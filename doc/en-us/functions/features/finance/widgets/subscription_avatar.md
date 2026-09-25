# lib/features/finance/widgets/subscription_avatar.dart

The leading avatar for a subscription, shared by the subscriptions page's tiles and the finance
home's subscription overview so a subscription looks the same wherever it is listed. Until v1.4.3
this was `_SubscriptionTile._buildLeading` inside `subscriptions_page.dart`; it moved here
unchanged when the home page gained a second list of subscriptions. See
[Finance](../../../../features/finance.md#views-and-analysis-page).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SubscriptionAvatar({...})` | constructor (`SubscriptionAvatar`) | B | Create a subscription avatar. |
| [`build`](#build) | method (`SubscriptionAvatar`) | A | Resolve the avatar through the image / emoji / account-image / category-emoji fallback chain. |
| `emojiAvatar` | local function (nested in `build`) | B | Build a circular emoji avatar. |
| `defaultIcon` | local function (nested in `build`) | B | Build the default repeat-icon avatar. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/widgets/subscription_avatar.dart`
reports 4, matching the 4 rows above exactly (1 Tier A, 3 Tier B).

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `SubscriptionAvatar`
- **Source:** `lib/features/finance/widgets/subscription_avatar.dart` (line 39)
- **Purpose:** Resolve the avatar through a four-tier fallback chain: the subscription's own image,
  then its own emoji, then the linked account's image, then the linked category's emoji, finally a
  generic repeat icon.
- **Inputs:** `context`; the widget's `subscription`, `account`, `category` fields.
- **Returns:** `Widget`.
- **Side effects:** The `FutureBuilder` branches resolve image files through
  `ImageService.resolve`, inside the returned widget's own build.
- **Algorithm:**
  1. Two nested local helpers: `emojiAvatar(String emoji)` (a tinted `CircleAvatar` with the emoji
     as text) and `defaultIcon()` (a tinted `CircleAvatar` with `Icons.repeat`); the tint is
     `theme.colorScheme.error` at 10% alpha.
  2. `subscription.imagePath != null` → `FutureBuilder<File>`; if the resolved file exists, show it
     as a [`StoredImageAvatar`](../../../shared/widgets/stored_image.md#storedimageavatar-build)
     (raster or SVG); otherwise fall through to the subscription's emoji or `defaultIcon()`.
  3. Else `subscription.emoji != null` → `emojiAvatar`.
  4. Else `account?.imagePath != null` → the same `FutureBuilder` pattern, falling back to the
     category's emoji or `defaultIcon()`.
  5. Else `category?.emoji != null` → `emojiAvatar`; otherwise `defaultIcon()`.
- **Usage:** `leading: SubscriptionAvatar(subscription: sub, account: account, category: cat)` in
  `_SubscriptionTile.build` and `_SubscriptionOverviewTile.build`.
- **Notes:** The order strictly prefers the subscription's own branding over the account's or the
  category's; an image that no longer exists on disk falls through rather than rendering blank.

## Related pages

- [`subscriptions_page.md`](../views/subscriptions_page.md) — `_SubscriptionTile`.
- [`finance_page.md`](../views/finance_page.md) — `_SubscriptionOverviewTile`.
- [`image_service.md`](../../../shared/services/image_service.md) — `resolve`.
- [`stored_image.md`](../../../shared/widgets/stored_image.md) — `StoredImageAvatar`.
