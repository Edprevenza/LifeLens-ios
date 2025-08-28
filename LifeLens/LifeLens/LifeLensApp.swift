// LifeLensApp.swift
// Main application entry point with production configuration

import SwiftUI
import CoreData

@main
struct LifeLensApp: App {
    // MARK: - Properties
    @StateObject private var appCoordinator = AppCoordinator.shared
    @StateObject private var authService = AuthenticationService.shared
    let persistenceController = PersistenceController.shared
    
    // MARK: - Initialization
    init() {
        // Early initialization tasks
        setupAppearance()
        
        // Initialize production configuration asynchronously
        Task {
            await AppCoordinator.shared.initializeProductionConfig()
        }
    }
    
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ModernHealthDashboard()
                .ignoresSafeArea()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appCoordinator)
                .environmentObject(authService)
                .task {
                    // Ensure initialization is complete
                    if !appCoordinator.isInitialized {
                        await appCoordinator.initializeProductionConfig()
                    }
                }
                .onAppear {
                    AppLogger.shared.log("LifeLens app launched", level: .info)
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
    
    // MARK: - Private Methods
    private func setupAppearance() {
        #if os(iOS)
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor.systemBlue
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor.systemBlue
        
        // Configure table view appearance
        UITableView.appearance().backgroundColor = UIColor.systemBackground
        UITableViewCell.appearance().backgroundColor = UIColor.secondarySystemBackground
        #endif
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        Group {
            if appCoordinator.isInitialized {
                if appCoordinator.hasSecurityViolation {
                    SecurityViolationView()
                } else {
                    AuthenticationContainerView()
                }
            } else {
                LoadingView()
            }
        }
        .animation(.easeInOut, value: appCoordinator.isInitialized)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                LifeLensLogo(size: .large, style: .withTitle)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Initializing...")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Security Violation View

struct SecurityViolationView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    
            .foregroundColor(.red)
                
                Text("Security Warning")
                    .font(.title)
                    .fontWeight(.bold)
                    
            .foregroundColor(.primary)
                
                Text("Your device configuration does not meet the security requirements for LifeLens. Please ensure your device is secure and try again.")
                    .font(.body)
                    
            .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: exitApp) {
                    Text("Exit")
                        .font(.headline)
                        
            .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(Color.red)
                        .cornerRadius(22)
                }
            }
        }
    }
    
    private func exitApp() {
        #if os(iOS)
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        #else
        NSApplication.shared.terminate(nil)
        #endif
    }
}