// LifeLensApp.swift
import SwiftUI
import CoreData

@main
struct LifeLensApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationContainerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authService)
                .onAppear {
                    setupApp()
                    // Configure for production
                    AppLifecycleManager.shared.configureForProduction()
                }
                #if os(macOS)
                .frame(minWidth: 1400, idealWidth: 1600, maxWidth: .infinity,
                       minHeight: 900, idealHeight: 1000, maxHeight: .infinity)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1600, height: 1000)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
        #endif
    }
    
    private func setupApp() {
        // Configure app appearance
        #if os(iOS)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        #endif
        
        // Initialize services
        AppLogger.shared.log("LifeLens app launched", level: .info)
    }
}