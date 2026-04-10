import 'dart:io';
import 'dart:ui';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/todo/services/todo_storage.dart';
import '../../l10n/app_localizations.dart';

/// Manages system tray icon and window hide/show behaviour on desktop.
class TrayService with TrayListener, WindowListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  bool _minimizeToTray = false;
  bool _closeToTray = false;
  bool _initialized = false;
  Locale _locale = const Locale('en');

  bool get minimizeToTray => _minimizeToTray;
  bool get closeToTray => _closeToTray;

  /// Initialise tray icon and window-manager hooks (desktop only).
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

  Future<void> _setupTray() async {
    final iconPath =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('MyDay!!!!!');
    await _rebuildMenu();
  }

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

  Future<void> setMinimizeToTray(bool value) async {
    _minimizeToTray = value;
    await TodoStorage.setMinimizeToTray(value);
  }

  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    await TodoStorage.setCloseToTray(value);
    await windowManager.setPreventClose(value);
  }

  /// Update locale and rebuild tray menu labels.
  Future<void> updateLocale(Locale locale) async {
    _locale = locale;
    if (_initialized) await _rebuildMenu();
  }

  // ─── TrayListener ─────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        windowManager.focus();
        break;
      case 'quit':
        // Actually close the app
        windowManager.setPreventClose(false);
        windowManager.close();
        break;
    }
  }

  // ─── WindowListener ───────────────────────────────────────────

  @override
  void onWindowClose() {
    if (_closeToTray) {
      windowManager.hide();
    } else {
      windowManager.destroy();
    }
  }

  @override
  void onWindowMinimize() {
    if (_minimizeToTray) {
      windowManager.hide();
    }
  }
}
