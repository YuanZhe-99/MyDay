import SwiftUI
import WidgetKit

// Todo widget (MyDayTodoWidget): systemSmall, systemMedium, systemLarge and,
// on iOS 16+, the lock-screen accessoryRectangular. Renders the myday.todo
// envelope; checkboxes queue `setDone` actions on iOS 17+ and open the app
// before. See doc/en-us/features/home-screen-widgets.md.

// MARK: - Model

/// One Todo row of a day.
struct TodoItem {
  let id: String
  let title: String
  let emoji: String
  let kind: String
  var done: Bool
  /// Reminder time `HH:mm`, or empty.
  let time: String
  let late: Bool
  /// A one-time task with a recurrence: its checkbox opens the app instead.
  let rec: Bool
  /// Scheduled exactly on that day.
  let sched: Bool

  /// Purpose: Decode an item from the payload.
  /// Inputs: `json`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: Missing fields read as empty or false.
  init(json: [String: Any]) {
    id = PayloadValue.string(json["id"])
    title = PayloadValue.string(json["t"])
    emoji = PayloadValue.string(json["e"])
    kind = PayloadValue.string(json["k"])
    done = PayloadValue.bool(json["done"])
    time = PayloadValue.string(json["time"])
    late = PayloadValue.bool(json["late"])
    rec = PayloadValue.bool(json["rec"])
    sched = PayloadValue.bool(json["sched"])
  }

  /// Purpose: Return the title with its emoji.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  var displayTitle: String { emoji.isEmpty ? title : "\(emoji) \(title)" }

  /// Purpose: Return whether the row is drawn as overdue.
  /// Inputs: None.
  /// Returns: `Bool`.
  /// Side effects: None.
  /// Notes: Only open rows are overdue.
  var isOverdue: Bool { late && !done }
}

/// One day of the snapshot.
struct TodoDay {
  let date: String
  let label: String
  let score: Int?
  var items: [TodoItem]

  /// Purpose: Decode a day from the payload.
  /// Inputs: `json`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(json: [String: Any]) {
    date = PayloadValue.string(json["date"])
    label = PayloadValue.string(json["label"])
    score = PayloadValue.int(json["score"])
    items = PayloadValue.objects(json["items"]).map(TodoItem.init(json:))
  }

  /// Purpose: Return the rows in display order.
  /// Inputs: None.
  /// Returns: Open rows in payload order, then done rows.
  /// Side effects: None.
  /// Notes: Keeps a row toggled by a pending action in its new group.
  var ordered: [TodoItem] { items.filter { !$0.done } + items.filter { $0.done } }

  /// Purpose: Count open rows.
  /// Inputs: None.
  /// Returns: `Int`.
  /// Side effects: None.
  /// Notes: None.
  var openCount: Int { items.filter { !$0.done }.count }

  /// Purpose: Count done rows.
  /// Inputs: None.
  /// Returns: `Int`.
  /// Side effects: None.
  /// Notes: None.
  var doneCount: Int { items.count - openCount }

  /// Purpose: Return the completed fraction.
  /// Inputs: None.
  /// Returns: 0...1; 0 without rows.
  /// Side effects: None.
  /// Notes: None.
  var fraction: Double { items.isEmpty ? 0 : Double(doneCount) / Double(items.count) }

  /// Purpose: Return the header date text.
  /// Inputs: None.
  /// Returns: The payload's localized label, or a short local date.
  /// Side effects: None.
  /// Notes: None.
  var title: String {
    if !label.isEmpty { return label }
    return LocalDay.parse(date).map(LocalDay.shortDate) ?? date
  }
}

/// The myday.todo payload with pending `setDone` taps replayed.
struct TodoModel: MyDayKindModel {
  static let kind = "myday.todo"
  var days: [TodoDay]

  /// Purpose: Build the model and replay pending taps.
  /// Inputs: `env`.
  /// Returns: `TodoModel`.
  /// Side effects: None.
  /// Notes: `setDone` sets the matching item's state on the matching day, in queue order.
  static func make(from env: MyDayEnvelope) -> TodoModel? {
    var days = PayloadValue.objects(env.payload["days"]).map(TodoDay.init(json:))
    for action in env.pending where action.action == "setDone" {
      let id = PayloadValue.string(action.args["id"])
      let date = PayloadValue.string(action.args["date"])
      guard !id.isEmpty, !date.isEmpty else { continue }
      let done = PayloadValue.bool(action.args["done"])
      for d in days.indices where days[d].date == date {
        for i in days[d].items.indices where days[d].items[i].id == id {
          days[d].items[i].done = done
        }
      }
    }
    return TodoModel(days: days)
  }

