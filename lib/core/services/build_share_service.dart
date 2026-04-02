import 'dart:convert';
import '../models/build.dart';
import '../models/group_plan.dart';

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

  // ─── Group Plan ────────────────────────────────────────────────────────────

  static const _groupPrefix = 'DBDG:';

  /// Returns a share code string for [plan].
  static String encodeGroupPlan(GroupPlan plan) {
    final survivors = List.generate(4, (i) {
      final perks = plan.getPerkIdsForSurvivor(i);
      final item = plan.getItemIdForSurvivor(i);
      final offering = plan.getOfferingIdForSurvivor(i);
      return <String, dynamic>{
        'p': perks,
        if (item != null) 'i': item,
        if (offering != null) 'o': offering,
      };
    });
    final data = <String, dynamic>{
      'n': plan.name,
      if (plan.notes != null && plan.notes!.isNotEmpty) 'notes': plan.notes,
      's': survivors,
    };
    final jsonStr = jsonEncode(data);
    final encoded = base64Url.encode(utf8.encode(jsonStr));
    return '$_groupPrefix$encoded';
  }

  /// Parses [code] and returns a [GroupPlan] with a blank id, or null on failure.
  static GroupPlan? decodeGroupPlan(String code) {
    try {
      final trimmed = code.trim();
      if (!trimmed.startsWith(_groupPrefix)) return null;
      final encoded = trimmed.substring(_groupPrefix.length);
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final survivors = (data['s'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      List<String> perks(int i) =>
          i < survivors.length ? List<String>.from(survivors[i]['p'] ?? []) : [];
      String? item(int i) =>
          i < survivors.length ? survivors[i]['i'] as String? : null;
      String? offering(int i) =>
          i < survivors.length ? survivors[i]['o'] as String? : null;

      return GroupPlan(
        id: '',
        name: (data['n'] as String?)?.isNotEmpty == true
            ? data['n'] as String
            : 'Imported Plan',
        notes: data['notes'] as String?,
        survivor1PerkIds: perks(0),
        survivor2PerkIds: perks(1),
        survivor3PerkIds: perks(2),
        survivor4PerkIds: perks(3),
        survivor1ItemId: item(0),
        survivor2ItemId: item(1),
        survivor3ItemId: item(2),
        survivor4ItemId: item(3),
        survivor1OfferingId: offering(0),
        survivor2OfferingId: offering(1),
        survivor3OfferingId: offering(2),
        survivor4OfferingId: offering(3),
      );
    } catch (_) {
      return null;
    }
  }
}
