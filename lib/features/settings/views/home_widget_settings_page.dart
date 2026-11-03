import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapps_ui/myapps_ui.dart'
    show MyAppsSettingsSection, MyAppsSettingsSegmentRow;
import 'package:myapps_widget_ui/myapps_widget_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/intimacy_visibility.dart';
import '../../../shared/services/home_widget_service.dart';
import '../widgets/home_widget_preview.dart';

/// Settings › Home-screen widgets (1.8.3): one section per widget kind, each
/// with its text size, its privacy choice and a live preview.
class HomeWidgetSettingsPage extends ConsumerStatefulWidget {
  /// Purpose: Create the widget settings page.
  /// Inputs: None.
  /// Returns: A new `HomeWidgetSettingsPage`.
  /// Side effects: None.
  /// Notes: Pushed full screen on a narrow window and hosted in the Settings
  /// detail pane on a wide one. Android and iOS only.
  const HomeWidgetSettingsPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<HomeWidgetSettingsPage> createState() =>
      _HomeWidgetSettingsPageState();
}

class _HomeWidgetSettingsPageState
    extends ConsumerState<HomeWidgetSettingsPage> {
  Map<String, HomeWidgetKindSettings>? _settings;
  final _payloads = <String, Map<String, dynamic>?>{};

  /// Purpose: Load the settings and the preview payloads.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts reading `storage_config.json` and the data files.
  /// Notes: Flutter lifecycle override.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Purpose: Read the settings and build one unmasked payload per kind.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Reads storage; updates state.
  /// Notes: A kind whose data cannot be read previews as the placeholder.
  Future<void> _load() async {
    final settings = await HomeWidgetService.loadSettings();
    final builders = await HomeWidgetService.payloadBuilders(DateTime.now());
    final payloads = <String, Map<String, dynamic>?>{};
    for (final kind in HomeWidgetService.kinds) {
      try {
        payloads[kind] = await builders[kind]!(false);
      } catch (_) {
        payloads[kind] = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _payloads
        ..clear()
        ..addAll(payloads);
    });
  }

  /// Purpose: Change one kind's settings.
  /// Inputs: `kind`, `next`.
  /// Returns: None.
  /// Side effects: Updates state, persists and refreshes the widgets.
  /// Notes: None.
  void _update(String kind, HomeWidgetKindSettings next) {
    setState(() => _settings![kind] = next);
    HomeWidgetService.saveSettings(kind, next);
  }

  /// Purpose: Build the page.
  /// Inputs: `context`.
  /// Returns: A `Scaffold` with one section per visible kind.
  /// Side effects: None.
  /// Notes: The Private and Timer sections appear only while the Intimacy
  /// module is visible.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intimacyVisible = ref.watch(intimacyVisibilityProvider).visible;
    final settings = _settings;
    final titles = {
      HomeWidgetService.todoKind: l10n.homeWidgetKindTodo,
      HomeWidgetService.weightKind: l10n.homeWidgetKindWeight,
      HomeWidgetService.financeKind: l10n.homeWidgetKindFinance,
      HomeWidgetService.intimacyKind: l10n.homeWidgetKindPrivate,
      HomeWidgetService.timerKind: l10n.homeWidgetKindTimer,
    };

    Widget section(String kind) {
      final s = settings![kind]!;
      return MyAppsSettingsSection(
        title: titles[kind]!,
        children: [
          WidgetTextScaleControl(
            value: s.textScale,
            title: l10n.homeWidgetTextSize,
            onChanged: (v) => _update(kind, s.copyWith(textScale: v)),
          ),
          MyAppsSettingsSegmentRow<HomeWidgetPrivacyChoice>(
            leading: const Icon(Icons.visibility_outlined),
            title: l10n.homeWidgetPrivacy,
            description: kind == HomeWidgetService.todoKind
                ? null
                : l10n.homeWidgetPrivacyNote,
            segments: [
              ButtonSegment(
                value: HomeWidgetPrivacyChoice.show,
                label: Text(l10n.homeWidgetPrivacyShow),
              ),
              ButtonSegment(
                value: HomeWidgetPrivacyChoice.maskValues,
                label: Text(l10n.homeWidgetPrivacyMask),
              ),
              ButtonSegment(
                value: HomeWidgetPrivacyChoice.iconOnly,
                label: Text(l10n.homeWidgetPrivacyIcon),
              ),
            ],
            selected: {s.privacy},
            onSelectionChanged: (v) =>
                _update(kind, s.copyWith(privacy: v.first)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: HomeWidgetPreview(
              kind: kind,
              payload: _payloads[kind],
              settings: s,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeWidgetsTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    l10n.homeWidgetsHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final kind in HomeWidgetService.kinds)
                  if (intimacyVisible ||
                      (kind != HomeWidgetService.intimacyKind &&
                          kind != HomeWidgetService.timerKind))
                    section(kind),
              ],
            ),
    );
  }
}
