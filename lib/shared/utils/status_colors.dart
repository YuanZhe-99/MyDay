import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Colors for the money flows that carry a meaning of their own
/// (income = positive, expense = negative) in lists, charts and summary
/// cards. Green and red are kept for recognisability but derived from the
/// active [ColorScheme], following Material 3's custom-color guidance, so they
/// sit in the same tonal family as the rest of the UI in light, dark and
/// dynamic color.
abstract final class StatusColors {
  /// Purpose: Return the color for income and positive balances.
  /// Inputs: `scheme` — the color scheme the color will be drawn on.
  /// Returns: `Color` — green harmonized toward `scheme.primary`.
  /// Side effects: None.
  /// Notes: Harmonization only shifts the hue slightly, so it still reads as
  /// green next to the dropped red.
  static Color income(ColorScheme scheme) =>
      Colors.green.harmonizeWith(scheme.primary);

  /// Purpose: Return the color for expenses and negative amounts.
  /// Inputs: `scheme`.
  /// Returns: `Color` — `scheme.error`.
  /// Side effects: None.
  /// Notes: The scheme's error role is already a tuned red for its
  /// brightness.
  static Color expense(ColorScheme scheme) => scheme.error;
}
