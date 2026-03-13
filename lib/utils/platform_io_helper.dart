// Conditional export for dart:io dependent functionality.
// On platforms where dart:io is available (mobile, desktop), exports
// the real implementation using File, Directory, etc.
// On web (where dart:io is unavailable), exports stubs that return
// safe defaults (null, placeholders, etc.).
export 'platform_io_helper_stub.dart'
    if (dart.library.io) 'platform_io_helper_io.dart';