  /// Purpose: Return the day shown at an instant.
  /// Inputs: `date`.
  /// Returns: The day whose key is `date`'s local day, or nil (stale snapshot).
  /// Side effects: None.
  /// Notes: None.
  func today(at date: Date) -> TodoDay? {
    let key = LocalDay.key(date)
    return days.first { $0.date == key }
  }

  /// Purpose: Return the day after the shown one.
  /// Inputs: `date`.
  /// Returns: Tomorrow's day, or nil.
  /// Side effects: None.
  /// Notes: None.
  func tomorrow(at date: Date) -> TodoDay? {
    let key = LocalDay.key(LocalDay.nextMidnight(after: date))
    return days.first { $0.date == key }
  }

  /// Purpose: Return the next midnight and every reminder time ahead.
  /// Inputs: `now`.
  /// Returns: Dates.
  /// Side effects: None.
  /// Notes: None.
  func refreshDates(after now: Date) -> [Date] {
    var dates = [LocalDay.nextMidnight(after: now)]
    for day in days {
      guard let start = LocalDay.parse(day.date) else { continue }
      for item in day.items {
        if let at = LocalDay.time(item.time, on: start), at > now { dates.append(at) }
      }
    }
    return dates
  }

  /// Purpose: Return the gallery sample.
  /// Inputs: None.
  /// Returns: A payload with three tasks today.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] {
    let now = Date()
    func item(_ id: String, _ t: String, _ e: String, _ done: Bool, _ time: String) -> [String: Any] {
      ["id": id, "t": t, "e": e, "k": "daily", "done": done, "time": time, "late": false, "rec": false,
       "sched": false]
    }
    return [
      "days": [
        [
          "date": LocalDay.key(now), "label": "", "score": 2,
          "items": [
            item("a", "Morning run", "🏃", false, "07:30"),
            item("b", "Pay the bills", "🧾", false, "18:00"),
            item("c", "Read 20 pages", "📖", true, ""),
          ],
        ] as [String: Any],
        ["date": LocalDay.key(LocalDay.nextMidnight(after: now)), "label": "", "items": []] as [String: Any],
      ],
      "mask": false,
      "labels": [:] as [String: String],
    ]
  }
}

typealias TodoEntry = MyDayEntry<TodoModel>

// MARK: - Views

/// Shared wording and links for the Todo views.
private struct TodoText {
  let env: MyDayEnvelope

  /// Purpose: Format the open count.
  /// Inputs: `n`.
  /// Returns: For example "3 left".
  /// Side effects: None.
  /// Notes: Masked under *Hide values*.
  func left(_ n: Int) -> String { env.label("left", "{n} left", n: env.masked(String(n))) }

  /// Purpose: Format the progress.
  /// Inputs: `day`.
  /// Returns: For example "2/5 done".
  /// Side effects: None.
  /// Notes: Masked under *Hide values*.
  func progress(_ day: TodoDay) -> String {
    env.label(
      "progress", "{n}/{m} done", n: env.masked(String(day.doneCount)), m: env.masked(String(day.items.count)))
  }

  /// Purpose: Format the day score.
  /// Inputs: `score`.
  /// Returns: For example "Day score +2".
  /// Side effects: None.
  /// Notes: None.
  func score(_ score: Int) -> String {
    "\(env.label("score", "Day score")) \(env.masked(signed(Double(score), digits: 0)))"
  }

  /// Purpose: Return the summary line when no row is open.
  /// Inputs: `day`.
  /// Returns: "All done" or "Nothing planned".
  /// Side effects: None.
  /// Notes: None.
  func empty(_ day: TodoDay) -> String {
    day.items.isEmpty ? env.label("nothing", "Nothing planned") : env.label("allDone", "All done")
  }
}

/// Purpose: Return the deep link that toggles a task in the app.
/// Inputs: `id`.
/// Returns: `myday://widget/myday.todo?do=toggle&id=<id>`.
/// Side effects: None.
/// Notes: None.
private func todoToggleLink(_ id: String) -> URL {
  myDayLink(TodoModel.kind, [("do", "toggle"), ("id", id)])
}

/// One row: checkbox, title, and reminder time or "Overdue".
struct TodoRow: View {
  let item: TodoItem
  let day: String
  let env: MyDayEnvelope
  let allowLinks: Bool

