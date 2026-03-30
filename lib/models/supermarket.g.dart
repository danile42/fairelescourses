// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supermarket.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupermarketAdapter extends TypeAdapter<Supermarket> {
  @override
  final int typeId = 0;

  @override
  Supermarket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Supermarket(
      id: fields[0] as String,
      name: fields[1] as String,
      rows: (fields[2] as List).cast<String>(),
      cols: (fields[3] as List).cast<String>(),
      entrance: fields[4] as String,
      exit: fields[5] as String,
      cells: (fields[6] as Map).map(
        (dynamic k, dynamic v) =>
            MapEntry(k as String, (v as List).cast<String>()),
      ),
      address: fields[7] as String?,
      lat: fields[8] as double?,
      lng: fields[9] as double?,
      parentId: fields[10] as String?,
      subcells: fields[11] != null
          ? (fields[11] as Map).map(
              (dynamic k, dynamic v) =>
                  MapEntry(k as String, (v as List).cast<String>()),
            )
          : null,
      osmCategory: fields[12] as String?,
      osmCategories: (fields[13] as List?)?.cast<String>(),
      floorsRaw: (fields[14] as List?)?.toList(),
      groundFloorName: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Supermarket obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.rows)
      ..writeByte(3)
      ..write(obj.cols)
      ..writeByte(4)
      ..write(obj.entrance)
      ..writeByte(5)
      ..write(obj.exit)
      ..writeByte(6)
      ..write(obj.cells)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.lat)
      ..writeByte(9)
      ..write(obj.lng)
      ..writeByte(10)
      ..write(obj.parentId)
      ..writeByte(11)
      ..write(obj.subcells)
      ..writeByte(12)
      ..write(obj.osmCategory)
      ..writeByte(13)
      ..write(obj.osmCategories)
      ..writeByte(14)
      ..write(obj.floorsRaw)
      ..writeByte(15)
      ..write(obj.groundFloorName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupermarketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
