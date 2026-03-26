import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:qrscanner/common_component/snack_bar.dart';
import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/utils/image_isolate_helper.dart';
import 'package:qrscanner/core/utils/text_isolate_helper.dart';
import 'package:qrscanner/features/extract_image/extact_image_states.dart';
import 'package:qrscanner/features/extract_image/qr_camera_page.dart';

class ExtractImageController extends Cubit<ExtractImageStates> {
  ExtractImageController(this.scanType) : super(ExtractInitial());

  static ExtractImageController of(context) => BlocProvider.of(context);

  final pin = TextEditingController();
  final serial = TextEditingController();
  final String? scanType;

  bool textScanned = false;
  File? image;

  Future<void> getImage(BuildContext context) async {
    try {
      if (!context.mounted) {
        return;
      }

      final capturedFile = await QrCameraPage.capture(context);

      if (capturedFile == null) {
        emit(ImagePickedError());
        return;
      }

      final capturedPath = capturedFile.path.replaceFirst('file://', '');
      final sourceFile = File(capturedPath);

      if (!await sourceFile.exists()) {
        showSnackBar('فشل في حفظ الصورة', color: Colors.red);
        emit(ImagePickedError());
        return;
      }

      image = sourceFile;
      emit(ImagePickedSuccess());

      await _processImageOcr(sourceFile);
    } catch (e) {
      showSnackBar('خطأ في تصوير الكارت', color: Colors.red);
      emit(ImagePickedError());
    }
  }

  Future<void> _processImageOcr(File imageFile) async {
    emit(Scanning());

    try {
      File finalImage = imageFile;
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInKB = fileSizeInBytes / 1024;

      // تغيير حجم الصورة إذا كانت أكبر من 1024KB
      if (fileSizeInKB > 1024) {
        try {
          // Use isolate for heavy image processing
          final compressedFile =
              await ImageIsolateHelper.compressImageInIsolate(
                imagePath: imageFile.path,
              );

          if (compressedFile != null && await compressedFile.exists()) {
            finalImage = compressedFile;
          }
        } catch (e) {
          // نكمل بالصورة الأصلية في حالة فشل الضغط
        }
      }

      // إرسال الطلب للـ API
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.ocr.space/parse/image'),
      );

      request.headers['apikey'] = 'K81690124888957';
      request.fields.addAll({
        'scale': 'true',
        'isOverlayRequired': 'false',
        'OCREngine': '2',
        'language': 'eng',
        'detectOrientation': 'true',
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', finalImage.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      final dynamic decodedData = jsonDecode(body);
      if (decodedData is! Map<String, dynamic>) {
        showSnackBar('تنسيق استجابة غير صالح من الخادم', color: Colors.red);
        emit(ScanError());
        return;
      }

      final jsonData = decodedData;

      if (jsonData['IsErroredOnProcessing'] == true) {
        final dynamic errorMessage = jsonData['ErrorMessage'];
        String msg = 'حدث خطأ أثناء المعالجة';
        if (errorMessage is List && errorMessage.isNotEmpty) {
          msg = 'خطأ: ${errorMessage.first}';
        } else if (errorMessage is String) {
          msg = 'خطأ: $errorMessage';
        }
        showSnackBar(msg, color: Colors.red);
        emit(ScanError());
        return;
      }

      final dynamic parsedResults = jsonData['ParsedResults'];

      if (parsedResults is List && parsedResults.isNotEmpty) {
        final firstResult = parsedResults[0];
        if (firstResult is Map<String, dynamic>) {
          final parsedText = firstResult['ParsedText'];
          if (parsedText != null && parsedText.toString().trim().isNotEmpty) {
            _extractNumbersFromText(parsedText.toString());
          } else {
            showSnackBar(
              'لم يتم العثور على نص في الصورة',
              color: Colors.orange,
            );
            emit(ScanError());
          }
        } else {
          showSnackBar('تنسيق نتائج غير صالح', color: Colors.orange);
          emit(ScanError());
        }
      } else {
        showSnackBar('لم يتم العثور على نتائج OCR', color: Colors.orange);
        emit(ScanError());
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection timed out')) {
        showSnackBar(
          'فشل الاتصال بالإنترنت، يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
          color: Colors.red,
        );
      } else {
        showSnackBar('حدث خطأ: $e', color: Colors.red);
      }
      emit(ScanError());
    }
  }

  Future<void> _extractNumbersFromText(String text) async {
    // Use isolate for regex processing
    final result = await TextIsolateHelper.extractNumbersInIsolate(text);
    final String? foundPin = result['pin'];
    final String? foundSerial = result['serial'];

    if (foundPin != null) {
      pin.text = _formatPin(foundPin);
    }
    if (foundSerial != null) {
      serial.text = foundSerial;
    }

    if (foundPin != null || foundSerial != null) {
      textScanned = true;
      emit(ScanPinSuccess());
    } else {
      showSnackBar(
        'لم يتم العثور على أرقام (12 أو 14 رقم)',
        color: Colors.orange,
      );
      emit(ScanError());
    }
  }

  String _formatPin(String number) {
    if (number.length != 14) return number;
    return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7, 11)} ${number.substring(11, 14)}';
  }

  void resetState() {
    textScanned = false;
    image = null;
    pin.clear();
    serial.clear();
    emit(ExtractInitial());
  }

  int historyCount = 0;
  Future<void> loadHistoryCount() async {
    try {
      final response = await DioHelper.get('count');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['status'] == 1 && data['data'] != null) {
          historyCount = data['data'] is int
              ? data['data']
              : int.tryParse(data['data'].toString()) ?? 0;

          emit(ScanPinSuccess());
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> scan({
    required String phoneType,
    required int categoryId,
  }) async {
    emit(ScanLoading());

    try {
      final fields = <String, dynamic>{
        'pin': pin.text.replaceAll(' ', ''),
        'serial': serial.text.replaceAll(' ', ''),
        'phone_type': phoneType,
        'category_id': categoryId.toString(),
      };

      final formData = FormData.fromMap(fields);

      if (image != null && await image!.exists()) {
        final filename = p.basename(image!.path);
        final multipartFile = await MultipartFile.fromFile(
          image!.path,
          filename: filename,
        );
        formData.files.add(MapEntry('image', multipartFile));
      }

      final response = await DioHelper.post('scan', true, formData: formData);

      if (response.data is! Map<String, dynamic>) {
        showSnackBar('استجابة غير صالحة من الخادم');
        emit(ScanError());
        return;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 1) {
        showSnackBar('تم الارسال بنجاح');
        emit(ScanSuccess());
        resetState();
      } else {
        final msg = data['massage'] ?? data['message'] ?? 'حدث خطأ ما';
        showSnackBar(msg.toString());
        emit(ScanError());
      }
    } catch (error) {
      showSnackBar('حدث خطأ أثناء الإرسال');
      emit(ScanError());
    }
  }

  @override
  Future<void> close() async {
    pin.dispose();
    serial.dispose();
    return super.close();
  }
}
