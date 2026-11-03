import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myapps_widget/myapps_widget.dart';

import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/intimacy/services/intimacy_storage.dart';
import '../../features/todo/services/todo_storage.dart';
import '../../features/weight/services/weight_storage.dart';
import '../../l10n/app_localizations.dart';
import 'auto_sync_service.dart';
import 'home_widget_actions.dart';
import 'home_widget_payloads.dart';

/// How one widget kind shows its values, chosen in the widget settings.
enum HomeWidgetPrivacyChoice {
  /// Values shown; iOS still redacts `sensitive` kinds while locked.
  show,

  /// Numbers and amounts drawn as `••`; titles kept.
  maskValues,

  /// A neutral placeholder with the app icon.
  iconOnly;

  /// Purpose: Read a stored choice.
  /// Inputs: `value` — the stored name, or anything else.
  /// Returns: The matching choice, or null when unknown.
  /// Side effects: None.
  /// Notes: Unknown values fall back to the kind's default at the call site.
  static HomeWidgetPrivacyChoice? fromName(Object? value) =>
      values.where((c) => c.name == value).firstOrNull;
}

/// The device-local settings of one widget kind.
@immutable
class HomeWidgetKindSettings {
  /// Purpose: Hold one kind's settings.
  /// Inputs: `textScale` (clamped by the caller), `privacy`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: Stored under `homeWidgets.<kind>` in `storage_config.json`.
  const HomeWidgetKindSettings({
    this.textScale = WidgetTextScale.defaultValue,
    required this.privacy,
  });

  /// Text size multiplier, 0.9–1.5.
  final double textScale;

  /// Privacy choice.
  final HomeWidgetPrivacyChoice privacy;

  /// Purpose: Return a copy with selected fields replaced.
  /// Inputs: optional `textScale`, `privacy`.
  /// Returns: `HomeWidgetKindSettings`.
  /// Side effects: None.
  /// Notes: The text scale is clamped.
  HomeWidgetKindSettings copyWith({
    double? textScale,
    HomeWidgetPrivacyChoice? privacy,
  }) => HomeWidgetKindSettings(
    textScale: WidgetTextScale.clamp(textScale ?? this.textScale),
    privacy: privacy ?? this.privacy,
  );

  /// Purpose: Serialize for `storage_config.json`.
  /// Inputs: None.
  /// Returns: A JSON-ready map.
  /// Side effects: None.
  /// Notes: None.
  Map<String, dynamic> toJson() => {
    'textScale': textScale,
    'privacy': privacy.name,
  };
}

/// A widget tap that opened the app on a specific action, waiting for the
/// destination page to consume it.
@immutable
class HomeWidgetLaunchRequest {
  /// Purpose: Hold one launch request.
  /// Inputs: `kind`; `action` — the link's `do` value (`add`, `toggle`,
  /// `timer`) or null; `id` — the task id for `toggle`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: See the deep-link table in the widget feature doc.
  const HomeWidgetLaunchRequest({required this.kind, this.action, this.id});

  /// The widget kind that was tapped.
  final String kind;

  /// What to open, or null for the tab itself.
  final String? action;

  /// The task id of a `toggle` request.
  final String? id;
}

/// Routes `myday://widget/<kind>?do=…` links into the app.
abstract final class HomeWidgetLaunch {
  /// The request waiting for its page; pages listen and call [take].
  static final pending = ValueNotifier<HomeWidgetLaunchRequest?>(null);

  /// Purpose: Tell whether a location is a home-screen widget link.
  /// Inputs: `uri`.
  /// Returns: `bool` — true for `/<kind>` with a MyDay widget kind.
  /// Side effects: None.
  /// Notes: Lets the router skip the async [redirect] for ordinary routes.
  static bool isWidgetLink(Uri uri) =>
      uri.pathSegments.length == 1 &&
      HomeWidgetService.tabFor(uri.pathSegments.single) != null;

