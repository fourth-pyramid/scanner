import '../../../../core/appStorage/user_model.dart';
import '../../domain/entities/user_entity.dart';

/// Mapper to convert UserModel (Data) to UserEntity (Domain)
extension UserModelMapper on UserModel {
  UserEntity toEntity() => UserEntity(
    id: data?.user?.id,
    name: data?.user?.name,
    email: data?.user?.email,
    role: data?.user?.role,
    token: data?.token,
    active: data?.user?.active,
  );
}
