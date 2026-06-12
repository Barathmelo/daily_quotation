import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for the Daily Reminder
/// feature. One repeating calendar trigger at a time, identified by a
/// constant string so re-scheduling cleanly replaces the previous slot.
///
/// `UNCalendarNotificationTrigger(repeats:true)` freezes the body text
/// at schedule time, so the body would otherwise become stale as days
/// roll over. App launch re-schedules from `DailyQuotationApp.task`
/// (see Step 3 of the M3 plan) to refresh the body to the latest
/// "today's quote".
@MainActor
final class NotificationManager: ObservableObject {
  static let shared = NotificationManager()

  private let center = UNUserNotificationCenter.current()
  private let identifier = "daily-quote-reminder"

  @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

  private init() {
    Task { await refreshStatus() }
  }

  func refreshStatus() async {
    let settings = await center.notificationSettings()
    authorizationStatus = settings.authorizationStatus
  }

  /// Ask for authorization if the system hasn't seen a decision yet.
  /// Returns `true` when the app has permission to schedule.
  @discardableResult
  func requestAuthorizationIfNeeded() async -> Bool {
    await refreshStatus()
    switch authorizationStatus {
    case .notDetermined:
      do {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        await refreshStatus()
        return granted
      } catch {
        return false
      }
    case .authorized, .provisional, .ephemeral:
      return true
    case .denied:
      return false
    @unknown default:
      return false
    }
  }

  /// Cancel any existing reminder and re-schedule using today's quote
  /// text (or a generic placeholder if the shared cache is empty).
  func scheduleDailyReminder(hour: Int, minute: Int) async {
    cancelDailyReminder()

    let content = UNMutableNotificationContent()
    content.title = "Quoteary"
    if let quote = DailyQuoteSync.loadTodayQuote() {
      // Trim to keep the lock-screen presentation readable.
      let trimmed = String(quote.text.prefix(120))
      content.body = "\u{201C}\(trimmed)\u{201D} — \(quote.author)"
    } else {
      content.body = "Your daily quote is ready."
    }
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    do {
      try await center.add(request)
    } catch {
      #if DEBUG
      print("⚠️ NotificationManager.scheduleDailyReminder failed: \(error)")
      #endif
    }
  }

  func cancelDailyReminder() {
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
  }
}
