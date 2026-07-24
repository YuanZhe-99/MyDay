# lib/shared/services/image_service.dart

Static-only service for local image storage: picking a file from the OS picker, downloading a
remote image (e.g. a bank logo), resolving a stored relative path back to an absolute `File`, and
deleting a stored image. All images live under `<appDir>/images/` with UUID-based file names. Used
by Finance (account/subscription images), Intimacy (partner/toy photos), and referenced by the
sync image-transfer logic described in
[../../../sync.md#per-file-error-handling-not-whole-sync-abort](../../../sync.md#per-file-error-handling-not-whole-sync-abort).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_getImageDir`](#_getimagedir) | static method (`ImageService`) | A | Return (creating if needed) the app's `images/` directory. |
| [`pickAndSaveImage`](#pickandsaveimage) | static method (`ImageService`) | A | Let the user pick an image file and copy it into app storage. |
| [`resolve`](#resolve) | static method (`ImageService`) | A | Resolve a relative `images/...` path to an absolute `File`. |
| [`delete`](#delete) | static method (`ImageService`) | A | Delete a previously saved image if it exists. |
| [`downloadAndSave`](#downloadandsave) | static method (`ImageService`) | A | Download an image from a URL and save it into app storage. |

`grep -c 'Purpose:' lib/shared/services/image_service.dart` reports 5, matching all five real
declarations in this file (the `ImageService` class has no other methods, no written constructor,
and no undocumented declarations were found).

## Documentation

### `static Future<Directory> _getImageDir()` <a id="_getimagedir"></a>
- **Kind:** private static method of `ImageService`
- **Source:** `lib/shared/services/image_service.dart` (line 16)
- **Purpose:** Return the app's `images/` directory, creating it on first use.
- **Inputs:** None.
- **Returns:** `Future<Directory>` for `<appDir>/images`.
- **Side effects:** Creates the directory (`recursive: true`) if it does not already exist.
- **Algorithm:** Read `TodoStorage.getAppDir()`, join with `'images'`, create recursively if
  missing, return the `Directory`.
- **Usage:** Internal helper called by `pickAndSaveImage` and `downloadAndSave`.
- **Notes:** Relies on `TodoStorage.getAppDir()` so a custom storage path (set from Settings) is
  respected automatically.

### `static Future<String?> pickAndSaveImage()` <a id="pickandsaveimage"></a>
- **Kind:** static method of `ImageService`
- **Source:** `lib/shared/services/image_service.dart` (line 33)
- **Purpose:** Open the OS file picker restricted to images, copy the chosen file into app
  storage under a new UUID name, and return its app-relative path.
- **Inputs:** None (interactive; reads from `FilePicker.platform`).
- **Returns:** `Future<String?>` — `"images/<uuid><ext>"` relative to `appDir`, or `null` if the
  user cancelled or the picker returned no usable path.
- **Side effects:** Copies the picked file into `<appDir>/images/`.
- **Algorithm:**
  1. Call `FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false)`.
  2. Return `null` if the result or its file list is empty, or if the picked path is `null`.
  3. Ensure the image directory exists (`_getImageDir`).
  4. Build a new name `'${Uuid().v4()}$ext'` reusing the original file's extension.
  5. Copy the source file to the new destination path.
  6. Return `'images/$newName'`.
- **Usage:**
  ```dart
  final path = await ImageService.pickAndSaveImage();
  ```
  (`lib/features/finance/views/accounts_page.dart`, account image picker; also used in
  `intimacy_page.dart` and `add_subscription_dialog.dart`.)
- **Notes:** The returned path is always relative to `appDir` (e.g. `images/xxxx.png`), never
  absolute — callers must go through `ImageService.resolve()` to get a `File`.

### `static Future<File> resolve(String relativePath)` <a id="resolve"></a>
- **Kind:** static method of `ImageService`
- **Source:** `lib/shared/services/image_service.dart` (line 56)
- **Purpose:** Turn a stored relative image path back into an absolute `File`.
- **Inputs:** `relativePath` — e.g. `"images/xxxx.png"`.
- **Returns:** `Future<File>` — does not itself check that the file exists.
- **Side effects:** None (pure path join; reads `TodoStorage.getAppDir()`).
- **Algorithm:** `File(p.join((await TodoStorage.getAppDir()).path, relativePath))`.
- **Usage:**
  ```dart
  FutureBuilder<File>(
    future: ImageService.resolve(account.imagePath!),
    ...
  )
  ```
  (`lib/features/finance/views/accounts_page.dart`, rendering a stored account image.)
- **Notes:** Callers are responsible for checking `imagePath != null` before calling this (every
  call site in the repo uses `!` after a null check), and for handling a missing file (e.g. via
  `FutureBuilder`/`File.exists()`) since `resolve` does not validate existence.

### `static Future<void> delete(String relativePath)` <a id="delete"></a>
- **Kind:** static method of `ImageService`
- **Source:** `lib/shared/services/image_service.dart` (line 67)
- **Purpose:** Delete a previously saved image from app storage if it exists.
- **Inputs:** `relativePath`.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes the resolved file from disk when present.
- **Algorithm:** Resolve the path, check `await file.exists()`, delete only if true.
- **Usage:** Called when a partner/toy/account/subscription with an attached image is removed, so
  the on-disk image does not become an orphan.
- **Notes:** Silently no-ops when the file is already missing (no exception thrown).

### `static Future<String?> downloadAndSave(String url, {int minBytes = 500})` <a id="downloadandsave"></a>
- **Kind:** static method of `ImageService`
- **Source:** `lib/shared/services/image_service.dart` (line 83)
- **Purpose:** Download an image from a URL (e.g. a bank logo) and save it locally, rejecting
  responses that are too small to be a real image.
- **Inputs:** `url`; `minBytes` (default `500`) — responses smaller than this are treated as
  placeholder/default favicons and rejected.
- **Returns:** `Future<String?>` — `"images/<uuid><ext>"`, or `null` on any failure (non-200 status,
  too-small body, or thrown exception).
- **Side effects:** Performs an HTTP GET; writes the downloaded bytes into `<appDir>/images/`.
- **Algorithm:**
  1. `http.get(Uri.parse(url))`; return `null` if `statusCode != 200`.
  2. Return `null` if `response.bodyBytes.length < minBytes`.
  3. Pick a file extension from the `content-type` header: `jpeg`/`jpg` → `.jpg`, `ico` → `.ico`,
     `svg` → `.svg`, otherwise default `.png`.
  4. Ensure the image directory exists, build a new UUID file name, write the bytes.
  5. Return the relative path; any thrown exception anywhere in the try block is caught and
     converted to a `null` return.
- **Usage:**
  ```dart
  path = await ImageService.downloadAndSave(url);
  ```
  (`lib/features/finance/views/accounts_page.dart`, downloading a bank logo from
  `BankPresetService`-provided URLs.)
- **Notes:** The `minBytes` filter exists specifically to reject tiny placeholder/default favicon
  responses some bank logo URLs return instead of a real 404.
