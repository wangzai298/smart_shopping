import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

/// Results from attempting to pick an image.
enum PickResult {
  /// User successfully picked an image.
  success,
  /// User cancelled (tapped back, didn't take a photo).
  cancelled,
  /// Permission was denied and cannot be requested again.
  permissionDenied,
  /// An unexpected error occurred.
  error,
}

class CameraPickResult {
  final PickResult result;
  final File? file;
  final String? errorMessage;

  const CameraPickResult({required this.result, this.file, this.errorMessage});
}

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<CameraPickResult> pickFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (xFile != null) {
        return CameraPickResult(result: PickResult.success, file: File(xFile.path));
      }
      return const CameraPickResult(result: PickResult.cancelled);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' ||
          e.code == 'permission_denied' ||
          e.message?.contains('permission') == true) {
        return const CameraPickResult(result: PickResult.permissionDenied);
      }
      return CameraPickResult(result: PickResult.error, errorMessage: e.message);
    } catch (e) {
      return CameraPickResult(result: PickResult.error, errorMessage: e.toString());
    }
  }

  Future<CameraPickResult> pickFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (xFile != null) {
        return CameraPickResult(result: PickResult.success, file: File(xFile.path));
      }
      return const CameraPickResult(result: PickResult.cancelled);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' ||
          e.code == 'permission_denied' ||
          e.message?.contains('permission') == true) {
        return const CameraPickResult(result: PickResult.permissionDenied);
      }
      return CameraPickResult(result: PickResult.error, errorMessage: e.message);
    } catch (e) {
      return CameraPickResult(result: PickResult.error, errorMessage: e.toString());
    }
  }

  /// image_picker already outputs a resized JPEG (≤1024px, quality 80).
  /// Just read the file bytes and encode to Base64 — no re-compression needed.
  Future<String> compressAndEncode(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Image encoding failed: $e');
    }
  }
}
