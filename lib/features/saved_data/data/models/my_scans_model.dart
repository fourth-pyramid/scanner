class MyScansModel {
  MyScansModel({this.status, this.massage, this.data});

  MyScansModel.fromJson(Map<String, dynamic> json) {
    status = json['status'] as int?;
    massage = json['massage'] as String?;
    if (json['data'] != null) {
      data = <SavedData>[];
      for (final v in (json['data'] as List)) {
        data!.add(SavedData.fromJson(v as Map<String, dynamic>));
      }
    }
  }
  int? status;
  String? massage;
  List<SavedData>? data;

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

class SavedData {
  SavedData({
    this.id,
    this.pin,
    this.serial,
    this.image,
    this.phoneType,
    this.userId,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  SavedData.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    pin = json['pin'] as String?;
    serial = json['serial'] as String?;
    image = json['image'] as String?;
    phoneType = json['phone_type'] as String?;
    userId = json['user_id'] as String?;
    categoryId = json['category_id'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
  }
  int? id;
  String? pin;
  String? serial;
  String? image;
  String? phoneType;
  String? userId;
  String? categoryId;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['pin'] = pin;
    data['serial'] = serial;
    data['image'] = image;
    data['phone_type'] = phoneType;
    data['user_id'] = userId;
    data['category_id'] = categoryId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
