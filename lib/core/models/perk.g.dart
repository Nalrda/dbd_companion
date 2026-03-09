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
      description: fields[3] as String,
      rarity: fields[4] as String,
      category: fields[5] as String,
      isSurvivor: fields[6] as bool,
      iconUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Perk obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.character)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.rarity)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isSurvivor)
      ..writeByte(7)
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
