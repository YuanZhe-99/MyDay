import SwiftUI
import WidgetKit

// Timer widget (MyDayTimerWidget, systemSmall): the Intimacy stopwatch. While
// running, the elapsed time counts natively with Text(_:style: .timer). Start,
// Pause/Resume and +100 queue `start`, `pause` and `add` actions on iOS 17+;
// the rest of the widget, including the Finish flag, opens the timer page.
// Renders the myday.timer envelope; see doc/en-us/features/home-screen-widgets.md.

// MARK: - Model

/// The stopwatch session.
struct TimerSession {
  var running: Bool
  /// Epoch ms when the current run started; nil while paused.
  var startedAt: Int64?
  var accumulatedMs: Int64
  var count: Int
}

/// The myday.timer payload with pending taps replayed.
struct TimerModel: MyDayKindModel {
  static let kind = "myday.timer"
  var session: TimerSession?
  let lastAt: Date?
  let lastDurationMs: Int64
  let step: Int
  let generatedAt: Date

  /// Purpose: Build the model and replay pending taps.
  /// Inputs: `env`.
  /// Returns: `TimerModel`.
  /// Side effects: None.
  /// Notes: `start`: none → running from `at`, paused → resume at `at`,
  /// running → nothing. `pause`: running → accumulate `at − startedAt`.
  /// `add`: any session → count += `n`.
  static func make(from env: MyDayEnvelope) -> TimerModel? {
    let p = env.payload
    var session: TimerSession?
    if let s = PayloadValue.object(p["session"]) {
      let running = PayloadValue.bool(s["running"])
      session = TimerSession(
        running: running, startedAt: running ? PayloadValue.int64(s["startedAt"]) : nil,
        accumulatedMs: PayloadValue.int64(s["accumulatedMs"]) ?? 0,
        count: PayloadValue.int(s["count"]) ?? 0)
    }
    let step = PayloadValue.int(p["step"]) ?? 100
    for action in env.pending {
      switch action.action {
      case "start":
        if var current = session {
          if !current.running {
            current.running = true
            current.startedAt = action.at
            session = current
          }
        } else {
          session = TimerSession(running: true, startedAt: action.at, accumulatedMs: 0, count: 0)
        }
      case "pause":
        if var current = session, current.running {
          current.accumulatedMs += max(0, action.at - (current.startedAt ?? action.at))
          current.running = false
          current.startedAt = nil
          session = current
        }
      case "add":
        if var current = session {
          current.count += PayloadValue.int(action.args["n"]) ?? step
          session = current
        }
      default:
        break
      }
    }
    let last = PayloadValue.object(p["last"])
    return TimerModel(
      session: session,
      lastAt: PayloadValue.int64(last?["at"]).map { LocalDay.date(ms: $0) },
      lastDurationMs: PayloadValue.int64(last?["durationMs"]) ?? 0,
      step: step,
      generatedAt: Date())
  }

  /// Purpose: Return the instant the running stopwatch counts from.
  /// Inputs: None.
  /// Returns: `startedAt − accumulated`, or nil unless running.
  /// Side effects: None.
  /// Notes: `Text(_:style: .timer)` shows the time since this instant.
  var anchor: Date? {
    guard let session = session, session.running else { return nil }
    let started = session.startedAt.map { LocalDay.date(ms: $0) } ?? generatedAt
    return started.addingTimeInterval(-TimeInterval(session.accumulatedMs) / 1000)
  }

  /// Purpose: Return the elapsed milliseconds of a paused session.
  /// Inputs: None.
  /// Returns: `accumulatedMs`, or 0 without a session.
  /// Side effects: None.
  /// Notes: None.
  var pausedMs: Int64 { session?.accumulatedMs ?? 0 }

  /// Purpose: Return the day boundary.
  /// Inputs: `now`.
  /// Returns: The next midnight.
  /// Side effects: None.
  /// Notes: The idle "last" line switches from "today" at midnight.
  func refreshDates(after now: Date) -> [Date] { [LocalDay.nextMidnight(after: now)] }

