import SwiftUI
import WidgetKit

#if canImport(AppIntents)
  import AppIntents
#endif

// MyDay!!!!! home-screen widgets: the WidgetKit extension that renders the
// MyApps-Widget envelopes lib/shared/services/home_widget_service.dart
// publishes (kinds myday.todo, myday.weight, myday.finance, myday.intimacy and
// myday.timer). The envelopes are read with MyAppsWidgetKit.swift, compiled
// into this target from packages/myapps_widget. Payload formats, privacy and
// deep links are documented in doc/en-us/features/home-screen-widgets.md.
// This file holds the shared reading, timeline and styling code and the
// widget bundle; each kind lives in its own MyDay*Widget.swift file.

/// App Group shared with Runner; matches `HomeWidgetService`'s bridge.
let myDayAppGroupId = "group.com.yuanzhe.myDay"
/// Brand indigo (#303F9F), used as a soft tint.
let myDayBrand = Color(red: 0x30 / 255, green: 0x3F / 255, blue: 0x9F / 255)
/// The real minus sign for signed values.
let myDayMinus = "\u{2212}"
/// Mask for numbers under *Hide values*.
let myDayMaskShort = "••"
/// Mask for amounts under *Hide values*.
let myDayMaskLong = "••••"

// MARK: - Payload values

/// Tolerant readers for the untyped payload JSON.
enum PayloadValue {
  /// Purpose: Read a finite JSON number, excluding booleans.
  /// Inputs: `value` — any JSON value.
  /// Returns: The number as `Double`, or nil.
  /// Side effects: None.
  /// Notes: `JSONSerialization` returns booleans as `NSNumber` too.
  static func number(_ value: Any?) -> Double? {
    guard let n = value as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return nil }
    let d = n.doubleValue
    return d.isFinite ? d : nil
  }

  /// Purpose: Read a JSON number as a rounded `Int`.
  /// Inputs: `value`.
  /// Returns: `Int`, or nil for non-numbers and out-of-range values.
  /// Side effects: None.
  /// Notes: None.
  static func int(_ value: Any?) -> Int? {
    guard let d = number(value), abs(d) < 9e15 else { return nil }
    return Int(d.rounded())
  }

  /// Purpose: Read a JSON number as a rounded `Int64`, for epoch milliseconds.
  /// Inputs: `value`.
  /// Returns: `Int64`, or nil.
  /// Side effects: None.
  /// Notes: None.
  static func int64(_ value: Any?) -> Int64? {
    guard let d = number(value), abs(d) < 9e15 else { return nil }
    return Int64(d.rounded())
  }

  /// Purpose: Read a JSON string.
  /// Inputs: `value`.
  /// Returns: The string, or "" for anything else (including null).
  /// Side effects: None.
  /// Notes: None.
  static func string(_ value: Any?) -> String { value as? String ?? "" }

  /// Purpose: Read a JSON boolean.
  /// Inputs: `value`.
  /// Returns: The boolean, or false for anything else.
  /// Side effects: None.
  /// Notes: None.
  static func bool(_ value: Any?) -> Bool { value as? Bool ?? false }

  /// Purpose: Read a JSON object.
  /// Inputs: `value`.
  /// Returns: The dictionary, or nil (also for null).
  /// Side effects: None.
  /// Notes: None.
  static func object(_ value: Any?) -> [String: Any]? { value as? [String: Any] }

  /// Purpose: Read a JSON array of objects.
  /// Inputs: `value`.
  /// Returns: The objects; non-object elements are skipped.
  /// Side effects: None.
  /// Notes: None.
  static func objects(_ value: Any?) -> [[String: Any]] {
    (value as? [Any] ?? []).compactMap { $0 as? [String: Any] }
  }

  /// Purpose: Read a JSON array of strings.
  /// Inputs: `value`.
  /// Returns: The strings; other elements are skipped.
  /// Side effects: None.
  /// Notes: None.
  static func strings(_ value: Any?) -> [String] {
    (value as? [Any] ?? []).compactMap { $0 as? String }
  }

  /// Purpose: Read a JSON array of numbers.
  /// Inputs: `value`.
  /// Returns: The numbers; other elements are skipped.
  /// Side effects: None.
  /// Notes: None.
  static func numbers(_ value: Any?) -> [Double] {
    (value as? [Any] ?? []).compactMap { number($0) }
  }
}

