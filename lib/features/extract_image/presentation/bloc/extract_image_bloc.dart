import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/extract_image/domain/entities/card_data.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/get_history_count_usecase.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/process_image_usecase.dart';
import 'package:qrscanner/features/extract_image/domain/usecases/submit_scan_usecase.dart';

part 'extract_image_event.dart';
part 'extract_image_state.dart';

// ponytail: bloc for extract image feature
class ExtractImageBloc extends Bloc<ExtractImageEvent, ExtractImageState> {
  ExtractImageBloc({
    required this.processImageUseCase,
    required this.submitScanUseCase,
    required this.getHistoryCountUseCase,
  }) : super(ExtractImageInitial()) {
    on<SetImageEvent>(_onSetImage);
    on<ProcessImageEvent>(_onProcessImage);
    on<SubmitScanEvent>(_onSubmitScan);
    on<LoadHistoryCountEvent>(_onLoadHistoryCount);
    on<ResetEvent>(_onReset);
    on<UpdatePinEvent>(_onUpdatePin);
    on<UpdateSerialEvent>(_onUpdateSerial);
  }

  final ProcessImageUseCase processImageUseCase;
  final SubmitScanUseCase submitScanUseCase;
  final GetHistoryCountUseCase getHistoryCountUseCase;

  // State fields
  File? _currentImage;
  String? _currentPin;
  String? _currentSerial;
  bool _pinDetected = false;
  bool _serialDetected = false;
  int _historyCount = 0;

  // Getters for UI access
  File? get currentImage => _currentImage;
  String? get currentPin => _currentPin;
  String? get currentSerial => _currentSerial;
  bool get pinDetected => _pinDetected;
  bool get serialDetected => _serialDetected;
  int get historyCount => _historyCount;

  void _onSetImage(SetImageEvent event, Emitter<ExtractImageState> emit) {
    _currentImage = event.image;
    _resetExtractionData();
    _safeEmit(emit, ImagePickedSuccess(image: event.image));
  }

  Future<void> _onProcessImage(
    ProcessImageEvent event,
    Emitter<ExtractImageState> emit,
  ) async {
    if (_currentImage == null) {
      _safeEmit(emit, const ScanError(message: 'No image selected'));
      return;
    }

    _safeEmit(emit, Scanning());

    final result = await processImageUseCase(
      ProcessImageParams(imageFile: _currentImage!),
    );

    if (isClosed) return;

    result.fold(
      (failure) => _safeEmit(emit, ScanError(message: failure.message)),
      (cardData) {
        _applyCardData(cardData);
        _safeEmit(
          emit,
          ScanResultLoaded(
            pin: cardData.pin,
            serial: cardData.serial,
            pinDetected: cardData.pinDetected,
            serialDetected: cardData.serialDetected,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitScan(
    SubmitScanEvent event,
    Emitter<ExtractImageState> emit,
  ) async {
    if (_currentPin == null || _currentSerial == null) {
      _safeEmit(emit, const ScanError(message: 'PIN and Serial are required'));
      return;
    }

    _safeEmit(emit, SubmitLoading());

    final result = await submitScanUseCase(
      SubmitScanParams(
        pin: _currentPin!,
        serial: _currentSerial!,
        phoneType: event.phoneType,
        categoryId: event.categoryId,
        image: _currentImage,
      ),
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        _safeEmit(emit, ScanError(message: failure.message));
      },
      (_) async {
        _safeEmit(emit, ScanSuccess());
        // Load history count
        final historyResult = await getHistoryCountUseCase(NoParams());
        if (!isClosed) {
          historyResult.fold(
            (failure) {
              _historyCount = 0;
            },
            (count) {
              _historyCount = count;
              _safeEmit(emit, HistoryCountLoaded(count: count));
            },
          );
        }
      },
    );
  }

  Future<void> _onLoadHistoryCount(
    LoadHistoryCountEvent event,
    Emitter<ExtractImageState> emit,
  ) async {
    final result = await getHistoryCountUseCase(NoParams());

    if (isClosed) return;

    result.fold(
      (failure) {
        _historyCount = 0;
      },
      (count) {
        _historyCount = count;
        _safeEmit(emit, HistoryCountLoaded(count: count));
      },
    );
  }

  void _onReset(ResetEvent event, Emitter<ExtractImageState> emit) {
    _currentImage = null;
    _resetExtractionData();
    _safeEmit(emit, ExtractImageInitial());
  }

  void _onUpdatePin(UpdatePinEvent event, Emitter<ExtractImageState> emit) {
    _currentPin = event.pin;
  }

  void _onUpdateSerial(UpdateSerialEvent event, Emitter<ExtractImageState> emit) {
    _currentSerial = event.serial;
  }

  void _resetExtractionData() {
    _currentPin = null;
    _currentSerial = null;
    _pinDetected = false;
    _serialDetected = false;
  }

  void _applyCardData(CardData cardData) {
    _currentPin = cardData.pin;
    _currentSerial = cardData.serial;
    _pinDetected = cardData.pinDetected;
    _serialDetected = cardData.serialDetected;
  }

  void _safeEmit(Emitter<ExtractImageState> emit, ExtractImageState state) {
    if (!isClosed) emit(state);
  }
}