  /// Purpose: Return the gallery sample.
  /// Inputs: None.
  /// Returns: A running session.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] {
    let now = Date().timeIntervalSince1970 * 1000
    return [
      "session": ["running": true, "startedAt": now - 754_000, "accumulatedMs": 0, "count": 300]
        as [String: Any],
      "step": 100, "mask": false, "labels": [:] as [String: String],
    ]
  }
}

typealias TimerEntry = MyDayEntry<TimerModel>

/// Purpose: Format a duration as a stopwatch reading.
/// Inputs: `ms`.
/// Returns: `mm:ss`, or `h:mm:ss` from one hour.
/// Side effects: None.
/// Notes: None.
func stopwatchText(_ ms: Int64) -> String {
  let seconds = Int(max(0, ms / 1000))
  let h = seconds / 3600
  let m = (seconds % 3600) / 60
  let s = seconds % 60
  return h > 0 ? String(format: "%ld:%02ld:%02ld", h, m, s) : String(format: "%02ld:%02ld", m, s)
}

// MARK: - Views

/// A round control pill.
struct TimerPill<Content: View>: View {
  let env: MyDayEnvelope
  let strong: Bool
  let content: Content

  /// Purpose: Create a pill.
  /// Inputs: `env`; `strong` — filled brand style; `content`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(env: MyDayEnvelope, strong: Bool = false, @ViewBuilder content: () -> Content) {
    self.env = env
    self.strong = strong
    self.content = content()
  }

  /// Purpose: Draw the pill.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    content
      .font(.system(size: env.pt(12), weight: .bold, design: .rounded))
      .foregroundColor(strong ? .white : myDayBrand)
      .lineLimit(1)
      .frame(maxWidth: .infinity, minHeight: env.pt(26))
      .background(Capsule().fill(strong ? myDayBrand : myDayBrand.opacity(0.15)))
      .accentable()
  }
}

/// systemSmall: state, elapsed time, count and the controls.
struct TimerSmallView: View {
  let entry: TimerEntry
  let model: TimerModel

  /// Purpose: Draw the timer card.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    let env = entry.env
    return VStack(alignment: .leading, spacing: 2) {
      MyDayHeader(symbol: "stopwatch", title: env.label("title", "Timer"), env: env) {
        if let session = model.session {
          Text(session.running ? env.label("running", "Running") : env.label("paused", "Paused"))
            .font(.system(size: env.pt(10), weight: .semibold))
            .foregroundColor(session.running ? myDayBrand : .orange).lineLimit(1)
        }
      }
      Spacer(minLength: 2)
      if let session = model.session {
        elapsed.sensitiveValue(env.sensitive)
        Text(env.label("count", "Count {n}", n: env.masked(String(session.count))))
          .font(.system(size: env.pt(11), weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
          .sensitiveValue(env.sensitive)
      } else {
        Text(env.label("idle", "Not running"))
          .font(.system(size: env.pt(15), weight: .semibold)).lineLimit(1)
        if let line = lastLine() {
          Text(line).font(.system(size: env.pt(11))).foregroundColor(.secondary).lineLimit(2)
            .sensitiveValue(env.sensitive)
        }
      }
      Spacer(minLength: 4)
      controls
    }
  }

  /// Purpose: Draw the elapsed time.
  /// Inputs: None.
  /// Returns: A live timer while running, a static reading while paused.
  /// Side effects: None.
  /// Notes: Masked under *Hide values*, which also stops the live count.
  @ViewBuilder private var elapsed: some View {
    if entry.env.mask {
      Text(verbatim: "\(myDayMaskShort):\(myDayMaskShort)")
        .font(.system(size: entry.env.pt(28), weight: .bold, design: .rounded))
        .foregroundColor(myDayBrand).lineLimit(1).accentable()
    } else if let anchor = model.anchor {
      Text(anchor, style: .timer)
        .font(.system(size: entry.env.pt(28), weight: .bold, design: .rounded).monospacedDigit())
        .foregroundColor(myDayBrand).lineLimit(1).minimumScaleFactor(0.6).accentable()
    } else {
      Text(stopwatchText(model.pausedMs))
        .font(.system(size: entry.env.pt(28), weight: .bold, design: .rounded).monospacedDigit())
        .foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.6)
    }
  }

