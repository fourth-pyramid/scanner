import 'package:equatable/equatable.dart';

/// Entity representing saved scan data
/// Pure Dart - no external dependencies
class SavedScanEntity extends Equatable {
  const SavedScanEntity({
    this.id,
    this.pin,
    this.serial,
    this.image,
    this.phoneType,
    this.categoryId,
    this.createdAt,
  });
  final int? id;
  final String? pin;
  final String? serial;
  final String? image;
  final String? phoneType;
  final String? categoryId;
  final String? createdAt;

  @override
  List<Object?> get props => [
    id,
    pin,
    serial,
    image,
    phoneType,
    categoryId,
    createdAt,
  ];
}
