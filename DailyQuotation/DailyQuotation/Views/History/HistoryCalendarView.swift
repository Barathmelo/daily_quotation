import SwiftUI

/// Premium-only date picker that lets the user jump to any past day's
/// 20-quote feed. The date range is locked between the app's content
/// start date (2025-01-01, matching `FeedViewModel.todayOrder`) and
/// today, so the user can't accidentally request a future or pre-launch
/// day.
struct HistoryCalendarView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedDate: Date = Date()
  @State private var navigateToHistoryFeed: Bool = false

  private let startDate = Calendar.current.date(
    from: DateComponents(year: 2025, month: 1, day: 1)
  )!

  private var dateRange: ClosedRange<Date> {
    startDate ... Date()
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("Browse quotes from any day since January 2025.")
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
