// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************
// Este código es generado automáticamente por Hive. No lo modifiques manualmente.
class BoatModelAdapter extends TypeAdapter<BoatModel> {
  @override
  final int typeId = 0;

  @override
  BoatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoatModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      capacity: fields[3] as int,
      pricePerDay: fields[4] as double,
      description: fields[5] as String,
      imageUrl: fields[6] as String,
      depositAmount: fields[7] as double,
      isAvailable: fields[8] as bool,
      portName: fields[9] as String,
      ratingAvg: fields[10] as double,
      ratingCount: fields[11] as int,
      requiredLicense: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BoatModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.capacity)
      ..writeByte(4)
      ..write(obj.pricePerDay)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.depositAmount)
      ..writeByte(8)
      ..write(obj.isAvailable)
      ..writeByte(9)
      ..write(obj.portName)
      ..writeByte(10)
      ..write(obj.ratingAvg)
      ..writeByte(11)
      ..write(obj.ratingCount)
      ..writeByte(12)
      ..write(obj.requiredLicense);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
