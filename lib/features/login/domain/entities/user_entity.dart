import 'package:equatable/equatable.dart';

/// Entity representing user data
/// Pure Dart - no external dependencies
class UserEntity extends Equatable {
  const UserEntity({
    this.id,
    this.name,
    this.email,
    this.role,
    this.token,
    this.active,
  });
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? token;
  final String? active;

  @override
  List<Object?> get props => [id, name, email, role, token, active];
}
