import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/card_data.dart';
import '../../domain/usecases/get_history_count_usecase.dart';
import '../../domain/usecases/process_image_usecase.dart';
import '../../domain/usecases/submit_scan_usecase.dart';
import 'extract_image_state.dart';

/// Cubit for ExtractImage feature
/// Only handles UI state and calls UseCases - no business logic
class ExtractImageCubit extends Cubit<ExtractImageState> {
  ExtractImageCubit({
    required this.processImageUseCase,
    required this.submitScanUseCase,
    required this.getHistoryCountUseCase,
  }) : super(ExtractImageInitial());
  final ProcessImageUseCase processImageUseCase;
  final SubmitScanUseCase submitScanUseCase;
  final GetHistoryCountUseCase getHistoryCountUseCase;

  // State fields
  File? _currentImage;
  String? _currentPin;
  String? _currentSerial;
  File? _pinCroppedImage;
  File? _serialCroppedImage;
  bool _pinDetected = false;
  bool _serialDetected = false;
  int _historyCount = 0;

  // Getters for UI access
  File? get currentImage => _currentImage;
  String? get currentPin => _currentPin;
  String? get currentSerial => _currentSerial;
  File? get pinCroppedImage => _pinCroppedImage;
  File? get serialCroppedImage => _serialCroppedImage;
  bool get pinDetected => _pinDetected;
  bool get serialDetected => _serialDetected;
  int get historyCount => _historyCount;

  /// Set captured image from camera
  void setImage(File image) {
    _currentImage = image;
    _resetExtractionData();
    emit(ImagePickedSuccess(image: image));
  }

  /// Process the current image and extract PIN/SERIAL
  Future<void> processImage() async {
    if (_currentImage == null) {
      emit(const ScanError(message: 'No image selected'));
      return;
    }

    emit(Scanning());

    final result = await processImageUseCase(
      ProcessImageParams(imageFile: _currentImage!),
    );

    result.fold((failure) => emit(ScanError(message: failure.message)), (
      cardData,
    ) {
      _applyCardData(cardData);
      emit(
        ScanResultLoaded(
          pin: cardData.pin,
          serial: cardData.serial,
          pinCroppedImage: cardData.pinCroppedImage,
          serialCroppedImage: cardData.serialCroppedImage,
          pinDetected: cardData.pinDetected,
          serialDetected: cardData.serialDetected,
        ),
      );
    });
  }

  /// Submit scan data to server
  Future<bool> submitScan({
    required String phoneType,
    required int categoryId,
  }) async {
    if (_currentPin == null || _currentSerial == null) {
      emit(const ScanError(message: 'PIN and Serial are required'));
      return false;
    }

    emit(SubmitLoading());

    final result = await submitScanUseCase(
      SubmitScanParams(
        pin: _currentPin!,
        serial: _currentSerial!,
        phoneType: phoneType,
        categoryId: categoryId,
        image: _currentImage,
      ),
    );

    return result.fold(
      (failure) {
        emit(ScanError(message: failure.message));
        return false;
      },
      (_) {
        emit(ScanSuccess());
        // Reload history count after successful submission
        loadHistoryCount();
        return true;
      },
    );
  }

  /// Load history count from server
  Future<void> loadHistoryCount() async {
    final result = await getHistoryCountUseCase(NoParams());

    result.fold(
      (failure) {
        // Silently fail for history count
        _historyCount = 0;
      },
      (count) {
        _historyCount = count;
        emit(HistoryCountLoaded(count: count));
      },
    );
  }

  /// Reset all state
  void reset() {
    _currentImage = null;
    _resetExtractionData();
    emit(ExtractImageInitial());
  }

  /// Clear extraction data but keep image
  void _resetExtractionData() {
    _currentPin = null;
    _currentSerial = null;
    _pinCroppedImage = null;
    _serialCroppedImage = null;
    _pinDetected = false;
    _serialDetected = false;
  }

  /// Apply extracted card data to state
  void _applyCardData(CardData cardData) {
    _currentPin = cardData.pin;
    _currentSerial = cardData.serial;
    _pinCroppedImage = cardData.pinCroppedImage;
    _serialCroppedImage = cardData.serialCroppedImage;
    _pinDetected = cardData.pinDetected;
    _serialDetected = cardData.serialDetected;
  }

  /// Manual update PIN (for manual entry)
  void updatePin(String pin) {
    _currentPin = pin;
  }

  /// Manual update Serial (for manual entry)
  void updateSerial(String serial) {
    _currentSerial = serial;
  }

  /// Static method to get cubit from context
  static ExtractImageCubit of(BuildContext context) =>
      BlocProvider.of<ExtractImageCubit>(context);
}
