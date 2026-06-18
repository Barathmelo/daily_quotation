import RevenueCat
import RevenueCatUI
import SwiftUI

/// Global settings hub presented from the Feed top-right gear.
///
/// Sections (top → bottom):
/// 1. Premium header card (CTA for free users, status for subscribers).
/// 2. Daily Reminder (toggle + time picker, local UNCalendarNotification).
/// 3. Subscription (Manage Subscription + Restore Purchases).
/// 4. Widget hint (collapsible step-by-step on adding the home-screen widget).
/// 5. About (version, Terms, Privacy).
///
/// Support section (Rate / Share App) is intentionally omitted pre-launch
/// — both flows need the numeric Apple ID, which only exists once the
/// listing is live. Add it back via `DailyQuoteConfig.appStoreURL`.
///
/// History Calendar lives in the Explore tab (single source of truth).
struct SettingsSheet: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @StateObject private var notificationManager = NotificationManager.shared
  @Environment(\.dismiss) private var dismiss

  @State private var showingCustomerCenter = false
  @State private var showingPaywall = false
  @State private var isRestoring = false
  @State private var restoreAlert: RestoreAlert?

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
        premiumHeaderSection

        reminderSection
        subscriptionSection
        widgetSection
        aboutSection
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
      .sheet(isPresented: $showingPaywall) {
        PaywallView()
          .environmentObject(subscriptionManager)
      }
      .alert(item: $restoreAlert) { alert in
        Alert(
          title: Text(alert.title),
          message: Text(alert.message),
          dismissButton: .default(Text("OK"))
        )
      }
      .task {
        await notificationManager.refreshStatus()
      }
    }
  }

  // MARK: - Premium header card

  /// Top-of-list card that adapts to subscription state:
  /// - Non-Premium → tappable CTA, opens `PaywallView`.
  /// - Premium → static status badge with no tap action and no chevron.
  ///   The "Manage Subscription" row below remains the single entry
  ///   point to RC's CustomerCenter, avoiding two controls that lead
  ///   to the same place.
  ///
  /// `listRowInsets(EdgeInsets())` is required: it removes the row's
  /// inner padding so the gradient card fully covers the `.insetGrouped`
  /// Section's default light-grey rounded container. Without it, the
  /// container peeks out around the card and reads as a stray "frame"
  /// floating behind the gradient.
  @ViewBuilder
  private var premiumHeaderSection: some View {
    Section {
      Group {
        if subscriptionManager.isPremiumUser {
          premiumHeaderCard
        } else {
          Button {
            HapticManager.medium()
            showingPaywall = true
          } label: {
            premiumHeaderCard
          }
          .buttonStyle(.plain)
        }
      }
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
    }
  }

  private var premiumHeaderCard: some View {
    let isPremium = subscriptionManager.isPremiumUser

    return HStack(alignment: .center, spacing: 14) {
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.18))
          .frame(width: 44, height: 44)
        Image(systemName: isPremium ? "checkmark.seal.fill" : "crown.fill")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(.white)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("Premium")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
        Text(
          isPremium
            ? "Premium active — thanks for supporting Quoteary."
            : "Unlimited refreshes, full quote library, and more."
        )
        .font(.system(size: 13))
        .foregroundStyle(.white.opacity(0.85))
        .lineLimit(2)
      }

      Spacer(minLength: 8)

      // Chevron only when the card is interactive (free users).
      if !isPremium {
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white.opacity(0.85))
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      LinearGradient(
        colors: [
          Color(red: 0.45, green: 0.30, blue: 0.85),
          Color(red: 0.85, green: 0.32, blue: 0.55),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

  // MARK: - Subscription

  /// Manage Subscription opens RC's CustomerCenter (cancel / change plan
  /// / billing history). Restore Purchases re-syncs entitlements with
  /// the App Store — required by App Store Review for any app that
  /// supports IAP, even when CustomerCenter is also reachable.
  @ViewBuilder
  private var subscriptionSection: some View {
    Section("Subscription") {
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

      Button {
        Task { await handleRestorePurchases() }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "arrow.clockwise.circle")
            .frame(width: 24)
            .foregroundStyle(.primary)
          Text("Restore Purchases")
            .foregroundStyle(.primary)
          Spacer()
          if isRestoring {
            ProgressView()
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(isRestoring)
    }
  }

  // MARK: - Widget

  /// Static how-to. iOS doesn't expose an API to deep-link into the
  /// widget gallery, so we settle for a 3-step explainer the user can
  /// expand on demand. Kept inside Settings (not a full sheet) because
  /// the instructions are short and rarely consulted.
  @ViewBuilder
  private var widgetSection: some View {
    Section("Widget") {
      DisclosureGroup {
        VStack(alignment: .leading, spacing: 8) {
          widgetStep(number: 1, text: "Long-press an empty area on your Home Screen until apps wiggle.")
          widgetStep(number: 2, text: "Tap the + button in the top-left, then search for \"Quoteary\".")
          widgetStep(number: 3, text: "Choose a size, add the widget, and tap Done.")
        }
        .padding(.vertical, 4)
      } label: {
        Label("Add Widget to Home Screen", systemImage: "rectangle.3.group")
      }
    }
  }

  private func widgetStep(number: Int, text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Text("\(number).")
        .font(.callout.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 18, alignment: .trailing)
      Text(text)
        .font(.callout)
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  // MARK: - About

  @ViewBuilder
  private var aboutSection: some View {
    Section("About") {
      HStack {
        Label("Version", systemImage: "info.circle")
        Spacer()
        Text(appVersion)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }

      Link(destination: DailyQuoteConfig.termsOfUseURL) {
        Label("Terms of Use", systemImage: "doc.text")
      }
      Link(destination: DailyQuoteConfig.privacyPolicyURL) {
        Label("Privacy Policy", systemImage: "hand.raised")
      }
    }
  }

  // MARK: - Reminder helpers

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

  // MARK: - Restore helpers

  /// Wraps `RevenueCatManager.restorePurchases` and surfaces the result
  /// as an alert. We always tell the user *something* — silent success
  /// looks like a broken button, especially for users who already had
  /// Premium and don't visually see anything change.
  private func handleRestorePurchases() async {
    isRestoring = true
    defer { isRestoring = false }
    do {
      _ = try await subscriptionManager.restorePurchases()
      restoreAlert = subscriptionManager.isPremiumUser
        ? RestoreAlert(
            title: "Purchases Restored",
            message: "Your Premium subscription is now active on this device."
          )
        : RestoreAlert(
            title: "No Purchases Found",
            message: "We couldn't find an active subscription tied to your Apple ID."
          )
    } catch {
      restoreAlert = RestoreAlert(
        title: "Restore Failed",
        message: (error as NSError).localizedDescription
      )
    }
  }

  // MARK: - Reusable row

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

/// Identifiable wrapper so `.alert(item:)` can drive a single alert
/// surface from multiple branches (success / no-op / failure).
private struct RestoreAlert: Identifiable {
  let id = UUID()
  let title: String
  let message: String
}