// MARK: - Local days

/// Local-calendar helpers; day keys are `yyyy-MM-dd` in the device zone, like
/// `HomeWidgetPayloads.dayKey`.
enum LocalDay {
  /// Purpose: Return the Gregorian calendar in the device zone.
  /// Inputs: None.
  /// Returns: `Calendar`.
  /// Side effects: None.
  /// Notes: Gregorian on purpose: the app's keys never use the user's display calendar.
  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  /// Purpose: Format a date's local day key.
  /// Inputs: `date`.
  /// Returns: `yyyy-MM-dd`.
  /// Side effects: None.
  /// Notes: None.
  static func key(_ date: Date) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04ld-%02ld-%02ld", c.year ?? 0, c.month ?? 0, c.day ?? 0)
  }

  /// Purpose: Format a date's local month key.
  /// Inputs: `date`.
  /// Returns: `yyyy-MM`.
  /// Side effects: None.
  /// Notes: None.
  static func monthKey(_ date: Date) -> String {
    let c = calendar.dateComponents([.year, .month], from: date)
    return String(format: "%04ld-%02ld", c.year ?? 0, c.month ?? 0)
  }

  /// Purpose: Parse a day key to its local midnight.
  /// Inputs: `key` — `yyyy-MM-dd`.
  /// Returns: `Date`, or nil when malformed.
  /// Side effects: None.
  /// Notes: None.
  static func parse(_ key: String) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }

  /// Purpose: Return the next local midnight after a date.
  /// Inputs: `date`.
  /// Returns: `Date`.
  /// Side effects: None.
  /// Notes: Used for the Todo day flip and the bill/cycle day boundaries.
  static func nextMidnight(after date: Date) -> Date {
    let cal = calendar
    return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date))
      ?? date.addingTimeInterval(24 * 3600)
  }

  /// Purpose: Combine a day with an `HH:mm` time of day.
  /// Inputs: `hhmm`; `day` — any instant of the day.
  /// Returns: `Date`, or nil when `hhmm` is empty or malformed.
  /// Side effects: None.
  /// Notes: None.
  static func time(_ hhmm: String, on day: Date) -> Date? {
    let parts = hhmm.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2, (0..<24).contains(parts[0]), (0..<60).contains(parts[1]) else { return nil }
    return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day)
  }

  /// Purpose: Count local calendar days between two instants.
  /// Inputs: `from`, `to`.
  /// Returns: Days from `from`'s day to `to`'s day; negative when `to` is earlier.
  /// Side effects: None.
  /// Notes: None.
  static func days(from: Date, to: Date) -> Int {
    let cal = calendar
    return cal.dateComponents([.day], from: cal.startOfDay(for: from), to: cal.startOfDay(for: to)).day ?? 0
  }

  /// Purpose: Format a local time of day.
  /// Inputs: `date`.
  /// Returns: `HH:mm`.
  /// Side effects: None.
  /// Notes: None.
  static func hhmm(_ date: Date) -> String {
    let c = calendar.dateComponents([.hour, .minute], from: date)
    return String(format: "%02ld:%02ld", c.hour ?? 0, c.minute ?? 0)
  }

  /// Purpose: Format a short numeric date in the device locale.
  /// Inputs: `date`.
  /// Returns: For example "11/2" or "11月2日".
  /// Side effects: None.
  /// Notes: Used where the payload carries no wording for a date.
  static func shortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.timeZone = .current
    formatter.setLocalizedDateFormatFromTemplate("Md")
    return formatter.string(from: date)
  }

  /// Purpose: Convert epoch milliseconds to a date.
  /// Inputs: `ms`.
  /// Returns: `Date`.
  /// Side effects: None.
  /// Notes: None.
  static func date(ms: Int64) -> Date { Date(timeIntervalSince1970: TimeInterval(ms) / 1000) }
}

