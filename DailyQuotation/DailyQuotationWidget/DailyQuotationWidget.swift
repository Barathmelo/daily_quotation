//
//  DailyQuotationWidget.swift
//  DailyQuotationWidget
//
//  Created by Alex on 2025/12/7.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuoteEntry {
    QuoteEntry(date: .now, quote: .placeholder, appearance: .default)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> QuoteEntry
  {
    await loadEntry()
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    QuoteEntry
  > {
    let entry = await loadEntry()
    let nextUpdate =
      Calendar.current.nextDate(
        after: Date(),
        matching: DateComponents(hour: 0, minute: 5),
        matchingPolicy: .nextTime,
        direction: .forward
      ) ?? Date().addingTimeInterval(60 * 60 * 6)

    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }

  private func loadEntry() async -> QuoteEntry {
    let quote = WidgetQuoteRepository.quoteOfToday()
    let appearance = WidgetAppearanceStore.currentSettings()
    return QuoteEntry(date: .now, quote: quote, appearance: appearance)
  }
}

struct QuoteEntry: TimelineEntry {
  let date: Date
  let quote: Quote
  let appearance: AppearanceSettings
}

struct DailyQuotationWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    contentView
      .widgetURL(widgetURL)
      .containerBackground(for: .widget) {
        backgroundGradient
      }
  }

  private var widgetURL: URL? {
    URL(string: "dailyquotation://quote-of-today")
  }

  private var contentView: some View {
    ZStack(alignment: .topLeading) {
      backgroundGradient
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 12) {
       
          Spacer()
        Text("“\(entry.quote.text)”")
          .font(adjustedQuoteFont)
          .fontWeight(.medium)
          .foregroundStyle(.white)
          .lineLimit(maxQuoteLines)
          .minimumScaleFactor(0.6)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()

        metaText
          Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(paddingForFamily)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    // 进一步向外扩散背景，覆盖系统留白
    .padding(-24)
  }

  private var backgroundGradient: some View {
    LinearGradient(
      gradient: Gradient(colors: [
        Color(red: 0.16, green: 0.16, blue: 0.3),
        Color(red: 0.05, green: 0.05, blue: 0.1),
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .overlay(
      RadialGradient(
        gradient: Gradient(colors: [
          .white.opacity(0.18),
          .clear,
        ]),
        center: .topTrailing,
        startRadius: 10,
        endRadius: 240
      )
    )
  }

  private var maxQuoteLines: Int {
    switch family {
    case .systemSmall:
      return 4
    case .systemLarge, .systemExtraLarge:
      return 7
    default:
      return 5
    }
  }

  private var paddingForFamily: CGFloat {
    switch family {
    case .systemSmall:
      return 16
    case .systemMedium:
      return 22
    default:
      return 26
    }
  }

  private var adjustedQuoteFont: Font {
    let baseSize = entry.appearance.size.fontSize
    let lengthFactor = quoteScaleFactor(for: entry.quote.text.count)
    let familyFactor = familyFontFactor
    let size = baseSize * lengthFactor * familyFactor
    return .system(size: size, design: entry.appearance.font.fontDesign)
  }

  private var familyFontFactor: CGFloat {
    switch family {
    case .systemSmall:
      return 0.66
    case .systemMedium:
      return 0.84
    default:
      return 1.0
    }
  }

  private func quoteScaleFactor(for length: Int) -> CGFloat {
    switch length {
    case ..<50:
      return 0.90
    case 50..<120:
      return 0.75
    case 120..<160:
      return 0.62
    default:
      return 0.50
    }
  }

  @ViewBuilder
  private var metaText: some View {
    let author = entry.quote.author.uppercased()
    let category = entry.quote.category?.uppercased()
    let content = [author, category].compactMap { $0 }.joined(separator: " • ")

    Text(content)
      .font(.system(size: metaFontSize, weight: .semibold, design: .rounded))
      .foregroundStyle(.white.opacity(0.85))
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }

  private var metaFontSize: CGFloat {
    switch family {
    case .systemSmall:
      return 12
    case .systemMedium:
      return 12
    default:
      return 13
    }
  }
}

struct DailyQuotationWidget: Widget {
  let kind: String = "DailyQuotationWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: ConfigurationAppIntent.self,
      provider: Provider()
    ) { entry in
      DailyQuotationWidgetEntryView(entry: entry)
        .containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Quote of Today")
    .description("在主屏幕随时查看今日灵感。")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .systemLarge,
    ])
  }
}

#Preview(as: .systemSmall) {
  DailyQuotationWidget()
} timeline: {
  QuoteEntry(date: .now, quote: .placeholder, appearance: .default)
}
