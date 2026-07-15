class UserModel {
  UserModel({this.status, this.massage, this.data});

  UserModel.fromJson(Map<String, dynamic> json) {
    status = json['status'] as int?;
    massage = json['massage'] as String?;
    data = json['data'] != null ? Data.fromJson(json['data'] as Map<String, dynamic>) : null;
  }
  int? status;
  String? massage;
  Data? data;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['status'] = status;
    data['massage'] = massage;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Data({this.token, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    token = json['token'] as String?;
    user = json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null;
  }
  String? token;
  User? user;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['token'] = token;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  User({
    this.id,
    this.name,
    this.email,
    this.role,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.active,
    this.width,
    this.hight,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    name = json['name'] as String?;
    email = json['email'] as String?;
    role = json['role'] as String?;
    emailVerifiedAt = json['email_verified_at'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
    active = json['active'] as String?;
    width = json['width'] as String?;
    hight = json['hight'] as String?;
  }
  int? id;
  String? name;
  String? email;
  String? role;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  String? active;
  String? width;
  String? hight;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['role'] = role;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['active'] = active;
    data['width'] = width;
    data['hight'] = hight;
    return data;
  }
}
