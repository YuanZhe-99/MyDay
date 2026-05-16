import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/todo/services/todo_storage.dart';
import '../../l10n/app_localizations.dart';

/// Manages system tray icon and window hide/show behaviour on desktop.
class TrayService with TrayListener, WindowListener {
  /// Purpose: Prevent direct instantiation of the tray singleton.
  /// Inputs: None.
  /// Returns: A new `TrayService` instance.
  /// Side effects: None.
  /// Notes: Use `TrayService.instance` instead.
  TrayService._();
  static final TrayService instance = TrayService._();

  static const _dockChannel = MethodChannel('com.yuanzhe.my_day/dock');

  bool _minimizeToTray = false;
  bool _closeToTray = false;
  bool _initialized = false;
  Locale _locale = const Locale('en');

  /// Purpose: Return minimize to tray.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get minimizeToTray => _minimizeToTray;
  /// Purpose: Return close to tray.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get closeToTray => _closeToTray;

  /// Initialise tray icon and window-manager hooks (desktop only).
  /// Purpose: Implement the init behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    _minimizeToTray = await TodoStorage.getMinimizeToTray();
    _closeToTray = await TodoStorage.getCloseToTray();

    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(_closeToTray);

    await _setupTray();
    trayManager.addListener(this);

    _initialized = true;
  }

  /// Purpose: Provide the internal setup tray helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _setupTray() async {
    final iconPath =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/icon/app_icon.png';
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('MyDay!!!!!');
    await _rebuildMenu();
  }

  /// Purpose: Provide the internal rebuild menu helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _rebuildMenu() async {
    final l10n = lookupAppLocalizations(_locale);
    final menu = Menu(items: [
      MenuItem(key: 'show', label: l10n.trayShow),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: l10n.trayQuit),
    ]);
    await trayManager.setContextMenu(menu);
  }

  // ─── public setters (persisted) ────────────────────────────────

  /// Purpose: Implement the set minimize to tray behavior for this file.
  /// Inputs: `value`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> setMinimizeToTray(bool value) async {
    _minimizeToTray = value;
    await TodoStorage.setMinimizeToTray(value);
  }

  /// Purpose: Implement the set close to tray behavior for this file.
  /// Inputs: `value`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    await TodoStorage.setCloseToTray(value);
    await windowManager.setPreventClose(value);
  }

  /// Update locale and rebuild tray menu labels.
  /// Purpose: Update locale through the current flow.
  /// Inputs: `locale`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> updateLocale(Locale locale) async {
    _locale = locale;
    if (_initialized) await _rebuildMenu();
  }

  // ─── TrayListener ─────────────────────────────────────────────

  /// Purpose: Implement the on tray icon mouse down behavior for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  @override
  void onTrayIconMouseDown() {
    _showWindow();
  }

  /// Purpose: Implement the on tray icon right mouse down behavior for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  /// Purpose: Implement the on tray menu item click behavior for this file.
  /// Inputs: `menuItem`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'quit':
        // Actually close the app
        windowManager.setPreventClose(false);
        windowManager.close();
        break;
    }
  }

  // ─── WindowListener ───────────────────────────────────────────

  /// Purpose: Implement the on window close behavior for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  @override
  void onWindowClose() {
    if (_closeToTray) {
      windowManager.hide();
      _setDockIconVisible(false);
    } else {
      windowManager.destroy();
    }
  }

  /// Purpose: Implement the on window minimize behavior for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  @override
  void onWindowMinimize() {
    if (_minimizeToTray) {
      windowManager.hide();
      _setDockIconVisible(false);
    }
  }

  // ─── macOS Dock ──

  /// Purpose: Provide the internal show window helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  void _showWindow() {
    _setDockIconVisible(true);
    windowManager.show();
    windowManager.focus();
  }

  /// Purpose: Provide the internal set dock icon visible helper for this file.
  /// Inputs: `visible`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static void _setDockIconVisible(bool visible) {
    if (!Platform.isMacOS) return;
    _dockChannel.invokeMethod('setDockIconVisible', {'visible': visible});
  }
}
