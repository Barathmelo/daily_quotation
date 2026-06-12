//
//  DailyQuotationApp.swift
//  DailyQuotation
//
//  Created by Alex on 2025/12/6.
//

import RevenueCat
import SwiftUI

@main
struct DailyQuotationApp: App {
    @StateObject private var subscriptionManager = RevenueCatManager.shared

    init() {
        // RevenueCat must be configured exactly once, before any other
        // Purchases API is called. See DailyQuoteConfig.revenueCatAPIKey
        // for how to swap in your production key.
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif
        Purchases.configure(withAPIKey: DailyQuoteConfig.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
                .task {
                    // Start the customer-info listener and pre-load offerings
                    // once the SwiftUI environment is up.
                    subscriptionManager.start()

                    // Re-schedule the daily reminder so its body text reflects
                    // *today's* quote (UNCalendarNotificationTrigger freezes
                    // content at schedule time, so we re-arm on every launch).
                    if ReminderPreferences.isEnabled {
                        await NotificationManager.shared.scheduleDailyReminder(
                            hour: ReminderPreferences.hour,
                            minute: ReminderPreferences.minute
                        )
                    }
                }
        }
    }
}
