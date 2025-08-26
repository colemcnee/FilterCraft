import CoreImage
import Foundation
import Combine

/// Represents different types of edit operations for history tracking
public enum EditOperationType: String, CaseIterable {
    case adjustmentChange = "adjustment"
    case filterApplication = "filter"
    case reset = "reset"
    case imageLoad = "load"
    
    public var displayName: String {
        switch self {
        case .adjustmentChange: return "Adjustment"
        case .filterApplication: return "Filter"
        case .reset: return "Reset"
        case .imageLoad: return "Load Image"
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
    
    /// Current image adjustments
    @Published public var adjustments = ImageAdjustments() {
        didSet {
            if adjustments != oldValue {
                Task {
                    await updatePreview(reason: "Adjustments changed")
                    recordOperation(.adjustmentChange, description: "Updated image adjustments")
                }
            }
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
    
    /// Current preview image for display
    @Published public private(set) var previewImage: CIImage?
    
    /// Full resolution image for export
    @Published public private(set) var fullResolutionImage: CIImage?
    
    /// Original unedited image
    @Published public private(set) var originalImage: CIImage?
    
    /// History of edit operations
    @Published public private(set) var editHistory: [EditOperation] = []
    
    /// Session statistics
    @Published public private(set) var sessionStats = SessionStatistics()
    
    /// Whether any edits have been made
    public var hasEdits: Bool {
        adjustments.hasAdjustments || appliedFilter?.isEffective == true
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
    
    public init(imageProcessor: ImageProcessing = ImageProcessor()) {
        self.imageProcessor = imageProcessor
        self.sessionStats = SessionStatistics()
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
    
    /// Update adjustments with specific values
    public func updateAdjustments(_ newAdjustments: ImageAdjustments) {
        adjustments = newAdjustments
    }
    
    /// Apply a filter with specified intensity
    public func applyFilter(_ filterType: FilterType, intensity: Float = 1.0) {
        let newFilter = AppliedFilter(filterType: filterType, intensity: intensity)
        appliedFilter = newFilter
    }
    
    /// Update the intensity of the current filter
    public func updateFilterIntensity(_ intensity: Float) {
        guard let currentFilter = appliedFilter else { return }
        appliedFilter = currentFilter.withIntensity(intensity)
    }
    
    /// Reset all edits to original image
    public func resetToOriginal() async {
        processingState = .processing(progress: 0.3, operation: "Resetting edits")
        
        resetEditsInternal()
        await updatePreview(reason: "Reset to original")
        
        recordOperation(.reset, description: "Reset all edits")
        processingState = .completed
    }
    
    /// Generate final high-resolution image with all edits applied
    public func getFinalImage() async -> CIImage? {
        guard let originalImage = originalImage else { return nil }
        
        processingState = .processing(progress: 0.2, operation: "Processing final image")
        
        let finalImage = await imageProcessor.processImage(
            originalImage,
            adjustments: adjustments,
            filter: appliedFilter
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
    
    // MARK: - Private Methods
    
    private func resetEditsInternal() {
        adjustments = ImageAdjustments()
        appliedFilter = nil
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
            
            // Apply edits to preview
            let processedPreview = await imageProcessor.processImage(
                previewBase,
                adjustments: adjustments,
                filter: appliedFilter
            )
            
            if !Task.isCancelled {
                previewImage = processedPreview
                processingState = .completed
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
}

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