import 'package:qrscanner/core/appStorage/get_categories_model.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';

/// Mapper to convert CategoryData (Data) to CategoryEntity (Domain)
extension CategoryDataMapper on CategoryData {
  CategoryEntity toEntity() => CategoryEntity(id: id, name: name, image: image);
}

extension GetCategoriesModelMapper on GetCategoriesModel {
  List<CategoryEntity> toEntityList() {
    if (data == null) return [];
    return data!.map((category) => category.toEntity()).toList();
  }
}
