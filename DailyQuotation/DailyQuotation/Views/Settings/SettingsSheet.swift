import RevenueCatUI
import SwiftUI

/// Lightweight settings hub presented from the Favorites top-right gear.
///
/// Currently exposes:
/// - Daily Reminder toggle + time picker (local UNCalendarNotification)
/// - Manage Subscription (delegates to RC `CustomerCenterView`)
/// - App version
///
/// History Calendar lives in the Explore tab (single source of truth).
struct SettingsSheet: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @StateObject private var notificationManager = NotificationManager.shared
  @Environment(\.dismiss) private var dismiss

  @State private var showingCustomerCenter = false
  @State private var reminderEnabled: Bool = ReminderPreferences.isEnabled
  @State private var reminderTime: Date = {
    Calendar.current.date(
      bySettingHour: ReminderPreferences.hour,
      minute: ReminderPreferences.minute,
      second: 0,
      of: Date()
    ) ?? Date()
  }()

  private var appVersion: String {
    let dict = Bundle.main.infoDictionary
    let version = dict?["CFBundleShortVersionString"] as? String ?? "—"
    let build = dict?["CFBundleVersion"] as? String ?? "—"
    return "\(version) (\(build))"
  }

  var body: some View {
    NavigationStack {
      List {
        reminderSection

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
      .task {
        await notificationManager.refreshStatus()
      }
    }
  }

  // MARK: - Daily Reminder section

  @ViewBuilder
  private var reminderSection: some View {
    Section {
      Toggle("Daily Reminder", isOn: $reminderEnabled)
        .onChange(of: reminderEnabled) { _, newValue in
          handleReminderToggle(newValue)
        }

      if reminderEnabled {
        DatePicker(
          "Time",
          selection: $reminderTime,
          displayedComponents: .hourAndMinute
        )
        .onChange(of: reminderTime) { _, newValue in
          let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
          ReminderPreferences.hour = comps.hour ?? 9
          ReminderPreferences.minute = comps.minute ?? 0
          Task { await reschedule() }
        }
      }

      if notificationManager.authorizationStatus == .denied && reminderEnabled {
        Text("Notifications are disabled in System Settings. Open Settings → Notifications → Quoteary to enable.")
          .font(.caption)
          .foregroundStyle(.orange)
      }
    } header: {
      Text("Daily Reminder")
    } footer: {
      Text("Receive one quote each day at the time you choose. Content refreshes when you open the app.")
    }
  }

  private func handleReminderToggle(_ newValue: Bool) {
    Task {
      if newValue {
        let granted = await notificationManager.requestAuthorizationIfNeeded()
        if granted {
          ReminderPreferences.isEnabled = true
          await reschedule()
        } else {
          reminderEnabled = false
          ReminderPreferences.isEnabled = false
        }
      } else {
        ReminderPreferences.isEnabled = false
        notificationManager.cancelDailyReminder()
      }
    }
  }

  private func reschedule() async {
    await notificationManager.scheduleDailyReminder(
      hour: ReminderPreferences.hour,
      minute: ReminderPreferences.minute
    )
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