  /// Purpose: Draw the row.
  /// Inputs: None.
  /// Returns: The row view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    HStack(spacing: 5) {
      checkbox
      Text(item.displayTitle)
        .font(.system(size: env.pt(12), weight: .medium))
        .foregroundColor(item.done ? .secondary : .primary)
        .strikethrough(item.done)
        .lineLimit(1)
      Spacer(minLength: 2)
      trailing
    }
  }

  /// Purpose: Draw the checkbox symbol.
  /// Inputs: None.
  /// Returns: The symbol view.
  /// Side effects: None.
  /// Notes: None.
  private var checkIcon: some View {
    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
      .font(.system(size: env.pt(14), weight: .semibold))
      .foregroundColor(item.done ? .secondary : myDayBrand)
      .accentable()
  }

  /// Purpose: Draw the interactive checkbox.
  /// Inputs: None.
  /// Returns: An intent button, or a deep link for recurring tasks and iOS 14–16.
  /// Side effects: A tap queues `setDone` or opens the app.
  /// Notes: Recurring one-time tasks always open the app so its "next occurrence" prompt appears.
  @ViewBuilder private var checkbox: some View {
    if item.rec {
      if allowLinks {
        Link(destination: todoToggleLink(item.id)) { checkIcon }
      } else {
        checkIcon
      }
    } else {
      ActionControl(
        kind: TodoModel.kind, action: "setDone",
        args: ["id": item.id, "date": day, "done": !item.done],
        fallback: todoToggleLink(item.id), allowLinks: allowLinks
      ) {
        checkIcon
      }
    }
  }

  /// Purpose: Draw the trailing time or overdue badge.
  /// Inputs: None.
  /// Returns: The trailing view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var trailing: some View {
    if item.isOverdue {
      Text(env.label("overdue", "Overdue"))
        .font(.system(size: env.pt(10), weight: .semibold)).foregroundColor(.red).lineLimit(1).fixedSize()
    } else if !item.time.isEmpty && !item.done {
      Text(item.time)
        .font(.system(size: env.pt(10), weight: .semibold, design: .rounded).monospacedDigit())
        .foregroundColor(.secondary).lineLimit(1).fixedSize()
    }
  }
}

/// A column of rows.
struct TodoRows: View {
  let items: [TodoItem]
  let day: String
  let env: MyDayEnvelope
  let allowLinks: Bool

  /// Purpose: Draw the rows.
  /// Inputs: None.
  /// Returns: The column view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(Array(items.enumerated()), id: \.offset) { pair in
        TodoRow(item: pair.element, day: day, env: env, allowLinks: allowLinks)
      }
    }
  }
}

/// The "Open MyDay to update" state for a stale snapshot.
struct TodoStaleView: View {
  let env: MyDayEnvelope

  /// Purpose: Draw the stale state.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      MyDayHeader(symbol: "checklist", title: "MyDay", env: env)
      Spacer(minLength: 0)
      Text(env.label("stale", "Open MyDay to update"))
        .font(.system(size: env.pt(13), weight: .semibold)).lineLimit(2)
      Spacer(minLength: 0)
    }
  }
}

/// systemSmall: date, open count, progress bar and up to three rows.
struct TodoSmallView: View {
  let entry: TodoEntry
  let model: TodoModel

  /// Purpose: Draw the small widget.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    if let day = model.today(at: entry.date) {
      content(day)
    } else {
      TodoStaleView(env: entry.env)
    }
  }

  /// Purpose: Draw the small layout for a day.
  /// Inputs: `day`.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: Rows drop at large text sizes.
  private func content(_ day: TodoDay) -> some View {
    let env = entry.env
    let text = TodoText(env: env)
    return VStack(alignment: .leading, spacing: 0) {
      MyDayHeader(symbol: "checklist", title: day.title, env: env)
      Spacer(minLength: 3)
      Text(day.openCount > 0 ? text.left(day.openCount) : text.empty(day))
        .font(.system(size: env.pt(20), weight: .bold, design: .rounded))
        .foregroundColor(myDayBrand).lineLimit(1).minimumScaleFactor(0.6).accentable()
        .sensitiveValue(env.sensitive)
      MyDayProgressBar(fraction: env.mask ? 0 : day.fraction).padding(.vertical, 4)
        .sensitiveValue(env.sensitive)
      Spacer(minLength: 3)
      TodoRows(items: Array(day.ordered.prefix(env.rows(3))), day: day.date, env: env, allowLinks: false)
        .sensitiveValue(env.sensitive)
    }
  }
}

/// systemMedium: two columns of rows, tomorrow's scheduled tasks and the day score.
struct TodoMediumView: View {
  let entry: TodoEntry
  let model: TodoModel

