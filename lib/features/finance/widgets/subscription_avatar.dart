import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/services/image_service.dart';
import '../models/finance.dart';

/// The leading avatar for a subscription, shared by the subscriptions page's
/// tiles and the finance home's subscription overview so a subscription looks
/// the same wherever it is listed.
class SubscriptionAvatar extends StatelessWidget {
  final Subscription subscription;
  final Account? account;
  final Category? category;

  /// Purpose: Create a subscription avatar.
  /// Inputs: `subscription`; `account` and `category` — the resolved account
  /// and category, if any, used as fallbacks.
  /// Returns: A new `SubscriptionAvatar` instance.
  /// Side effects: None.
  /// Notes: None.
  const SubscriptionAvatar({
    super.key,
    required this.subscription,
    this.account,
    this.category,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Resolves image files asynchronously when a path is set.
  /// Notes: Four-step fallback: the subscription's own image, then its own
  /// emoji, then the account's image, then the category's emoji, then a plain
  /// repeat icon. An image that no longer exists on disk falls through to the
  /// next step rather than rendering blank.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    final sub = subscription;

    /// Purpose: Build a subscription emoji avatar.
    /// Inputs: `emoji`.
    /// Returns: `Widget`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    Widget emojiAvatar(String emoji) => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );

    /// Purpose: Build the default subscription icon avatar.
    /// Inputs: None.
    /// Returns: `Widget`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    Widget defaultIcon() => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(Icons.repeat, color: color, size: 20),
    );

    if (sub.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(sub.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              backgroundColor: color.withValues(alpha: 0.1),
            );
          }
          return sub.emoji != null ? emojiAvatar(sub.emoji!) : defaultIcon();
        },
      );
    }

    if (sub.emoji != null) return emojiAvatar(sub.emoji!);

    if (account?.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(account!.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              backgroundColor: color.withValues(alpha: 0.1),
            );
          }
          return category?.emoji != null
              ? emojiAvatar(category!.emoji!)
              : defaultIcon();
        },
      );
    }

    if (category?.emoji != null) return emojiAvatar(category!.emoji!);
    return defaultIcon();
  }
}
