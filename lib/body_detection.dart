import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

import 'body_detection_exception.dart';
import 'models/image_result.dart';
import 'models/pose.dart';
import 'png_image.dart';
import 'types.dart';

import 'classifier.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';

class BodyDetection {
  static const MethodChannel _channel =
      MethodChannel('com.0x48lab/body_detection');
  static const EventChannel _eventChannel =
      EventChannel('com.0x48lab/body_detection/image_stream');

  static StreamSubscription<dynamic>? _imageStreamSubscription;
  static late Classifier classifier;

  bool predicting = false;
  bool initialized = false;

  late List<dynamic> inferences;

  // Image
  static Future<List<dynamic>> detectPose({required PngImage image}) async {
    final Uint8List pngImageBytes = image.bytes.buffer.asUint8List();
    try {
      // Classifier (TFLite)
      // Uint8List --> CameraImage (TODO)
      const CameraImageFormat cameraImageFormat = CameraImageFormat(ImageFormatGroup.yuv420, raw: ImageFormatGroup.yuv420);
      List<CameraImagePlane> cameraImagePlane = [
        CameraImagePlane(
          bytes: pngImageBytes,
          bytesPerRow: 8,
        )
      ];
      CameraImageData cameraImageData = CameraImageData(
        format: cameraImageFormat, 
        planes: cameraImagePlane,
        width: image.width,
        height: image.height
      );
      final CameraImage cameraImage = CameraImage.fromPlatformInterface(cameraImageData);

      // Run model
      classifier.performOperations(cameraImage);
      classifier.runModel();

      List<dynamic> results = classifier.parseLandmarkData();
      return results;
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  // Camera
  static Future<void> startCameraStream({
    ImageCallback? onFrameAvailable,
    PoseCallback? onPoseAvailable,
    BodyMaskCallback? onMaskAvailable,
  }) async {
    try {
      await _channel.invokeMethod<void>('startCameraStream');

      _imageStreamSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic result) {
          final type = result['type'];
          // Camera image
          if (type == 'image' && onFrameAvailable != null) {
            onFrameAvailable(
              ImageResult.fromMap(result),
            );
          }
          // Pose detection result
          else if (type == 'pose' && onPoseAvailable != null) {
            onPoseAvailable(
              result['pose'] == null ? null : Pose.fromMap(result['pose']),
            );
          }
        },
      );
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  Future<void> stopCameraStream() async {
    try {
      await _imageStreamSubscription?.cancel();
      _imageStreamSubscription = null;

      await _channel.invokeMethod<void>('stopCameraStream');
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<void> enablePoseDetection() async {
    try {
      await _channel.invokeMethod<void>('enablePoseDetection');
      classifier = Classifier();
      classifier.loadModel();
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  Future<void> disablePoseDetection() async {
    try {
      await _channel.invokeMethod<void>('disablePoseDetection');

    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }
}