  /// Purpose: Turn a widget deep link into a tab location.
  /// Inputs: `uri` — the location go_router is asked to open; `intimacyVisible`.
  /// Returns: The tab path to redirect to, or null when `uri` is no widget link.
  /// Side effects: Sets [pending] for links with a `do` action.
  /// Notes: Accepts both `/myday.todo?do=add` (Android route) and
  /// `myday://widget/myday.todo?do=add` (iOS URL). Intimacy kinds go to
  /// `/todo` while the module is hidden.
  static String? redirect(Uri uri, {required bool intimacyVisible}) {
    final segments = uri.pathSegments;
    if (segments.length != 1) return null;
    final kind = segments.single;
    final tab = HomeWidgetService.tabFor(kind);
    if (tab == null) return null;
    final intimacy =
        kind == HomeWidgetService.intimacyKind ||
        kind == HomeWidgetService.timerKind;
    if (intimacy && !intimacyVisible) return '/todo';
    final action = uri.queryParameters['do'];
    if (action != null) {
      pending.value = HomeWidgetLaunchRequest(
        kind: kind,
        action: action,
        id: uri.queryParameters['id'],
      );
    }
    return tab;
  }

  /// Purpose: Consume the pending request if it belongs to one of `kinds`.
  /// Inputs: `kinds`.
  /// Returns: The request, or null.
  /// Side effects: Clears [pending] when it matches.
  /// Notes: Pages call this once loaded and from a [pending] listener.
  static HomeWidgetLaunchRequest? take(Set<String> kinds) {
    final request = pending.value;
    if (request == null || !kinds.contains(request.kind)) return null;
    pending.value = null;
    return request;
  }
}

/// Feeds the Android and iOS home-screen widgets (Todo, Weight, Finance,
/// Private and Timer) and applies the taps their controls queue.
///
/// A facade over the shared MyApps-Widget bridge (`packages/myapps_widget`):
/// each kind is one envelope whose payload is built by [HomeWidgetPayloads].
/// See `doc/en-us/features/home-screen-widgets.md`.
class HomeWidgetService {
  /// Purpose: Prevent direct instantiation and expose only static members.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  HomeWidgetService._();

  static const todoKind = 'myday.todo';
  static const weightKind = 'myday.weight';
  static const financeKind = 'myday.finance';
  static const intimacyKind = 'myday.intimacy';
  static const timerKind = 'myday.timer';

  /// Every kind, in settings-page order.
  static const kinds = [
    todoKind,
    weightKind,
    financeKind,
    intimacyKind,
    timerKind,
  ];

  /// iOS App Group shared with the `MyDayWidgets` extension.
  static const appGroupId = 'group.com.yuanzhe.myDay';

  /// Payload format version (the envelope's `pv`) of every kind; bump only
  /// with a matching native change.
  static const formatVersion = 1;

  /// `storage_config.json` key of the widget settings.
  static const configKey = 'homeWidgets';

  static const _providerPackage = 'com.yuanzhe.my_day.widget';

  /// Android providers per kind.
  static const androidProviders = {
    todoKind: [
      '$_providerPackage.TodoWidgetProvider',
      '$_providerPackage.TodoStripWidgetProvider',
    ],
    weightKind: [
      '$_providerPackage.WeightWidgetProvider',
      '$_providerPackage.WeightStripWidgetProvider',
    ],
    financeKind: ['$_providerPackage.FinanceWidgetProvider'],
    intimacyKind: ['$_providerPackage.IntimacyWidgetProvider'],
    timerKind: [
      '$_providerPackage.TimerWidgetProvider',
      '$_providerPackage.TimerStripWidgetProvider',
    ],
  };

  /// WidgetKit kinds per envelope kind.
  static const iosKinds = {
    todoKind: ['MyDayTodoWidget'],
    weightKind: ['MyDayWeightWidget'],
    financeKind: ['MyDayFinanceWidget'],
    intimacyKind: ['MyDayIntimacyWidget'],
    timerKind: ['MyDayTimerWidget'],
  };

  /// The shared bridge with every MyDay kind.
  static final bridge = MyAppsWidgetBridge(
    appGroupId: appGroupId,
    kinds: [
      for (final kind in kinds)
        WidgetKindDescriptor(
          id: kind,
          androidProviders: androidProviders[kind]!,
          iosKinds: iosKinds[kind]!,
          payloadVersion: formatVersion,
          defaultPrivacy: kind == todoKind
              ? WidgetPrivacy.normal
              : WidgetPrivacy.sensitive,
        ),
    ],
  );