// MARK: - Envelope

/// What a widget may draw.
enum MyDayAccess {
  /// The payload may be rendered.
  case content
  /// Missing, invalid or `hidden`: the neutral placeholder.
  case placeholder
  /// Written by a newer app: the placeholder with "Open MyDay to update".
  case tooNew
}

/// One kind's envelope as the renderers use it, with its pending actions.
struct MyDayEnvelope {
  let access: MyDayAccess
  let payload: [String: Any]
  let textScale: CGFloat
  /// Envelope privacy is `sensitive`: value views are `privacySensitive`.
  let sensitive: Bool
  let refreshDates: [Date]
  /// Queued taps not yet in `payload.appliedActions`, oldest first.
  let pending: [WidgetAction]

  /// Purpose: Return the envelope state that draws the neutral placeholder.
  /// Inputs: None.
  /// Returns: `MyDayEnvelope`.
  /// Side effects: None.
  /// Notes: None.
  static var placeholder: MyDayEnvelope {
    MyDayEnvelope(
      access: .placeholder, payload: [:], textScale: 1, sensitive: false, refreshDates: [], pending: [])
  }

  /// Purpose: Read a kind's stored envelope and its pending actions.
  /// Inputs: `kind` — the envelope kind, for example `myday.todo`.
  /// Returns: `MyDayEnvelope`.
  /// Side effects: Reads the App Group `UserDefaults`.
  /// Notes: `hidden`, missing and invalid envelopes all read as `.placeholder`.
  static func load(kind: String) -> MyDayEnvelope {
    let read = WidgetEnvelopeStore.read(kind: kind, appGroupId: myDayAppGroupId)
    switch read.status {
    case .ok:
      guard let envelope = read.envelope, envelope.privacy != .hidden else { return .placeholder }
      let applied = Set(PayloadValue.strings(envelope.payload["appliedActions"]))
      let pending = WidgetActionQueue.pending(kind: kind, appGroupId: myDayAppGroupId)
        .filter { !applied.contains($0.id) }
      return MyDayEnvelope(
        access: .content, payload: envelope.payload, textScale: CGFloat(envelope.textScale),
        sensitive: envelope.privacy == .sensitive, refreshDates: envelope.refreshDates,
        pending: pending)
    case .tooNew:
      return MyDayEnvelope(
        access: .tooNew, payload: [:], textScale: 1, sensitive: false, refreshDates: [], pending: [])
    case .missing, .invalid:
      return .placeholder
    }
  }

  /// Purpose: Wrap a sample payload for the gallery and placeholders.
  /// Inputs: `payload`.
  /// Returns: `MyDayEnvelope` with content access.
  /// Side effects: None.
  /// Notes: None.
  static func sample(_ payload: [String: Any]) -> MyDayEnvelope {
    MyDayEnvelope(
      access: .content, payload: payload, textScale: 1, sensitive: false, refreshDates: [], pending: [])
  }

  /// Purpose: Return the payload's labels.
  /// Inputs: None.
  /// Returns: `[String: String]`; non-string values are skipped.
  /// Side effects: None.
  /// Notes: None.
  var labels: [String: String] {
    var result: [String: String] = [:]
    for (key, value) in PayloadValue.object(payload["labels"]) ?? [:] {
      if let text = value as? String { result[key] = text }
    }
    return result
  }

  /// Purpose: Return whether *Hide values* is on.
  /// Inputs: None.
  /// Returns: `Bool`.
  /// Side effects: None.
  /// Notes: None.
  var mask: Bool { PayloadValue.bool(payload["mask"]) }

