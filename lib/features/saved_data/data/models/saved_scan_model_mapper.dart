import '../../../../core/appStorage/my_scans_model.dart';
import '../../domain/entities/saved_scan_entity.dart';

/// Mapper to convert SavedData (Data) to SavedScanEntity (Domain)
extension SavedDataMapper on SavedData {
  SavedScanEntity toEntity() => SavedScanEntity(
    id: id,
    pin: pin,
    serial: serial,
    image: image,
    phoneType: phoneType,
    categoryId: categoryId,
    createdAt: createdAt,
  );
}

extension MyScansModelMapper on MyScansModel {
  List<SavedScanEntity> toEntityList() {
    if (data == null) return [];
    return data!.map((scan) => scan.toEntity()).toList();
  }
}
