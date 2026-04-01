import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../features/todo/services/todo_storage.dart';

class ImageService {
  static Future<Directory> _getImageDir() async {
    final appDir = await TodoStorage.getAppDir();
    final imgDir = Directory(p.join(appDir.path, 'images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir;
  }

  /// Pick an image file and copy it into app storage.
  /// Returns the relative path (relative to appDir) e.g. "images/xxx.png",
  /// or null if the user cancelled.
  static Future<String?> pickAndSaveImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final pickedPath = result.files.single.path;
    if (pickedPath == null) return null;

    final imgDir = await _getImageDir();
    final ext = p.extension(pickedPath);
    final newName = '${const Uuid().v4()}$ext';
    final dest = File(p.join(imgDir.path, newName));
    await File(pickedPath).copy(dest.path);
    return 'images/$newName';
  }

  /// Resolve a relative imagePath to an absolute File path.
  static Future<File> resolve(String relativePath) async {
    final appDir = await TodoStorage.getAppDir();
    return File(p.join(appDir.path, relativePath));
  }

  /// Delete a previously saved image.
  static Future<void> delete(String relativePath) async {
    final file = await resolve(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Download an image from [url] and save it into app storage.
  /// Returns the relative path e.g. "images/xxx.png", or null on failure.
  /// Rejects responses smaller than [minBytes] (default 500) to filter out
  /// placeholder / default favicons.
  static Future<String?> downloadAndSave(String url, {int minBytes = 500}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      if (response.bodyBytes.length < minBytes) return null;

      final contentType = response.headers['content-type'] ?? '';
      String ext = '.png';
      if (contentType.contains('jpeg') || contentType.contains('jpg')) {
        ext = '.jpg';
      } else if (contentType.contains('ico')) {
        ext = '.ico';
      } else if (contentType.contains('svg')) {
        ext = '.svg';
      }

      final imgDir = await _getImageDir();
      final newName = '${const Uuid().v4()}$ext';
      final dest = File(p.join(imgDir.path, newName));
      await dest.writeAsBytes(response.bodyBytes);
      return 'images/$newName';
    } catch (_) {
      return null;
    }
  }
}
