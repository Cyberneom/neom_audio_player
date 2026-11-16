import '../../utils/enums/lyrics_source.dart';
import '../../utils/enums/lyrics_type.dart';

/// Hive-persistable lyrics cache record.
///
/// Stored keyed by media item ID so repeated plays do not re-fetch.
/// The [cachedAt] timestamp lets [LyricsController] expire stale entries.
class LyricsCacheEntry {
  static const int maxMediaIdChars = 256;
  static const int maxLyricsChars = 512 * 1024;
  static const int _maxSafeEpochMs = 8640000000000000;
  static final RegExp _unsafeIdChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _encodedTraversalOrBidi = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|d8%9c|ef%bb%bf)',
    caseSensitive: false,
  );
  static final RegExp _unsafeLyricsChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _pairedPromptBlocks = RegExp(
    r'<\s*(memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?<\s*/\s*\1\s*>|\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\](?:(?!\[\s*/?\s*\2\b)[\s\S])*?\[\s*/\s*\2\b[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _llmArtifacts = RegExp(
    r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\s*\|>|$)|<\|tool_call>[\s\S]*?(?:<tool_call\|>|$)|<think\b[^>]*>[\s\S]*?(?:</think\s*>|$)|<\|/?(?:turn|channel|tool_call|eot)\|?>?|<(?:turn|channel|tool_call)\s*\|>|<\s*/?\s*(?:think|thought|memory_recall|auto_memory|system_context)\b[^>]*>|\[\s*/?\s*(?:MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT|BIOCHIP)\b[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _closingContentTag = RegExp(
    r'</\s*content\s*>',
    caseSensitive: false,
  );

  String mediaId;
  String lyrics;
  LyricsSource source;
  LyricsType type;
  DateTime cachedAt;

  LyricsCacheEntry({
    this.mediaId = '',
    this.lyrics = '',
    this.source = LyricsSource.internal,
    this.type = LyricsType.text,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  static String _cleanId(dynamic raw) {
    if (raw == null) return '';
    final rawStr = raw.toString();
    if (_unsafeIdChars.hasMatch(rawStr) ||
        _encodedTraversalOrBidi.hasMatch(rawStr)) {
      return '';
    }
    final cleaned = rawStr.trim();
    final lower = cleaned.toLowerCase();
    if (cleaned.isEmpty ||
        cleaned == '.' ||
        cleaned == '..' ||
        cleaned.contains('..') ||
        cleaned.contains('/') ||
        cleaned.contains(r'\') ||
        lower == '__proto__' ||
        lower == 'constructor' ||
        lower == 'prototype' ||
        (lower.startsWith('__') && lower.endsWith('__'))) {
      return '';
    }
    return cleaned.length <= maxMediaIdChars
        ? cleaned
        : cleaned.substring(0, maxMediaIdChars);
  }

  static String _cleanLyrics(dynamic raw) {
    if (raw == null) return '';
    final rawStr = raw.toString();
    final bounded = rawStr.length <= maxLyricsChars
        ? rawStr
        : rawStr.substring(0, maxLyricsChars);
    return bounded
        .replaceAll(_pairedPromptBlocks, '')
        .replaceAll(_llmArtifacts, '')
        .replaceAll(_closingContentTag, '[content_end]')
        .replaceAll(_unsafeLyricsChars, '');
  }

  static DateTime _parseCachedAt(dynamic raw) {
    if (raw is num && raw.isFinite) {
      final ms = raw.toInt();
      if (ms > 0 && ms <= _maxSafeEpochMs) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    if (raw != null) {
      final parsed = DateTime.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJSON() {
    return {
      'mediaId': mediaId,
      'lyrics': lyrics,
      'source': source.name,
      'type': type.name,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  LyricsCacheEntry.fromJSON(Map<String, dynamic> data)
    : mediaId = _cleanId(data['mediaId']),
      lyrics = _cleanLyrics(data['lyrics']),
      source = LyricsSource.values.firstWhere(
        (e) => e.name == data['source']?.toString().trim(),
        orElse: () => LyricsSource.internal,
      ),
      type = LyricsType.values.firstWhere(
        (e) => e.name == data['type']?.toString().trim(),
        orElse: () => LyricsType.text,
      ),
      cachedAt = _parseCachedAt(data['cachedAt']);

  bool get isExpired {
    final now = DateTime.now();
    if (cachedAt.isAfter(now.add(const Duration(days: 1)))) return true;
    return now.difference(cachedAt).inHours > 72;
  }

}