  /// Purpose: Draw the medium widget.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    if let day = model.today(at: entry.date) {
      content(day, tomorrow: model.tomorrow(at: entry.date))
    } else {
      TodoStaleView(env: entry.env)
    }
  }

  /// Purpose: Draw the medium layout.
  /// Inputs: `day`; `tomorrow`.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: The right column continues the rows, then previews tomorrow.
  private func content(_ day: TodoDay, tomorrow: TodoDay?) -> some View {
    let env = entry.env
    let text = TodoText(env: env)
    let perColumn = env.rows(4)
    let rows = day.ordered
    let left = Array(rows.prefix(perColumn))
    let upcoming = (tomorrow?.items ?? []).filter { $0.sched }
    let tomorrowLines = upcoming.isEmpty ? 0 : min(upcoming.count, max(1, perColumn - 2)) + 1
    let right = Array(rows.dropFirst(perColumn).prefix(max(0, perColumn - tomorrowLines)))
    return VStack(alignment: .leading, spacing: 6) {
      MyDayHeader(symbol: "checklist", title: day.title, env: env) {
        AddLink(title: env.label("new", "New"), url: myDayLink(TodoModel.kind, [("do", "add")]), env: env)
      }
      HStack(spacing: 6) {
        Text(day.openCount > 0 ? text.left(day.openCount) : text.empty(day))
          .font(.system(size: env.pt(13), weight: .bold, design: .rounded)).foregroundColor(myDayBrand)
          .lineLimit(1).accentable()
        Text(text.progress(day)).font(.system(size: env.pt(11))).foregroundColor(.secondary).lineLimit(1)
        Spacer(minLength: 4)
        if let score = day.score {
          Text(text.score(score)).font(.system(size: env.pt(11), weight: .semibold))
            .foregroundColor(.secondary).lineLimit(1)
        }
      }
      .sensitiveValue(env.sensitive)
      HStack(alignment: .top, spacing: 10) {
        TodoRows(items: left, day: day.date, env: env, allowLinks: true)
          .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .leading, spacing: 4) {
          TodoRows(items: right, day: day.date, env: env, allowLinks: true)
          if tomorrowLines > 0 {
            Text(env.label("tomorrow", "Tomorrow"))
              .font(.system(size: env.pt(10), weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
            ForEach(Array(upcoming.prefix(tomorrowLines - 1).enumerated()), id: \.offset) { pair in
              HStack(spacing: 4) {
                Image(systemName: "calendar").font(.system(size: env.pt(10))).foregroundColor(.secondary)
                Text(pair.element.displayTitle).font(.system(size: env.pt(11))).lineLimit(1)
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .sensitiveValue(env.sensitive)
      Spacer(minLength: 0)
    }
  }
}

/// systemLarge: up to ten rows.
struct TodoLargeView: View {
  let entry: TodoEntry
  let model: TodoModel

  /// Purpose: Draw the large widget.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    if let day = model.today(at: entry.date) {
      content(day)
    } else {
      TodoStaleView(env: entry.env)
    }
  }

  /// Purpose: Draw the large layout.
  /// Inputs: `day`.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  private func content(_ day: TodoDay) -> some View {
    let env = entry.env
    let text = TodoText(env: env)
    return VStack(alignment: .leading, spacing: 8) {
      MyDayHeader(symbol: "checklist", title: day.title, env: env) {
        AddLink(title: env.label("new", "New"), url: myDayLink(TodoModel.kind, [("do", "add")]), env: env)
      }
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(day.openCount > 0 ? text.left(day.openCount) : text.empty(day))
            .font(.system(size: env.pt(22), weight: .bold, design: .rounded)).foregroundColor(myDayBrand)
            .lineLimit(1).minimumScaleFactor(0.7).accentable()
          Spacer(minLength: 4)
          Text(text.progress(day)).font(.system(size: env.pt(11))).foregroundColor(.secondary).lineLimit(1)
        }
        MyDayProgressBar(fraction: env.mask ? 0 : day.fraction)
      }
      .sensitiveValue(env.sensitive)
      TodoRows(items: Array(day.ordered.prefix(env.rows(10))), day: day.date, env: env, allowLinks: true)
        .sensitiveValue(env.sensitive)
      Spacer(minLength: 0)
      if let score = day.score {
        Text(text.score(score)).font(.system(size: env.pt(11), weight: .semibold))
          .foregroundColor(.secondary).lineLimit(1)
          .sensitiveValue(env.sensitive)
      }
    }
  }
}

/// accessoryRectangular: open count and the next task with a reminder time.
struct TodoRectangularView: View {
  let entry: TodoEntry
  let model: TodoModel