  /// Purpose: Scale a font size by the user's widget text size.
  /// Inputs: `size` — points at 100%.
  /// Returns: The scaled size.
  /// Side effects: None.
  /// Notes: Every text goes through this.
  func pt(_ size: CGFloat) -> CGFloat { size * textScale }

  /// Purpose: Return how many rows fit when `base` fit at 100%.
  /// Inputs: `base`.
  /// Returns: At least 1.
  /// Side effects: None.
  /// Notes: Large text sizes drop rows instead of clipping them.
  func rows(_ base: Int) -> Int { max(1, Int((CGFloat(base) / textScale + 0.35).rounded(.down))) }

  /// Purpose: Return a payload label, falling back to English.
  /// Inputs: `key`; `fallback`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  func label(_ key: String, _ fallback: String) -> String {
    let text = labels[key] ?? ""
    return text.isEmpty ? fallback : text
  }

  /// Purpose: Return a payload label with its placeholders filled.
  /// Inputs: `key`; `fallback`; `n` replaces `{n}`; `m` replaces `{m}`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  func label(_ key: String, _ fallback: String, n: String, m: String = "") -> String {
    label(key, fallback).replacingOccurrences(of: "{n}", with: n).replacingOccurrences(of: "{m}", with: m)
  }

  /// Purpose: Apply *Hide values* to a number or amount.
  /// Inputs: `value`; `long` — use the amount mask.
  /// Returns: The value, or `••` / `••••`.
  /// Side effects: None.
  /// Notes: None.
  func masked(_ value: String, long: Bool = false) -> String {
    mask ? (long ? myDayMaskLong : myDayMaskShort) : value
  }
}

// MARK: - Timeline

/// One kind's typed model, built from the envelope with pending actions replayed.
protocol MyDayKindModel {
  /// Envelope kind, for example `myday.todo`.
  static var kind: String { get }

  /// Purpose: Build the model from an envelope.
  /// Inputs: `env`.
  /// Returns: The model, or nil when the payload is unusable.
  /// Side effects: None.
  /// Notes: Replays `env.pending` over the payload.
  static func make(from env: MyDayEnvelope) -> Self?

  /// Purpose: Return the sample payload for the gallery.
  /// Inputs: None.
  /// Returns: A payload dictionary.
  /// Side effects: None.
  /// Notes: None.
  static var samplePayload: [String: Any] { get }

  /// Purpose: Return the instants at which the rendering changes.
  /// Inputs: `now`.
  /// Returns: Dates; past ones are ignored by the provider.
  /// Side effects: None.
  /// Notes: None.
  func refreshDates(after now: Date) -> [Date]
}

/// The widget state at one instant.
struct MyDayEntry<Model: MyDayKindModel>: TimelineEntry {
  let date: Date
  let env: MyDayEnvelope
  let model: Model?

  /// Purpose: Return the sample entry for the gallery and placeholders.
  /// Inputs: `date`.
  /// Returns: `MyDayEntry`.
  /// Side effects: None.
  /// Notes: None.
  static func sample(at date: Date) -> MyDayEntry<Model> {
    let env = MyDayEnvelope.sample(Model.samplePayload)
    return MyDayEntry(date: date, env: env, model: Model.make(from: env))
  }

  /// Purpose: Return whether the entry's content may be drawn.
  /// Inputs: None.
  /// Returns: The model when access is `.content`, else nil.
  /// Side effects: None.
  /// Notes: None.
  var content: Model? { env.access == .content ? model : nil }
}

/// Builds every kind's timeline: an entry now and at each instant the model
/// reports (midnight, reminder times, ...), reloading after the last one.
struct MyDayProvider<Model: MyDayKindModel>: TimelineProvider {
  /// Purpose: Return the redacted placeholder entry.
  /// Inputs: `context`.
  /// Returns: The sample entry.
  /// Side effects: None.
  /// Notes: None.
  func placeholder(in context: Context) -> MyDayEntry<Model> { MyDayEntry<Model>.sample(at: Date()) }

