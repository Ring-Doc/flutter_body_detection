import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'body_detection_exception.dart';
import 'models/image_result.dart';
import 'models/pose.dart';
import 'models/body_mask.dart';
import 'png_image.dart';
import 'types.dart';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class BodyDetection {
  static StreamSubscription<dynamic>? _imageStreamSubscription;

  // Image
  late Interpreter _interpreter;
  
  Classifier({Interpreter? interpreter}) {
    loadModel(interpreter: interpreter);
  }

  static Future<Pose?> detectPose({required PngImage image}) async {
    final Uint32List pngImageBytes = image.bytes.buffer.asUint32List();
    try {
      late TensorImage inputImage;
      inputImage = TensorImage(TfLiteType.float32);
      
      final result = 0;
      return result == null ? null : Pose.fromMap(result);
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<BodyMask?> detectBodyMask({required PngImage image}) async {
    final Uint8List pngImageBytes = image.bytes.buffer.asUint8List();
    try {
      final result = await _channel.invokeMapMethod(
        'detectImageSegmentationMask',
        <String, dynamic>{
          'pngImageBytes': pngImageBytes,
        },
      );
      return result == null ? null : BodyMask.fromMap(result);
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
          // Selfie segmentation result
          else if (type == 'mask' && onMaskAvailable != null) {
            onMaskAvailable(
              result['mask'] == null ? null : BodyMask.fromMap(result['mask']),
            );
          }
        },
      );
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<void> stopCameraStream() async {
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
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<void> disablePoseDetection() async {
    try {
      await _channel.invokeMethod<void>('disablePoseDetection');
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<void> enableBodyMaskDetection() async {
    try {
      await _channel.invokeMethod<void>('enableBodyMaskDetection');
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static Future<void> disableBodyMaskDetection() async {
    try {
      await _channel.invokeMethod<void>('disableBodyMaskDetection');
    } on PlatformException catch (e) {
      throw BodyDetectionException(e.code, e.message);
    }
  }

  static image_lib.Image convertCameraImage(PngImage pngImage) {
    final int width = pngImage.width;
    final int height = pngImage.height;
  }

  loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            "model.tflite",
            options: InterpreterOptions()..threads = 4,
          );
    } catch (e) {
      print("Error while creating interpreter: $e");
    }

    // var outputTensors = interpreter.getOutputTensors();
    // var inputTensors = interpreter.getInputTensors();
    // List<List<int>> _outputShapes = [];

    // outputTensors.forEach((tensor) {
    //   print("Output Tensor: " + tensor.toString());
    //   _outputShapes.add(tensor.shape);
    // });
    // inputTensors.forEach((tensor) {
    //   print("Input Tensor: " + tensor.toString());
    // });

    // print("------------------[A}========================\n" +
    //     _outputShapes.toString());

    outputLocations = TensorBufferFloat([1, 1, 17, 3]);
  }
