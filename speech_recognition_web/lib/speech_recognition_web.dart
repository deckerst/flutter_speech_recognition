import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class SpeechRecognitionPlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel('speech_recognition', const StandardMethodCodec(), registrar.messenger);
    final SpeechRecognitionPlugin instance = SpeechRecognitionPlugin(channel);
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  MethodChannel speechChannel;

  SpeechRecognitionPlugin(MethodChannel channel) {
    this.speechChannel = channel;
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'speech.isSupported':
        return html.SpeechRecognition.supported;
      case 'speech.activate':
        return _activate();
      case 'speech.listen':
        final String locale = call.arguments['locale'];
        final int completeDelayMillis = call.arguments['completeDelayMillis'];
        return _listen(locale, completeDelayMillis);
      case 'speech.cancel':
        return _cancel();
      case 'speech.stop':
        return _stop();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: "The speech_recognition_web plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  html.SpeechRecognition _speech;

  bool _activate() {
    _speech = html.SpeechRecognition();
    _speech.onStart.listen(onSpeechRecognitionStart);
    _speech.onEnd.listen(onSpeechRecognitionEnd);
    _speech.onError.listen(onSpeechRecognitionError);
    _speech.onResult.listen(onSpeechRecognitionResult);
    return true;
  }

  bool _listen(String locale, int completeDelayMillis) {
    if (locale != null && locale.isNotEmpty) _speech.lang = locale;
    _speech.start();
    return true;
  }

  bool _cancel() {
    _speech.abort();
    return true;
  }

  bool _stop() {
    _speech.stop();
    return true;
  }

  onSpeechRecognitionStart(html.Event event) {
    speechChannel.invokeMethod('speech.onRecognitionStarted', null);
  }

  onSpeechRecognitionEnd(html.Event event) {
    speechChannel.invokeMethod('speech.onRecognitionComplete', null);
  }

  onSpeechRecognitionError(html.SpeechRecognitionError event) {
    speechChannel.invokeMethod('speech.onError', event.error);
  }

  onSpeechRecognitionResult(html.SpeechRecognitionEvent event) {
    final results = event.results;
    if (results == null || results.isEmpty) return;
    final result = results.first;
    if (result.length == 0) return;
    final alternative = result.item(0);
    speechChannel.invokeMethod('speech.onSpeech', alternative.transcript);
  }
}
