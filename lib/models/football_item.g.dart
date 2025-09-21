// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'football_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FootballItemAdapter extends TypeAdapter<FootballItem> {
  @override
  final int typeId = 0;

  @override
  FootballItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FootballItem(name: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, FootballItem obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FootballItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