  static final _scheduler = WidgetRefreshScheduler(
    onRefresh: refresh,
    onError: (e, _) => debugPrint('HomeWidgetService: refresh failed: $e'),
  );

  /// Ids of actions applied this run, per kind, carried in the payload so
  /// renderers do not replay them while they are still queued.
  static final _applied = <String, List<String>>{todoKind: [], timerKind: []};

  /// Applies timer actions while the timer page is open, so the page's
  /// in-memory session is never overwritten; null otherwise.
  static Future<void> Function(List<WidgetAction> actions)? timerActionHandler;

  static Future<void>? _draining;
  static _LifecycleObserver? _observer;

  /// Purpose: Whether this platform has home-screen widgets.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Android and iOS only; every entry point no-ops elsewhere.
  static bool get isSupported => bridge.isSupported;

  /// Purpose: Return the tab path a kind opens.
  /// Inputs: `kind`.
  /// Returns: The path, or null for an unknown kind.
  /// Side effects: None.
  /// Notes: Used by [HomeWidgetLaunch.redirect].
  static String? tabFor(String kind) => switch (kind) {
    todoKind => '/todo',
    weightKind => '/weight',
    financeKind => '/finance',
    intimacyKind || timerKind => '/intimacy',
    _ => null,
  };

  /// Purpose: Return the default settings of a kind.
  /// Inputs: `kind`.
  /// Returns: `HomeWidgetKindSettings`.
  /// Side effects: None.
  /// Notes: Private defaults to hiding values; every other kind shows them.
  static HomeWidgetKindSettings defaultSettings(String kind) =>
      HomeWidgetKindSettings(
        privacy: kind == intimacyKind
            ? HomeWidgetPrivacyChoice.maskValues
            : HomeWidgetPrivacyChoice.show,
      );

  /// Purpose: Read every kind's settings.
  /// Inputs: None.
  /// Returns: Settings per kind, defaults filled in.
  /// Side effects: Reads `storage_config.json`.
  /// Notes: Malformed entries fall back to the defaults.
  static Future<Map<String, HomeWidgetKindSettings>> loadSettings() async {
    final raw = (await TodoStorage.readConfig())[configKey];
    return {for (final kind in kinds) kind: _parseSettings(kind, raw)};
  }

  /// Purpose: Parse one kind's stored settings.
  /// Inputs: `kind`; `raw` — the stored `homeWidgets` value.
  /// Returns: `HomeWidgetKindSettings`.
  /// Side effects: None.
  /// Notes: Tolerant of any JSON shape.
  static HomeWidgetKindSettings _parseSettings(String kind, Object? raw) {
    final fallback = defaultSettings(kind);
    final entry = raw is Map ? raw[kind] : null;
    if (entry is! Map) return fallback;
    final scale = entry['textScale'];
    return HomeWidgetKindSettings(
      textScale: scale is num
          ? WidgetTextScale.clamp(scale.toDouble())
          : fallback.textScale,
      privacy:
          HomeWidgetPrivacyChoice.fromName(entry['privacy']) ??
          fallback.privacy,
    );
  }

  /// Purpose: Store one kind's settings and refresh the widgets.
  /// Inputs: `kind`, `settings`.
  /// Returns: Completes when stored.
  /// Side effects: Merge-writes `homeWidgets` in `storage_config.json` and
  /// schedules a refresh.
  /// Notes: Device-local; never synced.
  static Future<void> saveSettings(
    String kind,
    HomeWidgetKindSettings settings,
  ) async {
    final raw = (await TodoStorage.readConfig())[configKey];
    final all = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    all[kind] = settings.toJson();
    await TodoStorage.writeConfig({configKey: all});
    notifyDataChanged();
  }

  /// Purpose: Start feeding the widgets.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Subscribes to sync reloads, app resume and queued widget
  /// actions, then drains the queue and refreshes every kind.
  /// Notes: Call once from `main()`; a no-op on unsupported platforms.
  static Future<void> init() async {
    if (!isSupported) return;
    AutoSyncService.instance.addOnLocalDataChanged(notifyDataChanged);
    bridge.setActionsQueuedListener(() => unawaited(drainActions()));
    _observer ??= _LifecycleObserver();
    WidgetsBinding.instance.addObserver(_observer!);
    await drainActions();
    unawaited(refresh());
  }

