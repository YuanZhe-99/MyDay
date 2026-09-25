# lib/shared/widgets/stored_image.dart

Renders an image file from app storage (`images/`) with the right decoder: `SvgPicture.file` for a
`.svg` file, `Image.file` for everything else. `StoredImage` is the rectangular view;
`StoredImageAvatar` is the circular avatar that replaces the former
`CircleAvatar(backgroundImage: FileImage(...))` pattern, which cannot show SVGs because an SVG cannot
supply an `ImageProvider`. Added in v1.4.5 because bundled bank logos copied into `images/` may be
SVGs (see [`ImageService.copyAssetImage`](../services/image_service.md#copyassetimage)). Every
Finance display site of a stored account or subscription image uses these widgets; the Intimacy
module still uses `FileImage`/`Image.file` directly, since its images only come from the file
picker.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `isSvgFile` | top-level function | B | Whether a stored image file is an SVG (`.svg` extension, case-insensitive). |
| `StoredImage(...)` | const constructor (`StoredImage`) | B | Create a stored-image view (`file`, `width`, `height`, `fit` default `cover`). |
| [`StoredImage.build`](#storedimage-build) | method (`StoredImage`) | A | Build the SVG or raster image for `file`. |
| `StoredImageAvatar(...)` | const constructor (`StoredImageAvatar`) | B | Create a circular avatar (`file`, `radius` default 20, `backgroundColor`). |
| [`StoredImageAvatar.build`](#storedimageavatar-build) | method (`StoredImageAvatar`) | A | Build the clipped circular avatar. |

**Reconciliation:** `grep -c '/// Purpose:' lib/shared/widgets/stored_image.dart` returns 5,
matching the 5 rows above exactly (2 Tier A, 3 Tier B).

## Documentation

### `Widget build(BuildContext context)` (`StoredImage`) <a id="storedimage-build"></a>
- **Kind:** method of `StoredImage`
- **Source:** `lib/shared/widgets/stored_image.dart` (line 41)
- **Purpose:** Pick the decoder for a stored image file by its extension.
- **Inputs:** `context`; the widget's `file`, `width`, `height`, `fit`.
- **Returns:** `SvgPicture.file` for a `.svg` file, otherwise `Image.file`, both sized and fitted as
  given.
- **Side effects:** Reads the file when painted.
- **Algorithm:**
  1. `isSvgFile(file)` → `SvgPicture.file` whose `placeholderBuilder` and `errorBuilder` both return
     an empty box of the requested size, so an unparsable SVG renders as blank space instead of
     throwing.
  2. Otherwise `Image.file(file, width:, height:, fit:)`.
- **Usage:**
  ```dart
  child: StoredImage(
    snap.data!,
    width: 48,
    height: 48,
    fit: BoxFit.cover,
  ),
  ```
  (`lib/features/finance/views/accounts_page.dart:1939`, the account dialog's image preview; also
  `lib/features/finance/widgets/add_subscription_dialog.dart:610`.)
- **Notes:** The extension is authoritative because `ImageService` always sets it — from the
  content type on download, from the asset key on `copyAssetImage`, from the picked file on
  `pickAndSaveImage`. Callers keep their own `existsSync()` guard; this widget only picks a decoder.

### `Widget build(BuildContext context)` (`StoredImageAvatar`) <a id="storedimageavatar-build"></a>
- **Kind:** method of `StoredImageAvatar`
- **Source:** `lib/shared/widgets/stored_image.dart` (line 83)
- **Purpose:** Render a stored image as a circular avatar that works for both raster and SVG files.
- **Inputs:** `context`; the widget's `file`, `radius`, `backgroundColor`.
- **Returns:** A `CircleAvatar` with the image as a `ClipOval`-clipped child.
- **Side effects:** None beyond `StoredImage`.
- **Algorithm:**
  1. SVG → `CircleAvatar(backgroundColor: Colors.white)` holding a `ClipOval` with padding of
     `radius * 0.18` around a `StoredImage` of `2 * radius` square and `BoxFit.contain`.
  2. Raster → `CircleAvatar(backgroundColor: backgroundColor)` holding a `ClipOval` around a
     `StoredImage` of `2 * radius` square and `BoxFit.cover` — the same fill as the old
     `backgroundImage: FileImage(...)`.
- **Usage:**
  ```dart
  return StoredImageAvatar(
    snap.data!,
    backgroundColor: color.withValues(alpha: 0.15),
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:893`, `_buildAccountAvatar`. The other call sites:
  `subscription_avatar.dart:69` and `:86`, `add_transaction_dialog.dart:437` with `radius: 12`,
  `subscription_detail_page.dart:396`, `finance_page.dart:1628`, `category_detail_page.dart:425`.)
- **Notes:** SVG logos are wordmarks as often as symbols and are drawn for light backgrounds, so
  they always get a white disc and `contain` with an inset — whole and legible in dark mode —
  and ignore `backgroundColor`. The image is a child rather than `backgroundImage` because
  `CircleAvatar.backgroundImage` needs an `ImageProvider`, which an SVG cannot supply.
