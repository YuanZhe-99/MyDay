# lib/features/profile/views/avatar_editor.dart

The full-screen avatar editor (1.6.1): the picked image (or the current avatar) is framed inside a
circle — drag to move, pinch or scroll to zoom, rotate in quarter turns, reset, save. The framed
square is what is stored, so the avatar always matches what was shown. Opened by
[`profile_header.md`](profile_header.md); image work is in
[`../services/avatar_image.md`](../services/avatar_image.md). See
[`../../../../features/profile.md`](../../../../features/profile.md#editing).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`showAvatarEditor`](#showavatareditor) | top-level function | A | Let the user frame an avatar and return the result. |
| `AvatarEditorPage` | widget (public) and constructor | B | The editor page. |
| `AvatarEditorPage.createState` | method (widget lifecycle) | B | Create the editor state. |
| `_AvatarEditorPageState.initState` | method (widget lifecycle) | B | Start preparing the image. |
| `_AvatarEditorPageState.dispose` | method (widget lifecycle) | B | Release the transformation controller. |
| [`_prepare`](#_prepare) | method (`_AvatarEditorPageState`) | A | Decode, orient and size the source for the current rotation. |
| `_rotate` | method (`_AvatarEditorPageState`) | B | Rotate a quarter turn clockwise. |
| `_reset` | method (`_AvatarEditorPageState`) | B | Return to the initial framing. |
| [`_save`](#_save) | method (`_AvatarEditorPageState`) | A | Crop what the circle shows and return it. |
| [`build`](#build) | method (`_AvatarEditorPageState`) | A | Build the editor. |
| `_CircleMaskPainter` | class, constructor, `paint`, `shouldRepaint` | B | Paint the scrim with a circular hole and the outline. |

## showAvatarEditor

- **Inputs:** `context`; `source` — the picked image or the current avatar's bytes.
- **Returns:** `Future<Uint8List?>` — a 512-pixel square JPEG, or null when the user backed out.
- **Side effects:** Pushes a full-screen dialog route.

## _prepare

- **Side effects:** Runs `prepareAvatarSourceInBackground(bytes, quarterTurns: _turns)`, resets the framing and updates the busy and failure flags. An undecodable image shows an error state instead of throwing.

## _save

- **Algorithm:** Reads the `InteractiveViewer`'s transformation matrix. The view's top-left and edge are mapped back through the matrix (`translation / scale`) and the base-size-to-pixel ratio into source-image pixels, then `cropAvatarJpegInBackground(... size: 512)` runs and the route pops with the JPEG.

## build

- **Returns:** A `Scaffold` with the title *Adjust avatar*, rotate and reset buttons in the app bar and a *Save* action; the body is a square viewport holding an `InteractiveViewer` (`minScale: 1`, `maxScale: 8`, `boundaryMargin: EdgeInsets.zero`, so the image always covers the circle) with the circular mask drawn over it, and the hint *Drag to move. Pinch or scroll to zoom.*
- **Notes:** The image is laid out to cover the square viewport at zoom 1. The viewport edge and base size are recorded for `_save`. A freshly prepared image is centred, and the transformation **must be reset in a `postFrameCallback`** — a controller cannot be changed during `build`.