  /// Purpose: Return the entry for the gallery or a transient view.
  /// Inputs: `context`, `completion`.
  /// Returns: None; calls `completion`.
  /// Side effects: Reads the App Group.
  /// Notes: The gallery shows sample data until the app has written an envelope.
  func getSnapshot(in context: Context, completion: @escaping (MyDayEntry<Model>) -> Void) {
    let env = MyDayEnvelope.load(kind: Model.kind)
    if context.isPreview && env.access != .content {
      completion(MyDayEntry<Model>.sample(at: Date()))
      return
    }
    completion(MyDayEntry(date: Date(), env: env, model: Model.make(from: env)))
  }

  /// Purpose: Return the timeline for the next day.
  /// Inputs: `context`, `completion`.
  /// Returns: None; calls `completion`.
  /// Side effects: Reads the App Group.
  /// Notes: The app reloads timelines on every publish and WidgetKit reloads
  /// after an intent runs, so the policy only covers time passing.
  func getTimeline(in context: Context, completion: @escaping (Timeline<MyDayEntry<Model>>) -> Void) {
    let now = Date()
    let env = MyDayEnvelope.load(kind: Model.kind)
    let model = env.access == .content ? Model.make(from: env) : nil
    let horizon = now.addingTimeInterval(24 * 3600)
    var dates: Set<Date> = [now]
    let candidates = (model?.refreshDates(after: now) ?? [LocalDay.nextMidnight(after: now)]) + env.refreshDates
    for date in candidates where date > now && date <= horizon {
      dates.insert(date)
    }
    let sorted = Array(dates.sorted().prefix(48))
    let entries = sorted.map { MyDayEntry(date: $0, env: env, model: model) }
    let last = sorted.last ?? now
    let reload = last > now ? max(last, now.addingTimeInterval(15 * 60)) : now.addingTimeInterval(3600)
    completion(Timeline(entries: entries, policy: .after(reload)))
  }
}

// MARK: - Links and controls

/// Purpose: Build a widget deep link.
/// Inputs: `kind` — the envelope kind; `query` — `(name, value)` pairs in order.
/// Returns: `myday://widget/<kind>?...`.
/// Side effects: None.
/// Notes: Values are percent-encoded by `URLComponents`.
func myDayLink(_ kind: String, _ query: [(String, String)] = []) -> URL {
  var components = URLComponents()
  components.scheme = "myday"
  components.host = "widget"
  components.path = "/" + kind
  if !query.isEmpty {
    components.queryItems = query.map { URLQueryItem(name: $0.0, value: $0.1) }
  }
  return components.url ?? URL(string: "myday://widget")!
}

/// An interactive control: a `MyAppsWidgetActionIntent` button on iOS 17+, a
/// deep link before (or the bare label where links are not supported).
struct ActionControl<Content: View>: View {
  let kind: String
  let action: String
  let args: [String: Any]
  let fallback: URL
  /// False in systemSmall, which supports only `widgetURL`.
  let allowLinks: Bool
  let content: Content

  /// Purpose: Create a control.
  /// Inputs: `kind`; `action`; `args`; `fallback` — the iOS 14–16 deep link;
  /// `allowLinks`; `content` — the label.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(
    kind: String, action: String, args: [String: Any] = [:], fallback: URL, allowLinks: Bool,
    @ViewBuilder content: () -> Content
  ) {
    self.kind = kind
    self.action = action
    self.args = args
    self.fallback = fallback
    self.allowLinks = allowLinks
    self.content = content()
  }

  #if canImport(AppIntents)
    /// Purpose: Draw the intent button or the fallback.
    /// Inputs: None.
    /// Returns: The control view.
    /// Side effects: A tap queues the action (iOS 17+) or opens the app.
    /// Notes: None.
    var body: some View {
      if #available(iOSApplicationExtension 17.0, *) {
        Button(
          intent: MyAppsWidgetActionIntent(
            kind: kind, action: action, args: args, appGroupId: myDayAppGroupId)
        ) {
          content
        }
        .buttonStyle(PlainButtonStyle())
      } else {
        linkFallback
      }
    }
  #else
    /// Purpose: Draw the fallback when the SDK has no AppIntents.
    /// Inputs: None.
    /// Returns: The control view.
    /// Side effects: A tap opens the app.
    /// Notes: None.
    var body: some View { linkFallback }
  #endif

  /// Purpose: Draw the pre-iOS 17 fallback.
  /// Inputs: None.
  /// Returns: A `Link`, or the bare label where links are unsupported.
  /// Side effects: None.
  /// Notes: None.
  @ViewBuilder private var linkFallback: some View {
    if allowLinks {
      Link(destination: fallback) { content }
    } else {
      content
    }
  }
}

