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
      survivor1ItemId: fields[9] as String?,
      survivor2ItemId: fields[10] as String?,
      survivor3ItemId: fields[11] as String?,
      survivor4ItemId: fields[12] as String?,
      survivor1OfferingId: fields[13] as String?,
      survivor2OfferingId: fields[14] as String?,
      survivor3OfferingId: fields[15] as String?,
      survivor4OfferingId: fields[16] as String?,
      survivor1Addon1Id: fields[17] as String?,
      survivor1Addon2Id: fields[18] as String?,
      survivor2Addon1Id: fields[19] as String?,
      survivor2Addon2Id: fields[20] as String?,
      survivor3Addon1Id: fields[21] as String?,
      survivor3Addon2Id: fields[22] as String?,
      survivor4Addon1Id: fields[23] as String?,
      survivor4Addon2Id: fields[24] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupPlan obj) {
    writer
      ..writeByte(25)
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
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.survivor1ItemId)
      ..writeByte(10)
      ..write(obj.survivor2ItemId)
      ..writeByte(11)
      ..write(obj.survivor3ItemId)
      ..writeByte(12)
      ..write(obj.survivor4ItemId)
      ..writeByte(13)
      ..write(obj.survivor1OfferingId)
      ..writeByte(14)
      ..write(obj.survivor2OfferingId)
      ..writeByte(15)
      ..write(obj.survivor3OfferingId)
      ..writeByte(16)
      ..write(obj.survivor4OfferingId)
      ..writeByte(17)
      ..write(obj.survivor1Addon1Id)
      ..writeByte(18)
      ..write(obj.survivor1Addon2Id)
      ..writeByte(19)
      ..write(obj.survivor2Addon1Id)
      ..writeByte(20)
      ..write(obj.survivor2Addon2Id)
      ..writeByte(21)
      ..write(obj.survivor3Addon1Id)
      ..writeByte(22)
      ..write(obj.survivor3Addon2Id)
      ..writeByte(23)
      ..write(obj.survivor4Addon1Id)
      ..writeByte(24)
      ..write(obj.survivor4Addon2Id);
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
