import RevenueCatUI
import SwiftUI

/// Lightweight settings hub presented from the Favorites top-right gear.
///
/// Currently exposes:
/// - History Calendar (premium-gated — taps from non-premium users dismiss
///   the sheet and open the paywall instead)
/// - Manage Subscription (delegates to RC `CustomerCenterView`)
/// - App version
///
/// M3 will extend this with daily-reminder time picker and category
/// preferences. The shape (NavigationStack + List sections) is chosen so
/// new rows just slot in without restructuring.
struct SettingsSheet: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  /// Called when the user taps a premium-gated row while not subscribed.
  /// The parent (FavoritesListView) handles paywall presentation.
  var onRequirePaywall: () -> Void = {}

  @State private var showingCustomerCenter = false
  @State private var showingHistory = false

  private var appVersion: String {
    let dict = Bundle.main.infoDictionary
    let version = dict?["CFBundleShortVersionString"] as? String ?? "—"
    let build = dict?["CFBundleVersion"] as? String ?? "—"
    return "\(version) (\(build))"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            if subscriptionManager.isPremiumUser {
              showingHistory = true
            } else {
              dismiss()
              onRequirePaywall()
            }
          } label: {
            row(
              title: "History Calendar",
              subtitle: subscriptionManager.isPremiumUser
                ? "Browse past quotes by date"
                : "Premium — browse quotes from any day",
              systemImage: "calendar",
              showLock: !subscriptionManager.isPremiumUser
            )
          }
          .buttonStyle(.plain)
        }

        Section {
          Button {
            showingCustomerCenter = true
          } label: {
            row(
              title: "Manage Subscription",
              subtitle: subscriptionManager.isPremiumUser ? "Premium active" : "Not subscribed",
              systemImage: "person.crop.circle"
            )
          }
          .buttonStyle(.plain)
        }

        Section {
          HStack {
            Label("Version", systemImage: "info.circle")
            Spacer()
            Text(appVersion)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
      .sheet(isPresented: $showingCustomerCenter) {
        CustomerCenterView()
      }
      .sheet(isPresented: $showingHistory) {
        HistoryCalendarView()
          .environmentObject(subscriptionManager)
      }
    }
  }

  private func row(title: String, subtitle: String, systemImage: String, showLock: Bool = false) -> some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .frame(width: 24)
        .foregroundStyle(.primary)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(title)
            .foregroundStyle(.primary)
          if showLock {
            Image(systemName: "lock.fill")
              .font(.caption2)
              .foregroundStyle(.yellow)
          }
        }
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
  }
}
