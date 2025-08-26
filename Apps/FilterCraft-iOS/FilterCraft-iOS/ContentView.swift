import SwiftUI
import FilterCraftCore
import PhotosUI

// MARK: - Main ContentView with component architecture
struct ContentView: View {
    @StateObject private var editSession = EditSession()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ImageDisplayView(editSession: editSession)
                    PhotoPickerView(editSession: editSession)
                    
                    if editSession.originalImage != nil {
                        FilterSelectionView(editSession: editSession)
                        AdjustmentControlsView(editSession: editSession)
                        ExportOptionsView(editSession: editSession)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("FilterCraft")
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Image Display Component
struct ImageDisplayView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        Group {
            if editSession.previewImage != nil {
                AsyncImageView(editSession: editSession)
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
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(maxHeight: 400)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("Select a photo to begin editing")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
}

// MARK: - Photo Picker Component
struct PhotoPickerView: View {
    @ObservedObject var editSession: EditSession
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            if editSession.originalImage == nil {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Select Photo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image Loaded")
                            .font(.headline)
                        
                        if let extent = editSession.originalImage?.extent {
                            Text("\(Int(extent.width)) × \(Int(extent.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Change")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: selectedPhoto) { _ in
            Task {
                if let selectedPhoto = selectedPhoto {
                    await loadSelectedPhoto(selectedPhoto)
                }
            }
        }
    }
    
    private func loadSelectedPhoto(_ photo: PhotosPickerItem) async {
        do {
            guard let imageData = try await photo.loadTransferable(type: Data.self) else {
                print("Failed to load photo data")
                return
            }
            
            guard let uiImage = UIImage(data: imageData) else {
                print("Failed to create UIImage from data")
                return
            }
            
            guard let ciImage = CIImage(image: uiImage) else {
                print("Failed to create CIImage from UIImage")
                return
            }
            
            await MainActor.run {
                Task {
                    await editSession.loadImage(ciImage)
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
}

// MARK: - Filter Selection Component
struct FilterSelectionView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if editSession.appliedFilter != nil {
                    Text(editSession.appliedFilter?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases) { filterType in
                        FilterButton(
                            filterType: filterType,
                            isSelected: editSession.appliedFilter?.filterType == filterType || editSession.pendingFilter == filterType,
                            isProcessing: editSession.processingState != .idle && editSession.processingState != .completed
                        ) {
                            editSession.applyFilter(filterType, intensity: filterType.defaultIntensity)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .contentMargins(.horizontal, 16)
        }
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let filterType: FilterType
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? .blue : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    if isProcessing && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: filterType.iconName)
                            .font(.title2)
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Text(filterType.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}

// MARK: - Adjustment Controls Component
struct AdjustmentControlsView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adjustments")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if editSession.userAdjustments.hasAdjustments {
                    Button("Reset Manual") {
                        editSession.updateUserAdjustments(ImageAdjustments())
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            
            // Show filter base adjustments if any filter is applied
            if editSession.baseAdjustments.hasAdjustments {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("From Filter: \(editSession.appliedFilter?.filterType.displayName ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("(Base adjustments)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(AdjustmentType.allCases.filter { editSession.baseAdjustments.value(for: $0) != 0 }) { adjustmentType in
                            BaseAdjustmentRow(
                                adjustmentType: adjustmentType,
                                value: editSession.baseAdjustments.value(for: adjustmentType)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // User adjustments section
            VStack(alignment: .leading, spacing: 8) {
                if editSession.baseAdjustments.hasAdjustments {
                    HStack {
                        Text("Manual Adjustments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("(Added to filter)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                VStack(spacing: 12) {
                    ForEach(AdjustmentType.allCases) { adjustmentType in
                        AdjustmentSliderRow(
                            adjustmentType: adjustmentType,
                            value: Binding(
                                get: { editSession.userAdjustments.value(for: adjustmentType) },
                                set: { newValue in
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.setValue(newValue, for: adjustmentType)
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Base Adjustment Display
struct BaseAdjustmentRow: View {
    let adjustmentType: AdjustmentType
    let value: Float
    
    var body: some View {
        HStack {
            Image(systemName: adjustmentType.iconName)
                .font(.caption)
                .frame(width: 20)
                .foregroundColor(.blue)
            
            Text(adjustmentType.displayName)
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(String(format: "%.2f", value))
                .font(.caption)
                .foregroundColor(.blue)
                .monospacedDigit()
        }
    }
}

// MARK: - Adjustment Slider Row
struct AdjustmentSliderRow: View {
    let adjustmentType: AdjustmentType
    @Binding var value: Float
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: adjustmentType.iconName)
                    .font(.caption)
                    .frame(width: 20)
                
                Text(adjustmentType.displayName)
                    .font(.caption)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 40)
                
                if value != adjustmentType.defaultValue {
                    Button(action: { value = adjustmentType.defaultValue }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            
            Slider(
                value: $value,
                in: adjustmentType.minValue...adjustmentType.maxValue
            ) {
                Text(adjustmentType.displayName)
            }
            .tint(value != adjustmentType.defaultValue ? .blue : .gray)
        }
    }
}

// MARK: - Export Options Component
struct ExportOptionsView: View {
    @ObservedObject var editSession: EditSession
    @State private var showingExportSheet = false
    @State private var exportedImageData: Data?
    
    var body: some View {
        VStack(spacing: 16) {
            if editSession.originalImage != nil {
                Button(action: { showingExportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Image")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(editSession.originalImage == nil)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(editSession: editSession, exportedImageData: $exportedImageData)
        }
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    let editSession: EditSession
    @Binding var exportedImageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ImageExportFormat = .jpeg
    @State private var quality: Double = 0.9
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $selectedFormat) {
                        Text("JPEG").tag(ImageExportFormat.jpeg)
                        Text("PNG").tag(ImageExportFormat.png)
                        Text("HEIF").tag(ImageExportFormat.heif)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedFormat == .jpeg {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quality")
                            .font(.headline)
                        
                        VStack {
                            Slider(value: $quality, in: 0.1...1.0)
                            
                            HStack {
                                Text("Lower")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(quality * 100))%")
                                    .font(.caption)
                                    .monospacedDigit()
                                Spacer()
                                Text("Higher")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: exportImage) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(isExporting ? "Exporting..." : "Export Image")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isExporting ? .gray : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isExporting)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(item: Binding<ExportedImage?>(
            get: { exportedImageData.map { ExportedImage(data: $0) } },
            set: { _ in exportedImageData = nil }
        )) { exportedImage in
            ExportedImageView(imageData: exportedImage.data)
        }
    }
    
    private func exportImage() {
        Task {
            isExporting = true
            defer { isExporting = false }
            
            do {
                let imageData = await editSession.exportImage(format: selectedFormat, quality: Float(quality))
                await MainActor.run {
                    exportedImageData = imageData
                    dismiss()
                }
            }
        }
    }
}

struct ExportedImage: Identifiable {
    let id = UUID()
    let data: Data
}

struct ExportedImageView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("Error displaying exported image")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: saveToPhotos) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Save to Photos")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Exported Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func saveToPhotos() {
        guard let uiImage = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        dismiss()
    }
}

// MARK: - AsyncImageView (keeping existing implementation)
struct AsyncImageView: View {
    @ObservedObject var editSession: EditSession
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
            if let previewImage = editSession.previewImage {
                convertCIImageToUIImage(previewImage)
            }
        }
        .onReceive(editSession.$previewImage) { newPreviewImage in
            guard let ciImage = newPreviewImage else { 
                uiImage = nil
                return 
            }
            convertCIImageToUIImage(ciImage)
        }
    }
    
    private func convertCIImageToUIImage(_ ciImage: CIImage) {
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

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}