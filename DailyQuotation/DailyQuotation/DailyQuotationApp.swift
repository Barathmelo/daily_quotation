//
//  DailyQuotationApp.swift
//  DailyQuotation
//
//  Created by Alex on 2025/12/6.
//

import SwiftUI

@main
struct DailyQuotationApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
        }
    }
}
