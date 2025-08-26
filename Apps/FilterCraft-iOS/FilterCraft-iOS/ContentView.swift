import SwiftUI
import PhotosUI
import CoreImage
import FilterCraftCore

struct ContentView: View {
    @StateObject private var editSession = EditSession()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingExportSheet = false
    @State private var showingSessionStats = false
    @State private var exportedImageData: Data?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    imageDisplaySection
                    
                    if editSession.originalImage != nil {
                        filterSelectionSection
                        adjustmentControlsSection
                        processingStatusSection
                        actionButtonsSection
                    } else {
                        welcomeSection
                    }
                }
                .padding()
            }
            .navigationTitle("FilterCraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editSession.originalImage != nil {
                        Button("Stats") {
                            showingSessionStats = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { _ in
            Task {
                if let selectedPhoto = selectedPhoto {
                    await loadSelectedPhoto(selectedPhoto)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(editSession: editSession, exportedImageData: $exportedImageData)
        }
        .sheet(isPresented: $showingSessionStats) {
            SessionStatsSheet(editSession: editSession)
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.artframe")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Welcome to FilterCraft")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a photo to start editing with professional filters and adjustments")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                Label("Choose Photo", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
    }
    
    private var imageDisplaySection: some View {
        Group {
            if let previewImage = editSession.previewImage {
                AsyncImageView(ciImage: previewImage)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if editSession.hasEdits {
                            Button("Reset") {
                                Task {
                                    await editSession.resetToOriginal()
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                        }
                    }
            }
        }
    }
    
    private var filterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filters")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let appliedFilter = editSession.appliedFilter, appliedFilter.isEffective {
                    Text(appliedFilter.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases) { filterType in
                        FilterButton(
                            filterType: filterType,
                            isSelected: editSession.appliedFilter?.filterType == filterType,
                            isProcessing: editSession.processingState != .idle && editSession.processingState != .completed
                        ) {
                            editSession.applyFilter(filterType, intensity: filterType.defaultIntensity)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Filter intensity control
            if let appliedFilter = editSession.appliedFilter, appliedFilter.filterType != .none {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intensity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(appliedFilter.intensity * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { appliedFilter.intensity },
                            set: { editSession.updateFilterIntensity($0) }
                        ),
                        in: 0...1,
                        step: 0.1
                    )
                    .tint(.blue)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var adjustmentControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DisclosureGroup("Exposure") {
                VStack(spacing: 12) {
                    AdjustmentSlider(
                        type: .brightness,
                        value: Binding(
                            get: { editSession.adjustments.brightness },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.brightness = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                    
                    AdjustmentSlider(
                        type: .exposure,
                        value: Binding(
                            get: { editSession.adjustments.exposure },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.exposure = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                    
                    AdjustmentSlider(
                        type: .highlights,
                        value: Binding(
                            get: { editSession.adjustments.highlights },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.highlights = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                    
                    AdjustmentSlider(
                        type: .shadows,
                        value: Binding(
                            get: { editSession.adjustments.shadows },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.shadows = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                }
                .padding(.top, 12)
            }
            .font(.headline)
            
            DisclosureGroup("Color") {
                VStack(spacing: 12) {
                    AdjustmentSlider(
                        type: .saturation,
                        value: Binding(
                            get: { editSession.adjustments.saturation },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.saturation = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                    
                    AdjustmentSlider(
                        type: .warmth,
                        value: Binding(
                            get: { editSession.adjustments.warmth },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.warmth = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                    
                    AdjustmentSlider(
                        type: .tint,
                        value: Binding(
                            get: { editSession.adjustments.tint },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.tint = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                }
                .padding(.top, 12)
            }
            .font(.headline)
            
            DisclosureGroup("Light") {
                VStack(spacing: 12) {
                    AdjustmentSlider(
                        type: .contrast,
                        value: Binding(
                            get: { editSession.adjustments.contrast },
                            set: { newValue in
                                var adjustments = editSession.adjustments
                                adjustments.contrast = newValue
                                editSession.updateAdjustments(adjustments)
                            }
                        )
                    )
                }
                .padding(.top, 12)
            }
            .font(.headline)
        }
    }
    
    private var processingStatusSection: some View {
        Group {
            switch editSession.processingState {
            case .idle, .completed:
                EmptyView()
            case .processing(let progress, let operation):
                VStack(spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(operation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress)
                        .tint(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            case .failed(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            if editSession.hasEdits {
                Button("Reset All") {
                    Task {
                        await editSession.resetToOriginal()
                    }
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            Button("Export") {
                showingExportSheet = true
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(editSession.hasEdits ? Color.blue : Color.secondary)
            .clipShape(Capsule())
            .disabled(!editSession.hasEdits)
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let ciImage = CIImage(image: uiImage) else {
            return
        }
        
        await editSession.loadImage(ciImage)
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let filterType: FilterType
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: filterType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(filterType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(isSelected ? 0 : 0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1.0)
    }
}

struct AdjustmentSlider: View {
    let type: AdjustmentType
    @Binding var value: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: type.iconName)
                    .font(.caption)
                    .frame(width: 20)
                    .foregroundColor(.secondary)
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(type.minValue)...Double(type.maxValue),
                step: 0.1
            ) {
                Text(type.displayName)
            }
            .tint(.blue)
        }
    }
}

struct AsyncImageView: View {
    let ciImage: CIImage
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            convertCIImageToUIImage()
        }
        .onChange(of: ciImage) { _ in
            convertCIImageToUIImage()
        }
    }
    
    private func convertCIImageToUIImage() {
        Task {
            let context = CIContext(options: [.useSoftwareRenderer: false])
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let newUIImage = UIImage(cgImage: cgImage)
                await MainActor.run {
                    uiImage = newUIImage
                }
            }
        }
    }
}

struct ExportSheet: View {
    let editSession: EditSession
    @Binding var exportedImageData: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ImageExportFormat = .jpeg
    @State private var quality: Float = 0.9
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ImageExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedFormat != .png {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quality: \(Int(quality * 100))%")
                            .font(.headline)
                        
                        Slider(value: $quality, in: 0.1...1.0, step: 0.1)
                            .tint(.blue)
                    }
                }
                
                Button(action: exportImage) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isExporting ? "Exporting..." : "Export Image")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isExporting)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportImage() {
        isExporting = true
        Task {
            let data = await editSession.exportImage(format: selectedFormat, quality: quality)
            await MainActor.run {
                exportedImageData = data
                isExporting = false
                if data != nil {
                    dismiss()
                }
            }
        }
    }
}

struct SessionStatsSheet: View {
    let editSession: EditSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Duration")
                        .font(.headline)
                    Text(editSession.sessionStats.formattedSessionDuration)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Operations")
                        .font(.headline)
                    Text("\(editSession.sessionStats.operationCount) total operations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Edit History")
                        .font(.headline)
                    
                    List(editSession.editHistory.suffix(10)) { operation in
                        HStack {
                            Image(systemName: iconForOperationType(operation.type))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(operation.description)
                                    .font(.subheadline)
                                Text(operation.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Session Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForOperationType(_ type: EditOperationType) -> String {
        switch type {
        case .imageLoad: return "photo"
        case .filterApplication: return "camera.filters"
        case .adjustmentChange: return "slider.horizontal.3"
        case .reset: return "arrow.clockwise"
        }
    }
}

#Preview {
    ContentView()
}