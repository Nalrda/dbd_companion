// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_plan.dart';

class GroupPlanAdapter extends TypeAdapter<GroupPlan> {
  @override
  final int typeId = 2;

  @override
  GroupPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupPlan(
      id: fields[0] as String,
      name: fields[1] as String,
      survivor1PerkIds: (fields[2] as List).cast<String>(),
      survivor2PerkIds: (fields[3] as List).cast<String>(),
      survivor3PerkIds: (fields[4] as List).cast<String>(),
      survivor4PerkIds: (fields[5] as List).cast<String>(),
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.survivor1PerkIds)
      ..writeByte(3)
      ..write(obj.survivor2PerkIds)
      ..writeByte(4)
      ..write(obj.survivor3PerkIds)
      ..writeByte(5)
      ..write(obj.survivor4PerkIds)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
