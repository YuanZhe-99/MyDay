import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  /// Purpose: Prevent direct instantiation of the theme namespace.
  /// Inputs: None.
  /// Returns: A new `AppTheme._` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  AppTheme._();

  /// Purpose: Return light.
  /// Inputs: None.
  /// Returns: `ThemeData`.
  /// Side effects: None.
  /// Notes: None.
  static ThemeData get light => FlexThemeData.light(
        scheme: FlexScheme.indigo,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          navigationBarLabelBehavior:
              NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
        useMaterial3: true,
      );

  /// Purpose: Return dark.
  /// Inputs: None.
  /// Returns: `ThemeData`.
  /// Side effects: None.
  /// Notes: None.
  static ThemeData get dark => FlexThemeData.dark(
        scheme: FlexScheme.indigo,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          navigationBarLabelBehavior:
              NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
        useMaterial3: true,
      );
}