/// A small "+ New" style button that opens an add dialog (medium and large only).
struct AddLink: View {
  let title: String
  let url: URL
  let env: MyDayEnvelope

  /// Purpose: Draw the button.
  /// Inputs: None.
  /// Returns: The link view.
  /// Side effects: A tap opens the app.
  /// Notes: None.
  var body: some View {
    Link(destination: url) {
      HStack(spacing: 2) {
        Image(systemName: "plus")
        Text(title).lineLimit(1)
      }
      .font(.system(size: env.pt(11), weight: .semibold))
      .foregroundColor(myDayBrand)
      .padding(.horizontal, 7)
      .padding(.vertical, 2)
      .background(Capsule().fill(myDayBrand.opacity(0.15)))
      .accentable()
    }
  }
}

// MARK: - Styling

extension View {
  /// Purpose: Mark a view as accented in tinted and lock-screen rendering.
  /// Inputs: None.
  /// Returns: The modified view.
  /// Side effects: None.
  /// Notes: No-op before iOS 16.
  @ViewBuilder func accentable() -> some View {
    if #available(iOSApplicationExtension 16.0, *) {
      widgetAccentable()
    } else {
      self
    }
  }

  /// Purpose: Mark a value view as private when the envelope is `sensitive`.
  /// Inputs: `sensitive`.
  /// Returns: The modified view.
  /// Side effects: None.
  /// Notes: Redacted while the device is locked; no-op before iOS 15.
  @ViewBuilder func sensitiveValue(_ sensitive: Bool) -> some View {
    if #available(iOSApplicationExtension 15.0, *) {
      privacySensitive(sensitive)
    } else {
      self
    }
  }

  /// Purpose: Apply the widget container background on every iOS version.
  /// Inputs: `background`; `padded` — add the system margin before iOS 17.
  /// Returns: The modified view.
  /// Side effects: None.
  /// Notes: iOS 17 requires `containerBackground` and adds margins itself.
  @ViewBuilder func widgetBackground<B: View>(_ background: B, padded: Bool) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      padding(padded ? 16 : 0).background(background)
    }
  }
}

/// The soft brand tint over the system background, light and dark.
struct MyDayBackground: View {
  /// Purpose: Draw the background.
  /// Inputs: None.
  /// Returns: The background view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    ZStack {
      Color(UIColor.systemBackground)
      LinearGradient(
        gradient: Gradient(colors: [myDayBrand.opacity(0.16), myDayBrand.opacity(0.02)]),
        startPoint: .topLeading, endPoint: .bottomTrailing)
    }
  }
}

/// A widget header: symbol, title and an optional trailing view.
struct MyDayHeader<Trailing: View>: View {
  let symbol: String
  let title: String
  let env: MyDayEnvelope
  let trailing: Trailing

  /// Purpose: Create a header.
  /// Inputs: `symbol` — SF Symbol name; `title`; `env`; `trailing`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(symbol: String, title: String, env: MyDayEnvelope, @ViewBuilder trailing: () -> Trailing) {
    self.symbol = symbol
    self.title = title
    self.env = env
    self.trailing = trailing()
  }

  /// Purpose: Draw the header row.
  /// Inputs: None.
  /// Returns: The header view.
  /// Side effects: None.
  /// Notes: None.
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: symbol)
        .font(.system(size: env.pt(13), weight: .semibold)).foregroundColor(myDayBrand).accentable()
      Text(title)
        .font(.system(size: env.pt(12), weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
      Spacer(minLength: 4)
      trailing
    }
  }
}