  /// Purpose: Draw the Start / Pause / Resume, +100 and Finish controls.
  /// Inputs: None.
  /// Returns: The control row.
  /// Side effects: Taps queue actions on iOS 17+.
  /// Notes: Finish is not a button: the widget URL opens the timer page.
  private var controls: some View {
    let env = entry.env
    let running = model.session?.running ?? false
    let open = myDayLink(TimerModel.kind, [("do", "timer")])
    return HStack(spacing: 5) {
      ActionControl(kind: TimerModel.kind, action: running ? "pause" : "start", fallback: open, allowLinks: false) {
        TimerPill(env: env, strong: true) {
          Image(systemName: running ? "pause.fill" : "play.fill")
        }
      }
      if model.session != nil {
        ActionControl(
          kind: TimerModel.kind, action: "add", args: ["n": model.step], fallback: open, allowLinks: false
        ) {
          TimerPill(env: env) { Text(verbatim: "+\(model.step)") }
        }
        TimerPill(env: env) { Image(systemName: "flag.checkered") }
      }
    }
  }

  /// Purpose: Format the last session line for the idle state.
  /// Inputs: None.
  /// Returns: "Last today · 24 min" or "Last 11/2 · 24 min", or nil without one.
  /// Side effects: None.
  /// Notes: `{n}` of `labels.last` is a short local date.
  private func lastLine() -> String? {
    guard let at = model.lastAt else { return nil }
    let env = entry.env
    let minutes = env.masked(String(Int((Double(model.lastDurationMs) / 60000).rounded())))
    if LocalDay.days(from: at, to: entry.date) == 0 {
      return env.label("lastToday", "Last today · {m} min", n: "", m: minutes)
    }
    return env.label("last", "Last {n} · {m} min", n: LocalDay.shortDate(at), m: minutes)
  }
}

/// Picks the Timer view, or the placeholder.
struct TimerEntryView: View {
  let entry: TimerEntry

  /// Purpose: Draw the widget.
  /// Inputs: None.
  /// Returns: The view with its background and tap URL.
  /// Side effects: None.
  /// Notes: The widget URL opens the timer page, which is also Finish.
  var body: some View {
    content.widgetBackground(MyDayBackground(), padded: true)
      .widgetURL(myDayLink(TimerModel.kind, [("do", "timer")]))
  }

  /// Purpose: Draw the card or the placeholder.
  /// Inputs: None.
  /// Returns: The view.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var content: some View {
    if let model = entry.content {
      TimerSmallView(entry: entry, model: model)
    } else {
      MyDayPlaceholderView(symbol: "stopwatch", message: placeholderMessage(entry.env.access))
    }
  }
}

/// The Timer widget.
struct MyDayTimerWidget: Widget {
  /// Widget kind; matches `iosKinds` in `HomeWidgetService`.
  let kind = "MyDayTimerWidget"

  /// Purpose: Configure the widget.
  /// Inputs: None.
  /// Returns: The widget configuration.
  /// Side effects: None.
  /// Notes: Home screen only: the kind is `sensitive` by default.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MyDayProvider<TimerModel>()) { entry in
      TimerEntryView(entry: entry)
    }
    .configurationDisplayName(galleryText("Timer", zhHans: "计时器", zhHant: "計時器", ja: "タイマー"))
    .description(
      galleryText(
        "Start, pause and count from the home screen", zhHans: "在主屏幕上开始、暂停和计数",
        zhHant: "在主畫面上開始、暫停和計數", ja: "ホーム画面から開始・一時停止・カウント"))
    .supportedFamilies([.systemSmall])
  }
}
