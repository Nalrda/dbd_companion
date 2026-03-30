// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchRecordAdapter extends TypeAdapter<MatchRecord> {
  @override
  final int typeId = 3;

  @override
  MatchRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchRecord(
      id: fields[0] as String,
      isSurvivor: fields[1] as bool,
      outcome: fields[2] as String,
      characterName: fields[3] as String?,
      mapName: fields[4] as String?,
      perkIds: (fields[5] as List).cast<String>(),
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      gensRemaining: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MatchRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isSurvivor)
      ..writeByte(2)
      ..write(obj.outcome)
      ..writeByte(3)
      ..write(obj.characterName)
      ..writeByte(4)
      ..write(obj.mapName)
      ..writeByte(5)
      ..write(obj.perkIds)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.gensRemaining);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
