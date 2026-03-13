import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Web stub — no dart:io available.
/// All File-dependent operations return null or safe defaults.

/// Creates a [FileImage] provider from a file path.
/// Returns null on web (File not available).
ImageProvider? createFileImage(String path) => null;

/// Gets the file size in bytes for the given path.
/// Returns null on web.
Future<int?> getFileLength(String path) async => null;

/// Whether the current platform supports local file operations.
bool get supportsLocalFiles => false;

/// Gets a temporary directory path.
/// Returns null on web.
Future<String?> getTempDirPath() async => null;

/// Checks if a file exists at the given path.
/// Returns false on web.
Future<bool> fileExists(String path) async => false;

/// Writes bytes to a file at the given path.
/// No-op on web.
Future<void> writeFileBytes(String path, Uint8List bytes) async {}

/// Creates a file:// URI from a path.
/// Returns a placeholder URI on web.
Uri fileUri(String path) => Uri.parse(path);
