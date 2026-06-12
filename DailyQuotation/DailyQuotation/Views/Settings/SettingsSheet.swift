import RevenueCatUI
import SwiftUI

/// Lightweight settings hub presented from the Favorites top-right gear.
///
/// Currently exposes:
/// - Manage Subscription (delegates to RC `CustomerCenterView`)
/// - App version
///
/// History Calendar lives in the Explore tab (single source of truth).
/// M3 will append the Daily Reminder toggle + time picker here.
struct SettingsSheet: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  @State private var showingCustomerCenter = false

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
    }
  }

  private func row(title: String, subtitle: String, systemImage: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .frame(width: 24)
        .foregroundStyle(.primary)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .foregroundStyle(.primary)
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
