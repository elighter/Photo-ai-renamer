import SwiftUI

@main
struct PhotoRenamerApp: App {
    @State private var showingPreferences = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
                .sheet(isPresented: $showingPreferences) {
                    PreferencesView()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            // Tercihler menüsü
            CommandGroup(replacing: .appInfo) {
                Button("Hakkında PhotoRenamer") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "PhotoRenamer",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Gemini AI ile fotoğraflarınızı akıllı bir şekilde yeniden adlandırın."
                            )
                        ]
                    )
                }
            }
            
            CommandGroup(after: .appSettings) {
                Button("Tercihler...") {
                    showingPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}