  /// Purpose: Draw the lock-screen strip.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: Not interactive; the whole strip opens the Todo tab.
  var body: some View {
    let env = entry.env
    let text = TodoText(env: env)
    return VStack(alignment: .leading, spacing: 1) {
      if let day = model.today(at: entry.date) {
        HStack(spacing: 4) {
          Image(systemName: "checklist")
          Text(day.openCount > 0 ? text.left(day.openCount) : text.empty(day))
            .font(.system(size: env.pt(15), weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .accentable()
        if let next = nextTimed(day) {
          Text(next.displayTitle).font(.system(size: env.pt(13), weight: .medium)).lineLimit(1)
          Text(next.time).font(.system(size: env.pt(11)).monospacedDigit()).foregroundColor(.secondary)
            .lineLimit(1)
        } else if let first = day.ordered.first(where: { !$0.done }) {
          Text(first.displayTitle).font(.system(size: env.pt(13), weight: .medium)).lineLimit(1)
        }
      } else {
        HStack(spacing: 4) {
          Image(systemName: "checklist")
          Text("MyDay").font(.system(size: env.pt(15), weight: .semibold)).lineLimit(1)
        }
        .accentable()
        Text(env.label("stale", "Open MyDay to update")).font(.system(size: env.pt(11))).lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .sensitiveValue(env.sensitive)
  }

  /// Purpose: Find the next open task with a reminder time.
  /// Inputs: `day`.
  /// Returns: The earliest open timed item at or after now, or nil.
  /// Side effects: None.
  /// Notes: `HH:mm` strings compare in time order.
  private func nextTimed(_ day: TodoDay) -> TodoItem? {
    let now = LocalDay.hhmm(entry.date)
    return day.items.filter { !$0.done && !$0.time.isEmpty && $0.time >= now }
      .min { $0.time < $1.time }
  }
}

/// Picks the Todo view for the current family.
struct TodoEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TodoEntry

  /// Purpose: Draw the widget for the family, or the placeholder.
  /// Inputs: None.
  /// Returns: The view with its background and tap URL.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      if family == .accessoryRectangular {
        strip.widgetBackground(Color.clear, padded: false).widgetURL(myDayLink(TodoModel.kind))
      } else {
        decoratedHome
      }
    } else {
      decoratedHome
    }
  }

  /// Purpose: Draw the home-screen content with its background and tap URL.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  private var decoratedHome: some View {
    home.widgetBackground(MyDayBackground(), padded: true).widgetURL(myDayLink(TodoModel.kind))
  }

  /// Purpose: Draw the lock-screen content.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var strip: some View {
    if let model = entry.content {
      TodoRectangularView(entry: entry, model: model)
    } else {
      HStack(spacing: 4) {
        Image(systemName: "checklist")
        Text("MyDay").font(.system(size: 15, weight: .semibold))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accentable()
    }
  }

  /// Purpose: Draw the home-screen content.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var home: some View {
    if let model = entry.content {
      switch family {
      case .systemLarge:
        TodoLargeView(entry: entry, model: model)
      case .systemMedium:
        TodoMediumView(entry: entry, model: model)
      default:
        TodoSmallView(entry: entry, model: model)
      }
    } else {
      MyDayPlaceholderView(symbol: "checklist", message: placeholderMessage(entry.env.access))
    }
  }
}

/// The Todo widget.
struct MyDayTodoWidget: Widget {
  /// Widget kind; matches `iosKinds` in `HomeWidgetService`.
  let kind = "MyDayTodoWidget"

  /// Purpose: Configure the widget.
  /// Inputs: None.
  /// Returns: The widget configuration.
  /// Side effects: None.
  /// Notes: None.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MyDayProvider<TodoModel>()) { entry in
      TodoEntryView(entry: entry)
    }
    .configurationDisplayName(galleryText("Today's tasks", zhHans: "今日待办", zhHant: "今日待辦", ja: "今日のタスク"))
    .description(
      galleryText(
        "Tasks, progress and the day score", zhHans: "任务、进度和今日评分", zhHant: "任務、進度與今日評分",
        ja: "タスク、進捗、今日のスコア"))
    .supportedFamilies(Self.families)
  }

  /// Purpose: Return the families this iOS version supports.
  /// Inputs: None.
  /// Returns: `[WidgetFamily]`.
  /// Side effects: None.
  /// Notes: The lock-screen strip needs iOS 16.
  static var families: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular]
    }
    return [.systemSmall, .systemMedium, .systemLarge]
  }
}
