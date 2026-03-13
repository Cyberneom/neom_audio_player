import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile/desktop implementation — dart:io is available.

/// Creates a [FileImage] provider from a file path.
ImageProvider? createFileImage(String path) {
  // Handle file:// URI format
  final cleanPath = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  return FileImage(File(cleanPath));
}

/// Gets the file size in bytes for the given path.
Future<int?> getFileLength(String path) async {
  try {
    return await File(path).length();
  } catch (_) {
    return null;
  }
}

/// Whether the current platform supports local file operations.
bool get supportsLocalFiles => true;

/// Gets a temporary directory path.
Future<String?> getTempDirPath() async {
  try {
    final dir = await getTemporaryDirectory();
    return dir.path;
  } catch (_) {
    return null;
  }
}

/// Checks if a file exists at the given path.
Future<bool> fileExists(String path) async {
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}

/// Writes bytes to a file at the given path.
Future<void> writeFileBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes);
}

/// Creates a file:// URI from a path.
Uri fileUri(String path) => Uri.file(path);