  /// Purpose: Schedule a debounced refresh after data or settings change.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Restarts the 2-second refresh timer.
  /// Notes: Called from every module save, sync/restore reloads, resume and
  /// the language, Intimacy-visibility and widget settings.
  static void notifyDataChanged() {
    if (!isSupported) return;
    _scheduler.schedule();
  }

  /// Purpose: Apply the actions queued by widget controls.
  /// Inputs: None.
  /// Returns: Completes when applied, published and acknowledged.
  /// Side effects: May write `todo_data.json` and `intimacy_data.json`,
  /// notifies auto-sync and open pages, publishes envelopes and removes the
  /// applied actions from the native queue.
  /// Notes: Concurrent calls share one pass. A failure leaves the actions
  /// queued for the next drain.
  static Future<void> drainActions() {
    if (!isSupported) return Future.value();
    return _draining ??= _drain().whenComplete(() => _draining = null);
  }

  /// Purpose: Run one drain pass.
  /// Inputs: None.
  /// Returns: Completes when done.
  /// Side effects: See [drainActions].
  /// Notes: Errors are logged and swallowed.
  static Future<void> _drain() async {
    try {
      final actions = await bridge.pendingActions();
      if (actions.isEmpty) return;
      final todo = actions.where((a) => a.kind == todoKind).toList();
      final timer = actions.where((a) => a.kind == timerKind).toList();
      final other = actions
          .where((a) => a.kind != todoKind && a.kind != timerKind)
          .map((a) => a.id);
      var wrote = false;
      if (todo.isNotEmpty) {
        final data = await TodoStorage.load();
        if (data != null) {
          final result = HomeWidgetActions.applyTodo(data, todo);
          if (result.changed) {
            await TodoStorage.save(result.data);
            wrote = true;
          }
        }
        _applied[todoKind]!.addAll(todo.map((a) => a.id));
      }
      if (timer.isNotEmpty) {
        final handler = timerActionHandler;
        if (handler != null) {
          await handler(timer);
        } else {
          final data = await IntimacyStorage.load();
          if (data != null) {
            final result = HomeWidgetActions.applyTimer(
              data.timerSession,
              timer,
            );
            if (result.changed) {
              await IntimacyStorage.save(
                data.withTimerSession(
                  result.data,
                  modifiedAt: DateTime.now().toUtc(),
                ),
              );
              wrote = true;
            }
          }
        }
        _applied[timerKind]!.addAll(timer.map((a) => a.id));
      }
      if (wrote) {
        AutoSyncService.instance.notifySaved();
        AutoSyncService.instance.notifyLocalDataChangedNow();
      }
      await refresh();
      await bridge.acknowledgeActions([
        ...todo.map((a) => a.id),
        ...timer.map((a) => a.id),
        ...other,
      ]);
    } catch (e) {
      debugPrint('HomeWidgetService: applying widget actions failed: $e');
    }
  }

  /// Purpose: Rebuild every kind's envelope and redraw the widgets.
  /// Inputs: None.
  /// Returns: Completes when published.
  /// Side effects: Reads the data files and `storage_config.json`, writes the
  /// native widget store, and clears the Private and Timer envelopes while the
  /// Intimacy module is hidden.
  /// Notes: Each kind fails independently; failures are logged, since a
  /// stale widget is harmless.
  static Future<void> refresh() async {
    if (!isSupported) return;
    final settings = await loadSettings();
    final now = DateTime.now();
    final builders = await payloadBuilders(now);
    for (final kind in kinds) {
      try {
        final s = settings[kind]!;
        final payload = await builders[kind]!(
          s.privacy == HomeWidgetPrivacyChoice.maskValues,
        );
        if (payload == null) {
          await bridge.clear(kind);
          continue;
        }
        await bridge.publish(
          bridge.envelope(
            kind,
            payload,
            generatedAt: now,
            textScale: s.textScale,
            privacy: envelopePrivacy(kind, s.privacy),
          ),
        );
      } catch (e) {
        debugPrint('HomeWidgetService: refreshing $kind failed: $e');
      }
    }
    for (final ids in _applied.values) {
      if (ids.length > HomeWidgetPayloads.maxAppliedActions) {
        ids.removeRange(0, ids.length - HomeWidgetPayloads.maxAppliedActions);
      }
    }
  }

