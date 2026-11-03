import SwiftUI
import WidgetKit

// Weight widget (MyDayWeightWidget, systemSmall): latest weight, 30-day change,
// BMI, a 30-day sparkline and when it was logged. Renders the myday.weight
// envelope; see doc/en-us/features/home-screen-widgets.md.

// MARK: - Model

/// The myday.weight payload.
struct WeightModel: MyDayKindModel {
  static let kind = "myday.weight"
  let latestKg: Double?
  let latestAt: Date?
  let change30: Double?
  let bmi: Double?
  let points: [Double]
  /// Morning reminder `HH:mm`, or empty when reminders are off.
  let remindAt: String

  /// Purpose: Build the model from the envelope.
  /// Inputs: `env`.
  /// Returns: `WeightModel`.
  /// Side effects: None.
  /// Notes: The weight kind has no interactive actions.
  static func make(from env: MyDayEnvelope) -> WeightModel? {
    let latest = PayloadValue.object(env.payload["latest"])
    return WeightModel(
      latestKg: PayloadValue.number(latest?["kg"]),
      latestAt: PayloadValue.int64(latest?["at"]).map { LocalDay.date(ms: $0) },
      change30: PayloadValue.number(env.payload["change30"]),
      bmi: PayloadValue.number(env.payload["bmi"]),
      points: PayloadValue.numbers(env.payload["points"]),
      remindAt: PayloadValue.string(env.payload["remindAt"]))
  }

  /// Purpose: Return the next midnight and today's reminder time.
  /// Inputs: `now`.
  /// Returns: Dates.
  /// Side effects: None.
  /// Notes: The footer changes at both.
  func refreshDates(after now: Date) -> [Date] {
    var dates = [LocalDay.nextMidnight(after: now)]
    if let remind = LocalDay.time(remindAt, on: now), remind > now { dates.append(remind) }
    return dates
  }

  /// Purpose: Return the gallery sample.
  /// Inputs: None.
  /// Returns: A payload with a falling trend.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] {
    [
      "latest": ["kg": 62.4, "at": Date().timeIntervalSince1970 * 1000] as [String: Any],
      "change30": -1.2, "bmi": 21.6,
      "points": [63.6, 63.4, 63.2, 63.3, 62.9, 62.8, 62.4],
      "remindAt": "", "mask": false, "labels": [:] as [String: String],
    ]
  }
}

typealias WeightEntry = MyDayEntry<WeightModel>

// MARK: - Views

/// A line chart of the recent weights.
struct WeightSparkline: View {
  let points: [Double]

  /// Purpose: Draw the sparkline.
  /// Inputs: None.
  /// Returns: The chart view; empty with fewer than two points.
  /// Side effects: None.
  /// Notes: The vertical range is at least 0.1 kg so a flat line stays centered.
  var body: some View {
    GeometryReader { geo in
      Path { path in
        guard points.count > 1, let low = points.min(), let high = points.max() else { return }
        let span = max(high - low, 0.1)
        let base = high - low < 0.1 ? low - (0.1 - (high - low)) / 2 : low
        for (index, value) in points.enumerated() {
          let x = geo.size.width * CGFloat(index) / CGFloat(points.count - 1)
          let y = geo.size.height * (1 - CGFloat((value - base) / span))
          if index == 0 {
            path.move(to: CGPoint(x: x, y: y))
          } else {
            path.addLine(to: CGPoint(x: x, y: y))
          }
        }
      }
      .stroke(myDayBrand, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
      .accentable()
    }
  }
}

/// systemSmall: the weight card.
struct WeightSmallView: View {
  let entry: WeightEntry
  let model: WeightModel

