import SwiftUI

/// Premium-only date picker that lets the user jump to any past day's
/// 20-quote feed. The selectable range is `[firstLaunchDate ... today]`
/// so the user can't pick days before they started using the app.
struct HistoryCalendarView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedDate: Date = Date()
  @State private var navigateToHistoryFeed: Bool = false

  /// Lower bound = the day the user first opened the app. Stamped
  /// once by `FirstLaunchTracker` from `ContentView.init`.
  private let startDate = FirstLaunchTracker.firstLaunchDate

  private var dateRange: ClosedRange<Date> {
    startDate ... Date()
  }

  private var startDateLabel: String {
    startDate.formatted(date: .long, time: .omitted)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("Browse quotes from any day since \(startDateLabel).")
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.65))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
          .padding(.top, 20)

        DatePicker(
          "Select date",
          selection: $selectedDate,
          in: dateRange,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(.white)
        .colorScheme(.dark)
        .padding(.horizontal, 16)

        Spacer()

        Button {
          navigateToHistoryFeed = true
        } label: {
          Label("View this day", systemImage: "arrow.right.circle.fill")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
      }
      .readableWidth()
      .frame(maxHeight: .infinity)
      .background(Color.black.ignoresSafeArea())
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
            .foregroundStyle(.white)
        }
      }
      .navigationDestination(isPresented: $navigateToHistoryFeed) {
        HistoryFeedView(referenceDate: selectedDate)
          .environmentObject(subscriptionManager)
      }
    }
  }
}