  /// Purpose: Prepare one payload builder per kind.
  /// Inputs: `now` — the instant the payloads describe.
  /// Returns: Builders keyed by kind; each takes the `mask` flag and returns
  /// the payload, or null for the Private and Timer kinds while the Intimacy
  /// module is hidden.
  /// Side effects: Reads `storage_config.json` and initializes intl date
  /// symbols for the app language; each builder reads its data file.
  /// Notes: Shared by [refresh] and the settings-page previews.
  static Future<Map<String, Future<Map<String, dynamic>?> Function(bool mask)>>
  payloadBuilders(DateTime now) async {
    final (l10n, localeTag) = await _l10n();
    try {
      await initializeDateFormatting(localeTag);
    } catch (_) {}
    final intimacyVisible = await TodoStorage.getIntimacyVisible();
    return <String, Future<Map<String, dynamic>?> Function(bool)>{
      todoKind: (mask) async => HomeWidgetPayloads.todo(
        await TodoStorage.load(),
        now: now,
        l10n: l10n,
        localeTag: localeTag,
        appliedActions: _applied[todoKind]!,
        mask: mask,
      ),
      weightKind: (mask) async => HomeWidgetPayloads.weight(
        await WeightStorage.load(),
        now: now,
        l10n: l10n,
        mask: mask,
      ),
      financeKind: (mask) async => HomeWidgetPayloads.finance(
        await FinanceStorage.load(),
        rates: await ExchangeRateStorage.load(),
        now: now,
        l10n: l10n,
        localeTag: localeTag,
        mask: mask,
      ),
      intimacyKind: (mask) async => intimacyVisible
          ? HomeWidgetPayloads.intimacy(
              await IntimacyStorage.load(),
              now: now,
              l10n: l10n,
              mask: mask,
            )
          : null,
      timerKind: (mask) async => intimacyVisible
          ? HomeWidgetPayloads.timer(
              await IntimacyStorage.load(),
              l10n: l10n,
              appliedActions: _applied[timerKind]!,
              mask: mask,
            )
          : null,
    };
  }

  /// Purpose: Map a privacy choice to the envelope's privacy level.
  /// Inputs: `kind`, `choice`.
  /// Returns: `WidgetPrivacy`.
  /// Side effects: None.
  /// Notes: *Show* keeps the kind's default level.
  static WidgetPrivacy envelopePrivacy(
    String kind,
    HomeWidgetPrivacyChoice choice,
  ) => switch (choice) {
    HomeWidgetPrivacyChoice.show => bridge.kinds[kind]!.defaultPrivacy,
    HomeWidgetPrivacyChoice.maskValues => WidgetPrivacy.sensitive,
    HomeWidgetPrivacyChoice.iconOnly => WidgetPrivacy.hidden,
  };

  /// Purpose: Resolve localizations and the intl locale tag.
  /// Inputs: None.
  /// Returns: The localizations and a tag such as `zh_TW`.
  /// Side effects: Reads `storage_config.json`.
  /// Notes: Same resolution as the settings provider; falls back to English.
  static Future<(AppLocalizations, String)> _l10n() async {
    final tag = await TodoStorage.getLocaleTag();
    var locale = PlatformDispatcher.instance.locale;
    if (tag != null) {
      final parts = tag.split('_');
      locale = parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
    }
    try {
      final l10n = lookupAppLocalizations(locale);
      final country =
          locale.languageCode == 'zh' &&
              (locale.countryCode == 'TW' || locale.scriptCode == 'Hant')
          ? '_TW'
          : '';
      return (l10n, '${locale.languageCode}$country');
    } catch (_) {
      return (lookupAppLocalizations(const Locale('en')), 'en');
    }
  }
}

/// Refreshes the widgets and drains queued actions when the app resumes.
class _LifecycleObserver with WidgetsBindingObserver {
  /// Purpose: React to app lifecycle changes.
  /// Inputs: `state`.
  /// Returns: None.
  /// Side effects: On resume, drains widget actions and schedules a refresh.
  /// Notes: Covers taps made while the app was suspended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(HomeWidgetService.drainActions());
    HomeWidgetService.notifyDataChanged();
  }
}
