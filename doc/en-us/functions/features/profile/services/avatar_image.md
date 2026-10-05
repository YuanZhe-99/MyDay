# lib/features/profile/services/avatar_image.dart

P3: shared declarations described below live in `myapps_profile`; this app
file is a re-export or adapter preserving its public import and constructor shape.
See [../../../../shared-ui.md](../../../../shared-ui.md).

The pure image operations behind the avatar editor (1.6.1). Every function is synchronous and
allocation-only, so callers run it in another isolate (`Isolate.run`) to keep the UI responsive.
The editor ([`../views/avatar_editor.md`](../views/avatar_editor.md)) calls `prepareAvatarSource`
and `cropAvatarJpeg`; [`profile_store.md`](profile_store.md) stores the resulting JPEG. See
[`../../../../features/profile.md`](../../../../features/profile.md#avatar-processing).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AvatarSource` | class and constructor | B | An upright, size-limited PNG copy of a picked image (`bytes`, `width`, `height`), ready for the editor. |
| `avatarSourceMaxEdge` | top-level `const int` | B | Longest edge, in pixels, the editor works with (2048). |
| `_decode` | top-level function (private) | B | Decode any image without letting a decoder exception escape. |
| [`prepareAvatarSource`](#prepareavatarsource) | top-level function | A | Normalise a picked image for the editor. |
| [`cropAvatarJpeg`](#cropavatarjpeg) | top-level function | A | Cut the square the user framed and encode it as the avatar. |
| [`squareAvatarJpeg`](#squareavatarjpeg) | top-level function | A | Turn any decodable image into a centred square JPEG (moved here from `profile_store.dart`). |
| [`prepareAvatarSourceInBackground`](#background-variants) | top-level function | A | Run `prepareAvatarSource` in another isolate (1.6.1). |
| [`cropAvatarJpegInBackground`](#background-variants) | top-level function | A | Run `cropAvatarJpeg` in another isolate (1.6.1). |

`grep -c 'Purpose:'` reports 7; `avatarSourceMaxEdge` and the `AvatarSource` fields carry plain `///` comments.

## _decode

- **Notes:** Truncated or foreign data can make a format probe throw (for example a `RangeError`)
  instead of returning null; both outcomes become `FormatException('Not a supported image')`.

## prepareAvatarSource

- **Inputs:** `bytes` — the picked file; `quarterTurns` — extra clockwise 90 degree turns (the editor's rotate button).
- **Returns:** `AvatarSource` — upright (EXIF applied), longest edge at most `avatarSourceMaxEdge`, encoded as PNG.
- **Algorithm:** `bakeOrientation`, then `copyRotate(angle: 90 * (quarterTurns % 4))`, then `copyResize` to 2048 on the longer edge when larger, then `encodePng`.
- **Notes:** Baking the orientation here means the pixels the editor shows and the pixels `cropAvatarJpeg` cuts are the same, whatever the platform's own EXIF handling. Throws `FormatException` for non-images.

## cropAvatarJpeg

- **Inputs:** `source` — bytes from `prepareAvatarSource`; `x`, `y`, `side` — the square in source pixels; `size` — output edge.
- **Returns:** `Uint8List` — a `size` x `size` JPEG (quality 88).
- **Notes:** The square is clamped into the image (`side` to the shorter edge, `x`/`y` so it stays inside), so rounding at the edges never fails. Throws `FormatException` for non-images.

## squareAvatarJpeg

- **Inputs:** `bytes`, `size`.
- **Returns:** `Uint8List` — JPEG bytes.
- **Notes:** The non-interactive path (no editor): applies EXIF orientation and takes the centred square with `copyResizeCropSquare`. Throws `FormatException` for non-images. Kept for callers and tests that want the centred crop.

## Background variants

`prepareAvatarSourceInBackground(bytes, {quarterTurns})` and `cropAvatarJpegInBackground(source, {x, y, side, size})` wrap the two functions in `Isolate.run` and return a `Future`. They are **top-level on purpose**: an `Isolate.run(() => ...)` closure written inside a widget's `State` method also captures the `State` and its controllers, which cannot be sent to another isolate, so the editor failed with *This image could not be used*. Here the closure captures only its arguments. The editor calls only these two; `test/profile_test.dart` runs both for real.
