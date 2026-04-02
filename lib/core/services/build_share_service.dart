import 'dart:convert';
import '../models/build.dart';

/// Encodes and decodes builds as portable share codes.
///
/// Format: `DBD:<base64url(JSON)>`
/// The JSON uses short keys to keep the code compact.
class BuildShareService {
  static const _prefix = 'DBD:';

  /// Returns a share code string for [build].
  static String encode(Build build) {
    final data = <String, dynamic>{
      'n': build.name,
      's': build.isSurvivor,
      'p': build.perkIds,
      if (build.itemId != null) 'i': build.itemId,
      if (build.addon1 != null && build.addon1!.isNotEmpty) 'a1': build.addon1,
      if (build.addon2 != null && build.addon2!.isNotEmpty) 'a2': build.addon2,
      if (build.offeringId != null) 'o': build.offeringId,
      if (build.notes != null && build.notes!.isNotEmpty) 'notes': build.notes,
      if (build.tags.isNotEmpty) 'tags': build.tags,
    };
    final jsonStr = jsonEncode(data);
    final encoded = base64Url.encode(utf8.encode(jsonStr));
    return '$_prefix$encoded';
  }

  /// Parses [code] and returns a [Build] with a blank id, or null on failure.
  static Build? decode(String code) {
    try {
      final trimmed = code.trim();
      if (!trimmed.startsWith(_prefix)) return null;
      final encoded = trimmed.substring(_prefix.length);
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Build(
        id: '',
        name: (data['n'] as String?)?.isNotEmpty == true
            ? data['n'] as String
            : 'Imported Build',
        isSurvivor: data['s'] as bool? ?? true,
        perkIds: List<String>.from(data['p'] ?? []),
        itemId: data['i'] as String?,
        addon1: data['a1'] as String?,
        addon2: data['a2'] as String?,
        offeringId: data['o'] as String?,
        notes: data['notes'] as String?,
        tags: List<String>.from(data['tags'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }
}
