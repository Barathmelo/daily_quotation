import SwiftUI

struct TabBarView: View {
    @Binding var currentView: AppView
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 128)
            .allowsHitTesting(false)
            
            // Tab bar
            HStack(spacing: 0) {
                tabButton(
                    view: .feed,
                    icon: "square.stack",
                    label: "Daily",
                    isSelected: currentView == .feed
                )
                
                tabButton(
                    view: .favorites,
                    icon: "heart",
                    label: "Saved",
                    isSelected: currentView == .favorites,
                    selectedColor: .red
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .background(
                Color(white: 0.1).opacity(0.6)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.white.opacity(0.1)),
                        alignment: .top
                    )
            )
        }
        .frame(height: 120)
    }
    
    private func tabButton(
        view: AppView,
        icon: String,
        label: String,
        isSelected: Bool,
        selectedColor: Color = .white
    ) -> some View {
        Button(action: {
            if currentView != view {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentView = view
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(isSelected ? selectedColor : Color(white: 0.5))
                    .symbolVariant(isSelected ? .fill : .none)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    )
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(isSelected ? selectedColor : Color(white: 0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


