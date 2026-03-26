import 'package:equatable/equatable.dart';

abstract class ExtractImageStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExtractInitial extends ExtractImageStates {}

class ImagePickedSuccess extends ExtractImageStates {}

class ImagePickedError extends ExtractImageStates {}

class ScanLoading extends ExtractImageStates {}

class ScanSuccess extends ExtractImageStates {}

class ScanPinSuccess extends ExtractImageStates {}

class ScanError extends ExtractImageStates {}

class Scanning extends ExtractImageStates {}
