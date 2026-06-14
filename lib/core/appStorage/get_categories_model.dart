class GetCategoriesModel {
  GetCategoriesModel({this.status, this.massage, this.data});

  GetCategoriesModel.fromJson(Map<String, dynamic> json) {
    status = json['status'] as int?;
    massage = json['massage'] as String?;
    if (json['data'] != null) {
      data = <CategoryData>[];
      for (final v in (json['data'] as List)) {
        data!.add(CategoryData.fromJson(v as Map<String, dynamic>));
      }
    }
  }
  int? status;
  String? massage;
  List<CategoryData>? data;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['status'] = status;
    data['massage'] = massage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CategoryData {
  CategoryData({
    this.id,
    this.name,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  CategoryData.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    name = json['name'] as String?;
    image = json['image'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
  }
  int? id;
  String? name;
  String? image;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
