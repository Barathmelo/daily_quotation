import SwiftUI

struct ContentView: View {
    @StateObject private var appearanceManager = AppearanceManager.shared
    @State private var view: AppView = .feed
    @State private var quotes: [Quote] = [Quote.initial]
    @State private var isLoading = false
    
    private var appearance: Binding<AppearanceSettings> {
        Binding(
            get: { appearanceManager.settings },
            set: { appearanceManager.updateSettings($0) }
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main content
            mainContent
            
            // Tab bar
            VStack {
                Spacer()
                TabBarView(currentView: $view)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            await loadQuotes(isRefresh: false)
        }
    }
    
    private var mainContent: some View {
        Group {
            if view == .feed {
                FeedView(
                    quotes: $quotes,
                    isLoading: $isLoading,
                    appearance: $appearance,
                    onRefresh: {
                        Task {
                            await loadQuotes(isRefresh: false)
                        }
                    }
                )
                .transition(.opacity)
            } else {
                FavoritesListView(appearance: $appearance)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: view)
    }
    
    private func loadQuotes(isRefresh: Bool) async {
        isLoading = true
        
        do {
            let newQuotes = try await GeminiService.shared.fetchQuotes(count: 10)
            
            await MainActor.run {
                if isRefresh {
                    quotes = newQuotes
                } else {
                    quotes.append(contentsOf: newQuotes)
                }
                isLoading = false
            }
        } catch {
            print("Error loading quotes: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

