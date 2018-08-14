import 'dart:async';

import 'dart:ui';
import 'package:flutter/services.dart';

typedef void AvailabilityHandler(bool result);
typedef void StringResultHandler(String text);

/// the channel to control the speech recognition
class SpeechRecognition {
  static const MethodChannel _channel = const MethodChannel('speech_recognition');

  static final SpeechRecognition _speech = new SpeechRecognition._internal();

  factory SpeechRecognition() => _speech;

  SpeechRecognition._internal() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  AvailabilityHandler availabilityHandler;

  StringResultHandler errorHandler;
  StringResultHandler currentLocaleHandler;
  StringResultHandler recognitionResultHandler;

  VoidCallback recognitionStartedHandler;
  VoidCallback recognitionCompleteHandler;

  /// ask for speech recognizer permission
  Future activate() => _channel.invokeMethod("speech.activate");

  /// start listening
  Future listen({String locale, int completeDelayMillis}) => _channel.invokeMethod("speech.listen", {
        'locale': locale,
        'completeDelayMillis': completeDelayMillis
      });

  Future cancel() => _channel.invokeMethod("speech.cancel");

  Future stop() => _channel.invokeMethod("speech.stop");

  Future _platformCallHandler(MethodCall call) async {
    print("_platformCallHandler call ${call
            .method} ${call
            .arguments}");
    switch (call.method) {
      case "speech.onSpeechAvailability":
        availabilityHandler(call.arguments);
        break;
      case "speech.onCurrentLocale":
        currentLocaleHandler(call.arguments);
        break;
      case "speech.onSpeech":
        recognitionResultHandler(call.arguments);
        break;
      case "speech.onRecognitionStarted":
        recognitionStartedHandler();
        break;
      case "speech.onRecognitionComplete":
        recognitionCompleteHandler();
        break;
      case "speech.onError":
        errorHandler(call.arguments);
        break;
      default:
        print('Unknown method ${call
                .method}');
    }
  }

  // define a method to handle availability / permission result
  void setAvailabilityHandler(AvailabilityHandler handler) => availabilityHandler = handler;

  // define a method to handle recognition result
  void setRecognitionResultHandler(StringResultHandler handler) => recognitionResultHandler = handler;

  // define a method to handle native call
  void setRecognitionStartedHandler(VoidCallback handler) => recognitionStartedHandler = handler;

  // define a method to handle native call
  void setRecognitionCompleteHandler(VoidCallback handler) => recognitionCompleteHandler = handler;

  void setCurrentLocaleHandler(StringResultHandler handler) => currentLocaleHandler = handler;

  void setErrorHandler(StringResultHandler handler) => errorHandler = handler;
}
