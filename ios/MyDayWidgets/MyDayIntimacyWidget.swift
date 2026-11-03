import SwiftUI
import WidgetKit

// Private widget (MyDayIntimacyWidget, systemSmall): days since the last
// record, this month's count and average duration, and the predicted cycle.
// Titled with the neutral label "Private". Renders the myday.intimacy
// envelope; see doc/en-us/features/home-screen-widgets.md.

// MARK: - Model

/// The myday.intimacy payload.
struct IntimacyModel: MyDayKindModel {
  static let kind = "myday.intimacy"
  let lastAt: Date?
  /// `yyyy-MM` of `monthCount`.
  let month: String
  let monthCount: Int
  let avgMinutes: Int?
  /// Local `yyyy-MM-dd` of the next predicted period, or empty.
  let cycleNext: String

  /// Purpose: Build the model from the envelope.
  /// Inputs: `env`.
  /// Returns: `IntimacyModel`.
  /// Side effects: None.
  /// Notes: The kind has no interactive actions.
  static func make(from env: MyDayEnvelope) -> IntimacyModel? {
    let p = env.payload
    return IntimacyModel(
      lastAt: PayloadValue.int64(p["lastAt"]).map { LocalDay.date(ms: $0) },
      month: PayloadValue.string(p["month"]),
      monthCount: PayloadValue.int(p["monthCount"]) ?? 0,
      avgMinutes: PayloadValue.int(p["avgMinutes"]),
      cycleNext: PayloadValue.string(p["cycleNext"]))
  }

  /// Purpose: Return this month's count at an instant.
  /// Inputs: `date`.
  /// Returns: `monthCount`, or 0 once the month has changed.
  /// Side effects: None.
  /// Notes: None.
  func count(at date: Date) -> Int { month == LocalDay.monthKey(date) ? monthCount : 0 }

  /// Purpose: Return this month's average at an instant.
  /// Inputs: `date`.
  /// Returns: `avgMinutes`, or nil once the month has changed.
  /// Side effects: None.
  /// Notes: None.
  func average(at date: Date) -> Int? { month == LocalDay.monthKey(date) ? avgMinutes : nil }

  /// Purpose: Return the days until the predicted period.
  /// Inputs: `date`.
  /// Returns: Days (0 = today), or nil when none is predicted or it has passed.
  /// Side effects: None.
  /// Notes: None.
  func cycleDays(at date: Date) -> Int? {
    guard let next = LocalDay.parse(cycleNext) else { return nil }
    let days = LocalDay.days(from: date, to: next)
    return days >= 0 ? days : nil
  }

  /// Purpose: Return the day boundary.
  /// Inputs: `now`.
  /// Returns: The next midnight.
  /// Side effects: None.
  /// Notes: The day counts change at midnight.
  func refreshDates(after now: Date) -> [Date] { [LocalDay.nextMidnight(after: now)] }

  /// Purpose: Return the gallery sample.
  /// Inputs: None.
  /// Returns: A masked payload, matching the kind's default *Hide values*.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] {
    let now = Date()
    return [
      "lastAt": (now.timeIntervalSince1970 - 2 * 86400) * 1000, "month": LocalDay.monthKey(now),
      "monthCount": 6, "avgMinutes": 24, "cycleNext": "", "mask": true,
      "labels": [:] as [String: String],
    ]
  }
}

typealias IntimacyEntry = MyDayEntry<IntimacyModel>

// MARK: - Views

/// systemSmall: the Private card.
struct IntimacySmallView: View {
  let entry: IntimacyEntry
  let model: IntimacyModel

  /// Purpose: Draw the card.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: The average line drops at large text sizes.
  var body: some View {
    let env = entry.env
    return VStack(alignment: .leading, spacing: 2) {
      MyDayHeader(symbol: "lock.fill", title: env.label("title", "Private"), env: env)
      Spacer(minLength: 2)
      if let last = model.lastAt {
        sinceLine(days: max(0, LocalDay.days(from: last, to: entry.date)))
          .sensitiveValue(env.sensitive)
      } else {
        Text(env.label("noData", "No records yet"))
          .font(.system(size: env.pt(13), weight: .semibold)).lineLimit(2)
      }
      Spacer(minLength: 2)
      VStack(alignment: .leading, spacing: 2) {
        Text(env.label("month", "{n} this month", n: env.masked(String(model.count(at: entry.date)))))
        if let avg = model.average(at: entry.date), env.textScale <= 1.3 {
          Text(env.label("avg", "avg {n} min", n: env.masked(String(avg))))
        }
        if let days = model.cycleDays(at: entry.date) {
          Text(
            days == 0
              ? env.label("cycleToday", "Period expected today")
              : env.label("cycleIn", "Period in {n} days", n: env.masked(String(days))))
        }
      }
      .font(.system(size: env.pt(11))).foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.8)
      .sensitiveValue(env.sensitive)
    }
  }

  /// Purpose: Draw the big "days since" value.
  /// Inputs: `days` — local days since the last record.
  /// Returns: The number with "days ago", or "Today".
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private func sinceLine(days: Int) -> some View {
    if days == 0 && !entry.env.mask {
      Text(entry.env.label("today", "Today"))
        .font(.system(size: entry.env.pt(26), weight: .bold, design: .rounded))
        .foregroundColor(myDayBrand).lineLimit(1).minimumScaleFactor(0.6).accentable()
    } else {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(entry.env.masked(String(days)))
          .font(.system(size: entry.env.pt(32), weight: .bold, design: .rounded))
          .foregroundColor(myDayBrand).lineLimit(1).minimumScaleFactor(0.6).accentable()
        Text(entry.env.label("daysAgo", "days ago"))
          .font(.system(size: entry.env.pt(12), weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
      }
    }
  }
}

/// Picks the Private view, or the placeholder.
struct IntimacyEntryView: View {
  let entry: IntimacyEntry

  /// Purpose: Draw the widget.
  /// Inputs: None.
  /// Returns: The view with its background and tap URL.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    content.widgetBackground(MyDayBackground(), padded: true).widgetURL(myDayLink(IntimacyModel.kind))
  }

  /// Purpose: Draw the card or the placeholder.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var content: some View {
    if let model = entry.content {
      IntimacySmallView(entry: entry, model: model)
    } else {
      MyDayPlaceholderView(symbol: "lock.fill", message: placeholderMessage(entry.env.access))
    }
  }
}

/// The Private widget.
struct MyDayIntimacyWidget: Widget {
  /// Widget kind; matches `iosKinds` in `HomeWidgetService`.
  let kind = "MyDayIntimacyWidget"

  /// Purpose: Configure the widget.
  /// Inputs: None.
  /// Returns: The widget configuration.
  /// Side effects: None.
  /// Notes: Gallery text is deliberately neutral.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MyDayProvider<IntimacyModel>()) { entry in
      IntimacyEntryView(entry: entry)
    }
    .configurationDisplayName(galleryText("Private", zhHans: "私密", zhHant: "私密", ja: "プライベート"))
    .description(
      galleryText("Private statistics", zhHans: "私密统计", zhHant: "私密統計", ja: "プライベートな統計"))
    .supportedFamilies([.systemSmall])
  }
}
