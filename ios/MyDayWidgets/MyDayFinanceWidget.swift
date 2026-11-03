import SwiftUI
import WidgetKit

// Finance widget (MyDayFinanceWidget): systemSmall and systemMedium. This
// month's expense, income and balance in the default currency, the top expense
// category (medium) and subscriptions billing within 7 days. Renders the
// myday.finance envelope; see doc/en-us/features/home-screen-widgets.md.

// MARK: - Model

/// One upcoming subscription bill.
struct FinanceBill {
  let name: String
  let emoji: String
  /// Local `yyyy-MM-dd` of the billing day.
  let day: String
  /// Localized short date.
  let date: String
  let amount: String

  /// Purpose: Decode a bill from the payload.
  /// Inputs: `json`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(json: [String: Any]) {
    name = PayloadValue.string(json["name"])
    emoji = PayloadValue.string(json["emoji"])
    day = PayloadValue.string(json["day"])
    date = PayloadValue.string(json["date"])
    amount = PayloadValue.string(json["amount"])
  }

  /// Purpose: Return the name with its emoji.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  var displayName: String { emoji.isEmpty ? name : "\(emoji) \(name)" }
}

/// The top expense category.
struct FinanceTop {
  let name: String
  let emoji: String
  let amount: String
  let share: Int
}

/// The myday.finance payload.
struct FinanceModel: MyDayKindModel {
  static let kind = "myday.finance"
  /// `yyyy-MM` of the totals.
  let month: String
  let monthLabel: String
  let expense: String
  let income: String
  let net: String
  let netNegative: Bool
  let top: FinanceTop?
  let bills: [FinanceBill]

  /// Purpose: Build the model from the envelope.
  /// Inputs: `env`.
  /// Returns: `FinanceModel`.
  /// Side effects: None.
  /// Notes: Amounts arrive formatted by the app.
  static func make(from env: MyDayEnvelope) -> FinanceModel? {
    let p = env.payload
    var top: FinanceTop?
    if let t = PayloadValue.object(p["top"]) {
      top = FinanceTop(
        name: PayloadValue.string(t["name"]), emoji: PayloadValue.string(t["emoji"]),
        amount: PayloadValue.string(t["amount"]), share: PayloadValue.int(t["share"]) ?? 0)
    }
    return FinanceModel(
      month: PayloadValue.string(p["month"]), monthLabel: PayloadValue.string(p["monthLabel"]),
      expense: PayloadValue.string(p["expense"]), income: PayloadValue.string(p["income"]),
      net: PayloadValue.string(p["net"]), netNegative: PayloadValue.bool(p["netNegative"]), top: top,
      bills: PayloadValue.objects(p["bills"]).map(FinanceBill.init(json:)))
  }

  /// Purpose: Return the bills still ahead at an instant.
  /// Inputs: `date`.
  /// Returns: Bills whose `day` is today or later.
  /// Side effects: None.
  /// Notes: Day keys compare in date order.
  func upcoming(at date: Date) -> [FinanceBill] {
    let today = LocalDay.key(date)
    return bills.filter { $0.day >= today }
  }

  /// Purpose: Return whether the totals belong to the current month.
  /// Inputs: `date`.
  /// Returns: `Bool`.
  /// Side effects: None.
  /// Notes: A snapshot from last month shows "Open MyDay to update".
  func isCurrent(at date: Date) -> Bool { month.isEmpty || month == LocalDay.monthKey(date) }

  /// Purpose: Return the bill day boundary.
  /// Inputs: `now`.
  /// Returns: The next midnight.
  /// Side effects: None.
  /// Notes: Bills drop and the month flips at midnight.
  func refreshDates(after now: Date) -> [Date] { [LocalDay.nextMidnight(after: now)] }

