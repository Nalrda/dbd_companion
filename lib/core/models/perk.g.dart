// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perk.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerkAdapter extends TypeAdapter<Perk> {
  @override
  final int typeId = 0;

  @override
  Perk read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Perk(
      id: fields[0] as String,
      name: fields[1] as String,
      character: fields[2] as String,
      categories: (fields[3] as List).cast<String>(),
      isSurvivor: fields[5] as bool,
      iconUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Perk obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.character)
      ..writeByte(3)
      ..write(obj.categories)
      ..writeByte(5)
      ..write(obj.isSurvivor)
      ..writeByte(6)
      ..write(obj.iconUrl);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
