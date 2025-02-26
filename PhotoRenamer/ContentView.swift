import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = PhotoRenamerViewModel()
    @State private var isHovering = false
    @State private var showFileImporter = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.selectedImages.isEmpty {
                    uploadArea
                } else {
                    imagePreviewList
                }
            }
            .padding()
            .frame(minWidth: 250)
            
            if !viewModel.selectedImages.isEmpty {
                ImagePreviewView(viewModel: viewModel)
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 100))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                    Text("Fotoğraf seçin")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("PhotoRenamer")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !viewModel.selectedImages.isEmpty {
                    Button("Tümünü Yeniden Adlandır") {
                        viewModel.renameAllImages()
                    }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(viewModel.isProcessing)
                }
            }
        }
    }
    
    private var uploadArea: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [10]
                        )
                    )
                    .foregroundColor(isHovering ? .accentColor : .gray)
                    .frame(height: 200)
                    .onDrop(of: [UTType.image], isTargeted: $isHovering) { providers in
                        // Make NSItemProvider array Sendable with isolation
                        let itemProviders = providers.map { $0 }
                        
                        // Process each provider individually on MainActor
                        Task { @MainActor in
                            await viewModel.handleDrop(providers: itemProviders)
                        }
                        return true
                    }
                
                VStack(spacing: 15) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 40))
                    Text("Fotoğrafları buraya sürükleyip bırakın")
                        .font(.headline)
                    Button("veya Dosya Seçin") {
                        showFileImporter = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            Text("Fotoğraflarınız yerel olarak işlenir ve Gemini AI ile analiz edilir.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.image],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await viewModel.handleFileImport(result: result)
            }
        }
    }
    
    private var imagePreviewList: some View {
        List {
            Section(header: Text("Seçili Fotoğraflar")) {
                ForEach(viewModel.selectedImages) { image in
                    HStack {
                        if let nsImage = image.thumbnail {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(6)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .cornerRadius(6)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(image.originalName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let suggestedName = image.suggestedName {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text(suggestedName)
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            } else if image.isProcessing {
                                // ProgressView'u iyileştirilmiş bir frame içine aldım ve scale effect yerine
                                // doğrudan bir frame boyutu kullanıyorum
                                ProgressView()
                                    .frame(width: 16, height: 16)
                                    .padding(.vertical, 5)
                            }
                        }
                        
                        Spacer()
                        
                        if image.suggestedName != nil {
                            Button(action: {
                                viewModel.renameSingleImage(image)
                            }) {
                                Image(systemName: "checkmark.circle")
                            }
                            .buttonStyle(.borderless)
                            .disabled(image.isProcessing || image.isRenamed)
                        }
                        
                        Button(action: {
                            viewModel.removeImage(image)
                        }) {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Button("Daha fazla fotoğraf ekle") {
                    showFileImporter = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct ImagePreviewView: View {
    @ObservedObject var viewModel: PhotoRenamerViewModel
    
    var body: some View {
        if let selectedImage = viewModel.currentSelectedImage {
            VStack {
                if let nsImage = selectedImage.fullImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding()
                } else {
                    // ProgressView'u sabit boyuta sahip bir frame içine alıyorum
                    ProgressView()
                        .frame(width: 40, height: 40)
                        .padding()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Orijinal Dosya Adı:")
                            .bold()
                        Text(selectedImage.originalName)
                            .foregroundColor(.secondary)
                    }
                    
                    if let suggestedName = selectedImage.suggestedName {
                        HStack {
                            Text("Önerilen Dosya Adı:")
                                .bold()
                            Text(suggestedName)
                                .foregroundColor(.accentColor)
                        }
                        
                        if let description = selectedImage.aiDescription {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Analizi:")
                                    .bold()
                                Text(description)
                                    .font(.body)
                                    .padding(10)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            Button("Yeniden Adlandır") {
                                viewModel.renameSingleImage(selectedImage)
                            }
                            .keyboardShortcut(.return, modifiers: [.command])
                            .disabled(selectedImage.isProcessing || selectedImage.isRenamed)
                            
                            Button("Farklı Öneri Oluştur") {
                                Task {
                                    await viewModel.regenerateSuggestion(for: selectedImage)
                                }
                            }
                            .disabled(selectedImage.isProcessing)
                        }
                        .padding(.top, 5)
                    } else if selectedImage.isProcessing {
                        VStack(spacing: 10) {
                            // Burada da ProgressView'u düzenliyorum, scale effect kullanmak yerine
                            // sabit boyutlu bir frame içine alıyorum
                            HStack {
                                ProgressView()
                                    .frame(width: 16, height: 16)
                                Text("AI tarafından analiz ediliyor...")
                                    .padding(.leading, 4)
                            }
                            Text("Bu işlem birkaç saniye sürebilir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.05))
            }
        } else {
            Text("Bir fotoğraf seçin")
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}