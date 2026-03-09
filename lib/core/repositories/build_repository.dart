import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/build.dart';

class BuildRepository {
  static const String _boxName = 'builds';
  static const _uuid = Uuid();

  static BuildRepository? _instance;
  static BuildRepository get instance => _instance ??= BuildRepository._();
  BuildRepository._();

  Box<Build>? _box;

  Future<Box<Build>> get _openBox async {
    _box ??= await Hive.openBox<Build>(_boxName);
    return _box!;
  }

  Future<List<Build>> getAllBuilds() async {
    final box = await _openBox;
    return box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<Build>> getSurvivorBuilds() async {
    final all = await getAllBuilds();
    return all.where((b) => b.isSurvivor).toList();
  }

  Future<List<Build>> getKillerBuilds() async {
    final all = await getAllBuilds();
    return all.where((b) => !b.isSurvivor).toList();
  }

  Future<Build> createBuild({
    required String name,
    required bool isSurvivor,
    List<String>? perkIds,
    String? notes,
    List<String>? tags,
  }) async {
    final box = await _openBox;
    final build = Build(
      id: _uuid.v4(),
      name: name,
      isSurvivor: isSurvivor,
      perkIds: perkIds ?? [],
      notes: notes,
      tags: tags,
    );
    await box.put(build.id, build);
    return build;
  }

  Future<void> saveBuild(Build build) async {
    final box = await _openBox;
    await box.put(build.id, build);
  }

  Future<void> deleteBuild(String id) async {
    final box = await _openBox;
    await box.delete(id);
  }

  Future<Build?> getBuildById(String id) async {
    final box = await _openBox;
    return box.get(id);
  }
}
