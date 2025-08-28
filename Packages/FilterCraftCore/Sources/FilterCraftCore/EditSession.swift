import Combine
import CoreImage
import Foundation

/// Represents different types of edit operations for history tracking
public enum EditOperationType: String, CaseIterable {
    case adjustmentChange = "adjustment"
    case filterApplication = "filter"
    case cropRotateChange = "cropRotate"
    case reset = "reset"
    case imageLoad = "load"
    
    public var displayName: String {
        switch self {
        case .adjustmentChange: return "Adjustment"
        case .filterApplication: return "Filter"
        case .cropRotateChange: return "Crop & Rotate"
        case .reset: return "Reset"
        case .imageLoad: return "Load Image"
        }
    }
    
    public var iconName: String {
        switch self {
        case .adjustmentChange: return "slider.horizontal.3"
        case .filterApplication: return "camera.filters"
        case .cropRotateChange: return "crop.rotate"
        case .reset: return "arrow.counterclockwise"
        case .imageLoad: return "photo"
        }
    }
}

/// Tracks individual edit operations
public struct EditOperation: Identifiable {
    public let id = UUID()
    public let type: EditOperationType
    public let timestamp: Date
    public let description: String
    
    public init(type: EditOperationType, description: String) {
        self.type = type
        self.timestamp = Date()
        self.description = description
    }
}

/// Processing state for UI feedback
public enum ProcessingState: Equatable {
    case idle
    case processing(progress: Float, operation: String)
    case completed
    case failed(Error)
    
