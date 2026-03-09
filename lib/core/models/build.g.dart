// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BuildAdapter extends TypeAdapter<Build> {
  @override
  final int typeId = 1;

  @override
  Build read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Build(
      id: fields[0] as String,
      name: fields[1] as String,
      isSurvivor: fields[2] as bool,
      perkIds: (fields[3] as List).cast<String>(),
      notes: fields[4] as String?,
      tags: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      itemId: fields[8] as String?,
      addon1: fields[9] as String?,
      addon2: fields[10] as String?,
      offeringId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Build obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isSurvivor)
      ..writeByte(3)
      ..write(obj.perkIds)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.itemId)
      ..writeByte(9)
      ..write(obj.addon1)
      ..writeByte(10)
      ..write(obj.addon2)
      ..writeByte(11)
      ..write(obj.offeringId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