  /// Purpose: Draw the card.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: The BMI line drops at large text sizes.
  var body: some View {
    let env = entry.env
    return VStack(alignment: .leading, spacing: 2) {
      MyDayHeader(symbol: "scalemass", title: env.label("title", "Weight"), env: env)
      Spacer(minLength: 2)
      if let kg = model.latestKg {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
          Text(env.masked(String(format: "%.1f", kg)))
            .font(.system(size: env.pt(30), weight: .bold, design: .rounded))
            .foregroundColor(myDayBrand).lineLimit(1).minimumScaleFactor(0.6).accentable()
          Text(env.label("unit", "kg")).font(.system(size: env.pt(12), weight: .semibold))
            .foregroundColor(.secondary)
        }
        .sensitiveValue(env.sensitive)
        changeLine.sensitiveValue(env.sensitive)
        if let bmi = model.bmi, env.textScale <= 1.2 {
          Text(verbatim: "\(env.label("bmi", "BMI")) \(env.masked(String(format: "%.1f", bmi)))")
            .font(.system(size: env.pt(11))).foregroundColor(.secondary).lineLimit(1)
            .sensitiveValue(env.sensitive)
        }
        if !env.mask && model.points.count > 1 {
          WeightSparkline(points: model.points).frame(height: 18).padding(.vertical, 2)
            .sensitiveValue(env.sensitive)
        }
        Spacer(minLength: 0)
        footer
      } else {
        Text(env.label("noData", "No records yet"))
          .font(.system(size: env.pt(13), weight: .semibold)).lineLimit(2)
        Spacer(minLength: 0)
      }
    }
  }

  /// Purpose: Draw the 30-day change line.
  /// Inputs: None.
  /// Returns: The line, green when the weight went down.
  /// Side effects: None.
  /// Notes: Nothing when there is no earlier record.
  @ViewBuilder private var changeLine: some View {
    if let change = model.change30 {
      HStack(spacing: 4) {
        Text(entry.env.label("change30", "30 days")).foregroundColor(.secondary)
        Text(entry.env.masked(signed(change)))
          .foregroundColor(!entry.env.mask && change < 0 ? .green : .secondary)
      }
      .font(.system(size: entry.env.pt(11), weight: .semibold)).lineLimit(1)
    }
  }

  /// Purpose: Draw when the latest record was logged, or "Not logged today".
  /// Inputs: None.
  /// Returns: The footer line.
  /// Side effects: None.
  /// Notes: "Not logged today" needs a reminder time that has passed.
  private var footer: some View {
    let footer = footerText()
    return Text(footer.text)
      .font(.system(size: entry.env.pt(10), weight: footer.warn ? .semibold : .regular))
      .foregroundColor(footer.warn ? .orange : .secondary).lineLimit(1)
  }

  /// Purpose: Compute the footer text.
  /// Inputs: None.
  /// Returns: The text and whether it is the orange reminder.
  /// Side effects: None.
  /// Notes: None.
  private func footerText() -> (text: String, warn: Bool) {
    let env = entry.env
    guard let at = model.latestAt else { return ("", false) }
    let days = LocalDay.days(from: at, to: entry.date)
    if days <= 0 { return (env.label("today", "Today {n}", n: LocalDay.hhmm(at)), false) }
    if let remind = LocalDay.time(model.remindAt, on: entry.date), entry.date >= remind {
      return (env.label("notLogged", "Not logged today"), true)
    }
    return (env.label("daysAgo", "{n} days ago", n: String(days)), false)
  }
}

/// Picks the Weight view, or the placeholder.
struct WeightEntryView: View {
  let entry: WeightEntry

  /// Purpose: Draw the widget.
  /// Inputs: None.
  /// Returns: The view with its background and tap URL.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    content.widgetBackground(MyDayBackground(), padded: true).widgetURL(myDayLink(WeightModel.kind))
  }

  /// Purpose: Draw the card or the placeholder.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var content: some View {
    if let model = entry.content {
      WeightSmallView(entry: entry, model: model)
    } else {
      MyDayPlaceholderView(symbol: "scalemass", message: placeholderMessage(entry.env.access))
    }
  }
}

/// The Weight widget.
struct MyDayWeightWidget: Widget {
  /// Widget kind; matches `iosKinds` in `HomeWidgetService`.
  let kind = "MyDayWeightWidget"

  /// Purpose: Configure the widget.
  /// Inputs: None.
  /// Returns: The widget configuration.
  /// Side effects: None.
  /// Notes: Home screen only: the kind is `sensitive` by default.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MyDayProvider<WeightModel>()) { entry in
      WeightEntryView(entry: entry)
    }
    .configurationDisplayName(galleryText("Weight", zhHans: "体重", zhHant: "體重", ja: "体重"))
    .description(
      galleryText(
        "Latest weight and the 30-day trend", zhHans: "最新体重与 30 天趋势", zhHant: "最新體重與 30 天趨勢",
        ja: "最新の体重と30日間の推移"))
    .supportedFamilies([.systemSmall])
  }
}