  /// Purpose: Return the gallery sample.
  /// Inputs: None.
  /// Returns: A payload with one bill.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] {
    let now = Date()
    return [
      "month": LocalDay.monthKey(now), "monthLabel": "", "expense": "¥3,284", "income": "¥12,000",
      "net": "¥8,716", "netNegative": false,
      "top": ["name": "Dining", "emoji": "🍜", "amount": "¥1,120", "share": 34] as [String: Any],
      "bills": [
        ["name": "Music", "emoji": "🎵", "day": LocalDay.key(now), "date": LocalDay.shortDate(now),
         "amount": "¥15"] as [String: Any]
      ],
      "mask": false, "labels": [:] as [String: String],
    ]
  }
}

typealias FinanceEntry = MyDayEntry<FinanceModel>

// MARK: - Views

/// One bill line: name, date and amount.
struct FinanceBillRow: View {
  let bill: FinanceBill
  let env: MyDayEnvelope

  /// Purpose: Draw the bill line.
  /// Inputs: None.
  /// Returns: The row view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    HStack(spacing: 4) {
      Text(bill.displayName).font(.system(size: env.pt(11), weight: .medium)).lineLimit(1)
      Spacer(minLength: 2)
      Text(bill.date).font(.system(size: env.pt(10))).foregroundColor(.secondary).lineLimit(1).fixedSize()
      Text(env.masked(bill.amount, long: true))
        .font(.system(size: env.pt(11), weight: .semibold, design: .rounded)).lineLimit(1).fixedSize()
        .sensitiveValue(env.sensitive)
    }
  }
}

/// Purpose: Return the header title shared by both families.
/// Inputs: `model`.
/// Returns: The localized month name, or `yyyy-MM` when absent.
/// Side effects: None.
/// Notes: None.
private func financeTitle(_ model: FinanceModel) -> String {
  model.monthLabel.isEmpty ? LocalDay.monthKey(Date()) : model.monthLabel
}

/// systemSmall: month, expense, income · net and the next bill.
struct FinanceSmallView: View {
  let entry: FinanceEntry
  let model: FinanceModel

  /// Purpose: Draw the small widget.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    let env = entry.env
    return VStack(alignment: .leading, spacing: 2) {
      MyDayHeader(symbol: "creditcard", title: financeTitle(model), env: env)
      Spacer(minLength: 2)
      if model.isCurrent(at: entry.date) {
        Text(env.label("expense", "Spent this month"))
          .font(.system(size: env.pt(10))).foregroundColor(.secondary).lineLimit(1)
        Text(env.masked(model.expense, long: true))
          .font(.system(size: env.pt(24), weight: .bold, design: .rounded)).foregroundColor(myDayBrand)
          .lineLimit(1).minimumScaleFactor(0.5).accentable()
          .sensitiveValue(env.sensitive)
        (Text(env.masked(model.income, long: true))
          + Text(" · ").foregroundColor(.secondary)
          + Text(env.masked(model.net, long: true))
          .foregroundColor(model.netNegative && !env.mask ? .red : .primary))
          .font(.system(size: env.pt(11), weight: .semibold, design: .rounded)).lineLimit(1)
          .minimumScaleFactor(0.7)
          .sensitiveValue(env.sensitive)
        Spacer(minLength: 2)
        if let bill = model.upcoming(at: entry.date).first {
          FinanceBillRow(bill: bill, env: env)
        } else {
          Text(env.label("noBills", "No bills this week"))
            .font(.system(size: env.pt(10))).foregroundColor(.secondary).lineLimit(1)
        }
      } else {
        Text(env.label("stale", "Open MyDay to update"))
          .font(.system(size: env.pt(13), weight: .semibold)).lineLimit(2)
        Spacer(minLength: 0)
      }
    }
  }
}

/// One labeled amount column of the medium layout.
struct FinanceColumn: View {
  let title: String
  let value: String
  let color: Color
  let env: MyDayEnvelope

  /// Purpose: Draw the column.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(title).font(.system(size: env.pt(10))).foregroundColor(.secondary).lineLimit(1)
      Text(env.masked(value, long: true))
        .font(.system(size: env.pt(17), weight: .bold, design: .rounded)).foregroundColor(color)
        .lineLimit(1).minimumScaleFactor(0.5)
        .sensitiveValue(env.sensitive)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// systemMedium: three columns, the top category and the bills.
struct FinanceMediumView: View {
  let entry: FinanceEntry
  let model: FinanceModel

