//
//  AppIntent.swift
//  DailyQuotationWidget
//
//  Created by Alex on 2025/12/7.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Quote of Today" }
  static var description: IntentDescription { "在主屏幕展示今日金句。" }
}
