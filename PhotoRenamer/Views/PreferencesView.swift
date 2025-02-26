import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccessAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Uygulama Tercihleri")
                .font(.title)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Gemini API Anahtarı")
                    .font(.headline)
                SecureField("API Anahtarını girin", text: $viewModel.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 400)
                
                Text("Bir Gemini API anahtarı edinmek için Google AI Studio'yu ziyaret edin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Link("API Anahtarı Oluştur", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                    .font(.caption)
                    .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            HStack {
                Spacer()
                
                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Kaydet") {
                    viewModel.saveSettings()
                    showingSuccessAlert = true
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500)
        .alert("Ayarlar Kaydedildi", isPresented: $showingSuccessAlert) {
            Button("Tamam") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("API anahtarınız güvenli bir şekilde kaydedildi.")
        }
        .onAppear {
            viewModel.loadSettings()
        }
    }
} 