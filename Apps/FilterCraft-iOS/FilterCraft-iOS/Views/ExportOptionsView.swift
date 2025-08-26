import SwiftUI
import FilterCraftCore

struct ExportOptionsView: View {
    @ObservedObject var editSession: EditSession
    @State private var showingExportSheet = false
    @State private var exportedImageData: Data?
    
    var body: some View {
        VStack(spacing: 16) {
            if editSession.originalImage != nil {
                HStack(spacing: 12) {
                    Button(action: { showingExportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(editSession.originalImage == nil)
                    
                    Button(action: { showingSessionStats() }) {
                        HStack {
                            Image(systemName: "chart.bar")
                            Text("Stats")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: 100)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(editSession: editSession, exportedImageData: $exportedImageData)
        }
    }
    
    private func showingSessionStats() {
        // TODO: Implement session statistics view
        print("Session stats: \(editSession.sessionStats.operationCount) operations")
    }
}

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
                            Slider(value: $quality, in: 0.1...1.0) {
                                Text("Quality")
                            }
                            
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
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
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
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
    
    private func saveToPhotos() {
        guard let uiImage = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        dismiss()
    }
}