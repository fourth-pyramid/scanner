import 'package:equatable/equatable.dart';

/// Entity representing a category
/// Pure Dart - no external dependencies
class CategoryEntity extends Equatable {
  const CategoryEntity({this.id, this.name, this.image});
  final int? id;
  final String? name;
  final String? image;

  @override
  List<Object?> get props => [id, name, image];
}