  /// Purpose: Draw the medium widget.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: Bill rows drop at large text sizes.
  var body: some View {
    let env = entry.env
    let bills = model.upcoming(at: entry.date)
    return VStack(alignment: .leading, spacing: 5) {
      MyDayHeader(symbol: "creditcard", title: financeTitle(model), env: env) {
        AddLink(title: env.label("add", "Add"), url: myDayLink(FinanceModel.kind, [("do", "add")]), env: env)
      }
      if model.isCurrent(at: entry.date) {
        HStack(alignment: .top, spacing: 8) {
          FinanceColumn(title: env.label("expense", "Spent this month"), value: model.expense, color: myDayBrand, env: env)
          FinanceColumn(title: env.label("income", "Income"), value: model.income, color: .primary, env: env)
          FinanceColumn(
            title: env.label("net", "Balance"), value: model.net,
            color: model.netNegative && !env.mask ? .red : .primary, env: env)
        }
        if let top = model.top {
          HStack(spacing: 4) {
            Text(env.label("top", "Top spending")).foregroundColor(.secondary)
            Text(top.emoji.isEmpty ? top.name : "\(top.emoji) \(top.name)").lineLimit(1)
            Spacer(minLength: 2)
            Text(verbatim: "\(env.masked(top.amount, long: true)) · \(env.masked(String(top.share)))%")
              .foregroundColor(.secondary).fixedSize()
              .sensitiveValue(env.sensitive)
          }
          .font(.system(size: env.pt(11), weight: .medium)).lineLimit(1)
        }
        if bills.isEmpty {
          Text(env.label("noBills", "No bills this week"))
            .font(.system(size: env.pt(10))).foregroundColor(.secondary).lineLimit(1)
        } else {
          Text(env.label("billsSoon", "{n} billing soon", n: String(bills.count)))
            .font(.system(size: env.pt(10), weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
          ForEach(Array(bills.prefix(env.rows(2)).enumerated()), id: \.offset) { pair in
            FinanceBillRow(bill: pair.element, env: env)
          }
        }
      } else {
        Text(env.label("stale", "Open MyDay to update"))
          .font(.system(size: env.pt(13), weight: .semibold)).lineLimit(2)
      }
      Spacer(minLength: 0)
    }
  }
}

/// Picks the Finance view for the family, or the placeholder.
struct FinanceEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: FinanceEntry

  /// Purpose: Draw the widget.
  /// Inputs: None.
  /// Returns: The view with its background and tap URL.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    content.widgetBackground(MyDayBackground(), padded: true).widgetURL(myDayLink(FinanceModel.kind))
  }

  /// Purpose: Draw the family's layout or the placeholder.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var content: some View {
    if let model = entry.content {
      if family == .systemMedium {
        FinanceMediumView(entry: entry, model: model)
      } else {
        FinanceSmallView(entry: entry, model: model)
      }
    } else {
      MyDayPlaceholderView(symbol: "creditcard", message: placeholderMessage(entry.env.access))
    }
  }
}

/// The Finance widget.
struct MyDayFinanceWidget: Widget {
  /// Widget kind; matches `iosKinds` in `HomeWidgetService`.
  let kind = "MyDayFinanceWidget"

  /// Purpose: Configure the widget.
  /// Inputs: None.
  /// Returns: The widget configuration.
  /// Side effects: None.
  /// Notes: Home screen only: the kind is `sensitive` by default.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MyDayProvider<FinanceModel>()) { entry in
      FinanceEntryView(entry: entry)
    }
    .configurationDisplayName(galleryText("This month", zhHans: "本月收支", zhHant: "本月收支", ja: "今月の収支"))
    .description(
      galleryText(
        "Spending, income and upcoming bills", zhHans: "支出、收入与即将扣费", zhHant: "支出、收入與即將扣款",
        ja: "支出、収入、まもなくの請求"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