extension MyDayHeader where Trailing == EmptyView {
  /// Purpose: Create a header without a trailing view.
  /// Inputs: `symbol`; `title`; `env`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  init(symbol: String, title: String, env: MyDayEnvelope) {
    self.init(symbol: symbol, title: title, env: env) { EmptyView() }
  }
}

/// A thin capsule progress bar.
struct MyDayProgressBar: View {
  let fraction: Double

  /// Purpose: Draw the bar.
  /// Inputs: None.
  /// Returns: The bar view.
  /// Side effects: None.
  /// Notes: `fraction` is clamped to 0...1.
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(myDayBrand.opacity(0.18))
        Capsule().fill(myDayBrand)
          .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)))
          .accentable()
      }
    }
    .frame(height: 4)
  }
}

/// The neutral placeholder: SF Symbol and "MyDay", optionally a message.
struct MyDayPlaceholderView: View {
  let symbol: String
  let message: String?

  /// Purpose: Draw the placeholder.
  /// Inputs: None.
  /// Returns: The placeholder view.
  /// Side effects: None.
  /// Notes: Shows nothing from the payload.
  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: symbol)
        .font(.system(size: 24, weight: .semibold)).foregroundColor(myDayBrand).accentable()
      Text("MyDay").font(.system(size: 13, weight: .semibold)).lineLimit(1)
      if let message = message {
        Text(message).font(.system(size: 11)).foregroundColor(.secondary)
          .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Purpose: Return the placeholder message for an envelope.
/// Inputs: `access`.
/// Returns: "Open MyDay to update" for `.tooNew`, otherwise nil.
/// Side effects: None.
/// Notes: Device language, because a too-new payload cannot be trusted for labels.
func placeholderMessage(_ access: MyDayAccess) -> String? {
  guard access == .tooNew else { return nil }
  return galleryText(
    "Open MyDay to update", zhHans: "打开 MyDay 以更新", zhHant: "打開 MyDay 以更新", ja: "MyDay を開いて更新")
}

/// Purpose: Format a signed number with a real minus sign.
/// Inputs: `value`; `digits` — fraction digits.
/// Returns: For example "+1.2", "−0.4" or "0.0".
/// Side effects: None.
/// Notes: None.
func signed(_ value: Double, digits: Int = 1) -> String {
  let text = String(format: "%.\(digits)f", abs(value))
  let rounded = (abs(value) * pow(10, Double(digits))).rounded()
  if rounded == 0 { return text }
  return (value < 0 ? myDayMinus : "+") + text
}

// MARK: - Widget gallery

/// Purpose: Pick widget-gallery text for the system language.
/// Inputs: The text in English, Simplified Chinese, Traditional Chinese and Japanese.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Gallery text only; widget content strings come from the app's ARB files.
func galleryText(_ en: String, zhHans: String, zhHant: String, ja: String) -> String {
  let language = Locale.preferredLanguages.first ?? "en"
  if language.hasPrefix("zh-Hant") || language.hasPrefix("zh-TW") || language.hasPrefix("zh-HK") {
    return zhHant
  }
  if language.hasPrefix("zh") { return zhHans }
  if language.hasPrefix("ja") { return ja }
  return en
}

@main
struct MyDayWidgetBundle: WidgetBundle {
  /// Purpose: List the extension's widgets.
  /// Inputs: None.
  /// Returns: The widgets.
  /// Side effects: None.
  /// Notes: The kind strings match `iosKinds` in `HomeWidgetService`.
  var body: some Widget {
    MyDayTodoWidget()
    MyDayWeightWidget()
    MyDayFinanceWidget()
    MyDayIntimacyWidget()
    MyDayTimerWidget()
  }
}
