// Conditional export for the on-device song cache.
// On platforms with dart:io (mobile, desktop), exports the real store over
// just_audio's cache directory. On web, where the browser owns caching,
// exports a stub that reports an empty cache.
export 'audio_cache_store_stub.dart'
    if (dart.library.io) 'audio_cache_store_io.dart';