    public static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.completed, .completed):
            return true
        case let (.processing(lhsProgress, lhsOp), .processing(rhsProgress, rhsOp)):
            return lhsProgress == rhsProgress && lhsOp == rhsOp
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Main editing session class for real-time photo editing
@MainActor
public class EditSession: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current state of image processing
    @Published public private(set) var processingState: ProcessingState = .idle
    
    /// Base adjustments applied by the current filter
    @Published public private(set) var baseAdjustments = ImageAdjustments()
    
    /// User-made manual adjustments (additive to base adjustments)
    @Published public var userAdjustments = ImageAdjustments() {
        didSet {
            if userAdjustments != oldValue {
                Task {
                    await updatePreview(reason: "User adjustments changed")
                    recordOperation(.adjustmentChange, description: "Updated manual adjustments")
                }
            }
        }
    }
    
    /// Temporary preview adjustments for real-time feedback during slider interaction
    @Published public private(set) var previewAdjustments = ImageAdjustments()
    
    /// Whether we're currently previewing adjustments (slider being dragged)
    @Published public private(set) var isPreviewingAdjustments = false
    
    /// Original user adjustments before preview started (for command creation)
    private var previewStartAdjustments = ImageAdjustments()
    
    /// Combined effective adjustments (base + user adjustments + preview if active)
    public var effectiveAdjustments: ImageAdjustments {
        if isPreviewingAdjustments {
            // When previewing, combine base adjustments with preview adjustments
            // (preview adjustments represent the user's temporary changes)
            return baseAdjustments.combined(with: previewAdjustments)
        } else {
            // Normal operation: combine base + user adjustments
            return baseAdjustments.combined(with: userAdjustments)
        }
    }
    
    /// Legacy property for backward compatibility - returns effective adjustments
    public var adjustments: ImageAdjustments {
        get { return effectiveAdjustments }
        set { 
            // When setting adjustments directly, treat them as user adjustments
            userAdjustments = newValue
        }
    }
    
    /// Currently applied filter
    @Published public var appliedFilter: AppliedFilter? {
        didSet {
            if appliedFilter != oldValue {
                Task {
                    await updatePreview(reason: "Filter changed")
                    recordOperation(.filterApplication, 
                                  description: appliedFilter?.description ?? "Removed filter")
                }
            }
        }
    }
    
    /// Filter currently being processed (for immediate UI feedback)
    @Published public private(set) var pendingFilter: FilterType?
    
    /// Current crop and rotate state
    @Published public private(set) var cropRotateState: CropRotateState = .identity {
        didSet {
            if cropRotateState != oldValue {
                Task {
                    await updatePreview(reason: "Crop/rotate state changed")
                    recordOperation(.cropRotateChange, description: cropRotateState.transformationDescription)
                }
            }
        }
    }
    
    /// Current preview image for display
    @Published public private(set) var previewImage: CIImage?
    
    /// Full resolution image for export
    @Published public private(set) var fullResolutionImage: CIImage?
    
    /// Original unedited image
    @Published public private(set) var originalImage: CIImage?
    
    /// History of edit operations (legacy - kept for compatibility)
    @Published public private(set) var editHistory: [EditOperation] = []
    
    /// New command-based history system for undo/redo
    @Published public private(set) var commandHistory = EditHistory()
    
    /// Whether command-based history is enabled (can be disabled for legacy compatibility)
    public let commandHistoryEnabled: Bool
    
    /// Session statistics
    @Published public private(set) var sessionStats = SessionStatistics()
    
    /// Whether any edits have been made
    public var hasEdits: Bool {
        baseAdjustments.hasAdjustments || 
        userAdjustments.hasAdjustments || 
        appliedFilter?.isEffective == true ||
        cropRotateState.hasTransformations
    }
    
    /// Current image extent for UI calculations
    public var imageExtent: CGRect {
        originalImage?.extent ?? .zero
    }
    
    // MARK: - Private Properties
    
    private let imageProcessor: ImageProcessing
    private let previewMaxDimension: CGFloat = 1024
    private var previewUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        imageProcessor: ImageProcessing = ImageProcessor(),
        enableCommandHistory: Bool = true
    ) {
        self.imageProcessor = imageProcessor
        self.sessionStats = SessionStatistics()
        self.commandHistoryEnabled = enableCommandHistory
        
        if enableCommandHistory {
            self.commandHistory = EditHistory()
        } else {
            self.commandHistory = EditHistory(maxHistorySize: 0, maxMemoryUsage: 0)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load a new image for editing
    public func loadImage(_ image: CIImage) async {
        processingState = .processing(progress: 0.1, operation: "Loading image")
        
        // Store original image
        originalImage = image
        fullResolutionImage = image
        
        // Generate initial preview
        processingState = .processing(progress: 0.5, operation: "Generating preview")
        previewImage = await imageProcessor.generatePreview(from: image, maxDimension: previewMaxDimension)
        
        // Reset adjustments and filters
        resetEditsInternal()
        
        // Record operation
        recordOperation(.imageLoad, description: "Loaded new image")
        
        processingState = .completed
        
        // Update session start time
        sessionStats = SessionStatistics()
    }
    
    /// Update adjustments with specific values (legacy method)
    public func updateAdjustments(_ newAdjustments: ImageAdjustments) {
        if commandHistoryEnabled {
            let command = AdjustmentCommand(
                previousUserAdjustments: userAdjustments,
                newUserAdjustments: newAdjustments
            )
            Task {
                await executeCommand(command)
            }
        } else {
            adjustments = newAdjustments
        }
    }
    
    /// Update user adjustments specifically (recommended method)
    public func updateUserAdjustments(_ newAdjustments: ImageAdjustments) {
        if commandHistoryEnabled {
            let command = AdjustmentCommand(
                previousUserAdjustments: userAdjustments,
                newUserAdjustments: newAdjustments
            )
            Task {
                await executeCommand(command)
            }
        } else {
            userAdjustments = newAdjustments
        }
    }
    
    /// Start previewing adjustments (called when user begins slider interaction)
    public func startPreviewingAdjustments() {
        guard !isPreviewingAdjustments else { return }
        
        previewStartAdjustments = userAdjustments
        previewAdjustments = userAdjustments  // Start with current user adjustments
        isPreviewingAdjustments = true
    }
    
    /// Update preview adjustments during slider interaction
    public func updatePreviewAdjustments(_ adjustments: ImageAdjustments) {
        guard isPreviewingAdjustments else { return }
        
        // Store the full adjustment values directly as they come from the sliders
        previewAdjustments = adjustments
        
        // Trigger preview update without creating commands
        Task {
            await updatePreview(reason: "Preview adjustments changed")
        }
    }
    
    /// End previewing and commit the final adjustments as a single command
    public func commitPreviewAdjustments() {
        guard isPreviewingAdjustments else { return }
        
        // The preview adjustments represent the final user adjustments
        let finalAdjustments = previewAdjustments
        isPreviewingAdjustments = false
        previewAdjustments = ImageAdjustments()
        
        // Create single command from start to final state
        updateUserAdjustments(finalAdjustments)
    }
    
    /// Cancel previewing and revert to original adjustments
    public func cancelPreviewAdjustments() {
        guard isPreviewingAdjustments else { return }
        
        isPreviewingAdjustments = false
        previewAdjustments = ImageAdjustments()
        
        // Trigger preview update to show original state
        Task {
            await updatePreview(reason: "Preview cancelled")
        }
    }
    
    /// Apply a filter with specified intensity
    public func applyFilter(_ filterType: FilterType, intensity: Float = 1.0) {
        // Set pending filter immediately for UI feedback
        pendingFilter = filterType
        
        let newFilter = AppliedFilter(filterType: filterType, intensity: intensity)
        
        if commandHistoryEnabled {
            let command: FilterCommand
            if let currentFilter = appliedFilter {
                command = FilterCommand(
                    changingFromFilter: currentFilter,
                    toFilter: newFilter,
                    previousBaseAdjustments: baseAdjustments
                )
            } else {
                command = FilterCommand(
                    applyingFilter: newFilter,
                    previousBaseAdjustments: baseAdjustments
                )
            }
            
            Task {
                await executeCommand(command)
            }
        } else {
            // Update base adjustments to reflect what the filter does
            baseAdjustments = filterType.getScaledAdjustments(intensity: intensity)
            appliedFilter = newFilter
        }
    }
    
    /// Update the intensity of the current filter
    public func updateFilterIntensity(_ intensity: Float) {
        guard let currentFilter = appliedFilter else { return }
        
        if commandHistoryEnabled {
            let command = FilterCommand(
                changingIntensityOf: currentFilter,
                from: currentFilter.intensity,
                to: intensity,
                previousBaseAdjustments: baseAdjustments
            )
            
            Task {
                await executeCommand(command)
            }
        } else {
            // Update base adjustments to reflect new intensity
            baseAdjustments = currentFilter.filterType.getScaledAdjustments(intensity: intensity)
            appliedFilter = currentFilter.withIntensity(intensity)
        }
    }
    
    /// Reset all edits to original image
    public func resetToOriginal() async {
        processingState = .processing(progress: 0.3, operation: "Resetting edits")
        
        if commandHistoryEnabled {
            let command = ResetCommand(completeResetFrom: self)
            await executeCommand(command)
        } else {
            resetEditsInternal()
            await updatePreview(reason: "Reset to original")
            recordOperation(.reset, description: "Reset all edits")
        }
        
        processingState = .completed
    }
    
    /// Generate final high-resolution image with all edits applied
    public func getFinalImage() async -> CIImage? {
        guard let originalImage = originalImage else { return nil }
        
        processingState = .processing(progress: 0.2, operation: "Processing final image")
        
        let finalImage = await imageProcessor.processImage(
            originalImage,
            adjustments: adjustments,
            filter: appliedFilter,
            cropRotate: cropRotateState.hasTransformations ? cropRotateState : nil
        )
        
        processingState = .processing(progress: 1.0, operation: "Final processing complete")
        processingState = .completed
        
        return finalImage
    }
    
    /// Export processed image in specified format
    public func exportImage(format: ImageExportFormat = .jpeg, quality: Float = 0.9) async -> Data? {
        processingState = .processing(progress: 0.1, operation: "Preparing export")
        
        guard let finalImage = await getFinalImage() else {
            processingState = .failed(ImageProcessingError.exportFailed)
            return nil
        }
        
        processingState = .processing(progress: 0.7, operation: "Rendering \(format.displayName)")
        
        let imageData = await imageProcessor.exportImage(finalImage, format: format, quality: quality)
        
        if imageData != nil {
            processingState = .completed
            sessionStats.incrementExportCount()
        } else {
            processingState = .failed(ImageProcessingError.exportFailed)
        }
        
        return imageData
    }
    
    /// Get processing progress for UI display
    public func getProcessingProgress() -> Float {
        switch processingState {
        case .processing(let progress, _):
            return progress
        case .completed:
            return 1.0
        default:
            return 0.0
        }
    }
    
    /// Get current processing operation description
    public func getCurrentOperation() -> String? {
        switch processingState {
        case .processing(_, let operation):
            return operation
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        default:
            return nil
        }
    }
    
    // MARK: - Command System Methods
    
    /// Execute a command and add it to history
    public func executeCommand(_ command: EditCommand) async {
        await command.execute(on: self)
        if commandHistoryEnabled {
            commandHistory.addCommand(command)
        }
    }
    
    /// Undo the last operation
    public func undo() async {
        guard commandHistoryEnabled else { return }
        await commandHistory.undo(on: self)
    }
    
    /// Redo the last undone operation
    public func redo() async {
        guard commandHistoryEnabled else { return }
        await commandHistory.redo(on: self)
    }
    
    /// Clear all command history
    public func clearCommandHistory() {
        guard commandHistoryEnabled else { return }
        commandHistory.clearHistory()
    }
    
    // MARK: - Internal Command System Methods
    // These methods are used by commands to directly modify state without triggering new commands
    
    internal func setUserAdjustmentsDirectly(_ adjustments: ImageAdjustments) async {
        // Temporarily disable the didSet observer by using the backing property
        let oldUserAdjustments = userAdjustments
        
        // Set the new value without triggering the didSet
        userAdjustments = adjustments
        
        // Manually trigger the preview update if the value actually changed
        if adjustments != oldUserAdjustments {
            await updatePreview(reason: "User adjustments changed via command")
            recordOperation(.adjustmentChange, description: "Updated manual adjustments")
        }
    }
    
    internal func setBaseAdjustmentsDirectly(_ adjustments: ImageAdjustments) async {
        let oldBaseAdjustments = baseAdjustments
        baseAdjustments = adjustments
        
        if adjustments != oldBaseAdjustments {
            await updatePreview(reason: "Base adjustments changed via command")
        }
    }
    
    internal func setAppliedFilterDirectly(_ filter: AppliedFilter?) async {
        let oldFilter = appliedFilter
        appliedFilter = filter
        
        if filter != oldFilter {
            await updatePreview(reason: "Filter changed via command")
            recordOperation(.filterApplication, 
                          description: filter?.description ?? "Removed filter")
        }
    }
    
    /// Reset adjustments of a specific type
    public func resetAdjustments() async {
        if commandHistoryEnabled {
            let command = ResetCommand(adjustmentResetFrom: self)
            await executeCommand(command)
        } else {
            userAdjustments = ImageAdjustments()
            baseAdjustments = ImageAdjustments()
            await updatePreview(reason: "Reset adjustments")
            recordOperation(.reset, description: "Reset adjustments")
        }
    }
    
    /// Reset only the current filter
    public func resetFilter() async {
        guard appliedFilter != nil else { return }
        
        if commandHistoryEnabled {
            let command = ResetCommand(filterResetFrom: self)
            await executeCommand(command)
        } else {
            appliedFilter = nil
            baseAdjustments = ImageAdjustments()
            await updatePreview(reason: "Reset filter")
            recordOperation(.reset, description: "Reset filter")
        }
    }
    
    /// Reset only user adjustments (keep base adjustments from filters)
    public func resetUserAdjustments() async {
        if commandHistoryEnabled {
            let command = ResetCommand(userAdjustmentResetFrom: self)
            await executeCommand(command)
        } else {
            userAdjustments = ImageAdjustments()
            await updatePreview(reason: "Reset user adjustments")
            recordOperation(.reset, description: "Reset manual adjustments")
        }
    }
    
    /// Smart reset that analyzes current state and resets intelligently
    public func smartReset() async {
        if commandHistoryEnabled {
            let command = SmartResetCommand(smartResetFrom: self)
            await executeCommand(command)
        } else {
            // Fallback to complete reset for legacy mode
            await resetToOriginal()
        }
    }
    
    // MARK: - Private Methods
    
    private func resetEditsInternal() {
        baseAdjustments = ImageAdjustments()
        userAdjustments = ImageAdjustments()
        appliedFilter = nil
        pendingFilter = nil
        fullResolutionImage = originalImage
    }
    
    private func updatePreview(reason: String) async {
        // Cancel previous update if still running
        previewUpdateTask?.cancel()
        
        previewUpdateTask = Task {
            guard let original = originalImage else { return }
            
            processingState = .processing(progress: 0.3, operation: "Updating preview")
            
            // Generate preview at lower resolution for performance
            let previewBase = await imageProcessor.generatePreview(from: original, maxDimension: previewMaxDimension) ?? original
            
            processingState = .processing(progress: 0.7, operation: "Applying effects")
            
            // Apply edits to preview (including crop/rotate)
            let effectiveState = effectiveCropRotateState
            let processedPreview = await imageProcessor.processImage(
                previewBase,
                adjustments: adjustments,
                filter: appliedFilter,
                cropRotate: effectiveState.hasTransformations ? effectiveState : nil
            )
            
            if !Task.isCancelled {
                previewImage = processedPreview
                processingState = .completed
                // Clear pending filter when processing is complete
                pendingFilter = nil
                sessionStats.incrementOperationCount()
            }
        }
        
        await previewUpdateTask?.value
    }
    
    private func recordOperation(_ type: EditOperationType, description: String) {
        let operation = EditOperation(type: type, description: description)
        editHistory.append(operation)
        
        // Keep history manageable (last 50 operations)
        if editHistory.count > 50 {
            editHistory.removeFirst()
        }
        
        sessionStats.recordOperation(type)
    }
    
    // MARK: - Crop & Rotate Methods
    
    @Published private var temporaryCropRotateState: CropRotateState?
    
    /// Update crop and rotate state with command pattern
    public func updateCropRotateState(_ newState: CropRotateState) {
        guard newState != cropRotateState else { return }
        
        if commandHistoryEnabled {
            let command = CropRotateCommand(
                previousState: cropRotateState,
                newState: newState
            )
            Task {
                await executeCommand(command)
            }
        } else {
            cropRotateState = newState
        }
    }
    
    /// Update crop/rotate state temporarily during gestures (no command creation)
    public func updateCropRotateStateTemporary(_ newState: CropRotateState) {
        temporaryCropRotateState = newState
        Task {
            await updatePreview(reason: "Temporary crop/rotate state changed")
        }
    }
    
    /// Commit the temporary crop/rotate state as the actual state
    public func commitTemporaryCropRotateState() {
        guard let tempState = temporaryCropRotateState else { return }
        temporaryCropRotateState = nil
        updateCropRotateState(tempState)
    }
    
    /// Cancel temporary crop/rotate changes
    public func cancelTemporaryCropRotateState() {
        guard temporaryCropRotateState != nil else { return }
        temporaryCropRotateState = nil
        Task {
            await updatePreview(reason: "Cancelled temporary crop/rotate state")
        }
    }
    
    /// Get the effective crop/rotate state (temporary if available, otherwise actual)
    public var effectiveCropRotateState: CropRotateState {
        return temporaryCropRotateState ?? cropRotateState
    }
    
    /// Apply crop and rotate state directly (used by commands)
    internal func applyCropRotateStateDirectly(_ state: CropRotateState) async {
        await MainActor.run {
            cropRotateState = state
        }
        
        // Trigger image reprocessing with new crop/rotate
        await updatePreview(reason: "Crop/rotate applied")
    }
    
    /// Reset crop and rotate to identity
    public func resetCropRotate() {
        updateCropRotateState(.identity)
    }
    
    /// Apply only crop (keeping current rotation and flips)
    public func updateCropRect(_ newRect: CGRect) {
        let newState = cropRotateState.withCropRect(newRect)
        updateCropRotateState(newState)
    }
    
    /// Apply rotation change (keeping current crop and flips)
    public func updateRotation(_ newAngle: Float) {
        let newState = cropRotateState.withRotation(newAngle)
        updateCropRotateState(newState)
    }
    
    /// Rotate by a delta amount
    public func rotateByDelta(_ deltaAngle: Float) {
        let newState = cropRotateState.withRotationDelta(deltaAngle)
        updateCropRotateState(newState)
    }
    
    /// Rotate by 90 degrees clockwise
    public func rotate90Clockwise() {
        rotateByDelta(.pi / 2)
    }
    
    /// Rotate by 90 degrees counter-clockwise
    public func rotate90CounterClockwise() {
        rotateByDelta(-.pi / 2)
    }
    
    /// Toggle horizontal flip
    public func toggleHorizontalFlip() {
        let newState = cropRotateState.withToggledHorizontalFlip()
        updateCropRotateState(newState)
    }
    
    /// Toggle vertical flip
    public func toggleVerticalFlip() {
        let newState = cropRotateState.withToggledVerticalFlip()
        updateCropRotateState(newState)
    }
    
    /// Update aspect ratio constraint
    public func updateAspectRatio(_ aspectRatio: AspectRatio?) {
        let newState = cropRotateState.withAspectRatio(aspectRatio)
        updateCropRotateState(newState)
    }
    
    /// Get the current crop rectangle in pixel coordinates
    public func pixelCropRect() -> CGRect? {
        guard let originalImage = originalImage else { return nil }
        return cropRotateState.pixelCropRect(for: originalImage.extent.size)
    }
}

#if DEBUG
extension EditSession {
    static public var preview: EditSession {
        let session = EditSession()
        
        // Add fake data for previews
        session.userAdjustments = ImageAdjustments(
            brightness: 0.1,
            contrast: 1.1,
            saturation: 1.2
        )

        session.cropRotateState = CropRotateState()
        
        session.originalImage = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 512, height: 512))
        session.previewImage = session.originalImage
        
        return session
    }
}
#endif

// MARK: - Session Statistics

/// Tracks statistics for the current editing session
public struct SessionStatistics {
    public let sessionStartTime: Date
    public private(set) var operationCount: Int = 0
    public private(set) var exportCount: Int = 0
    public private(set) var operationsByType: [EditOperationType: Int] = [:]
    
    public init() {
        self.sessionStartTime = Date()
    }
    
    public var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    public var formattedSessionDuration: String {
        let duration = sessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    mutating func incrementOperationCount() {
        operationCount += 1
    }
    
    mutating func incrementExportCount() {
        exportCount += 1
    }
    
    mutating func recordOperation(_ type: EditOperationType) {
        operationsByType[type, default: 0] += 1
        incrementOperationCount()
    }
}
