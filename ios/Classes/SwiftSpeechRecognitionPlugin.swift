import Flutter
import UIKit
import Speech

@available(iOS 10.0, *)
public class SwiftSpeechRecognitionPlugin: NSObject, FlutterPlugin, SFSpeechRecognizerDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "speech_recognition", binaryMessenger: registrar.messenger())
    let instance = SwiftSpeechRecognitionPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let speechRecognizerEn = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
  private let speechRecognizerFr = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))!
  private let speechRecognizerIt = SFSpeechRecognizer(locale: Locale(identifier: "it-IT"))!
  private let speechRecognizerKo = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))!
  private let speechRecognizerRu = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))!

  private var speechChannel: FlutterMethodChannel?

  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

  private var recognitionTask: SFSpeechRecognitionTask?

  private let audioEngine = AVAudioEngine()

  init(channel:FlutterMethodChannel){
    speechChannel = channel
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    //result("iOS " + UIDevice.current.systemVersion)
    switch (call.method) {
    case "speech.activate":
      self.activateRecognition(result: result)

    case "speech.listen":
      guard let args = call.arguments as? [String: Any] else {
        fatalError("args are formatted badly")
      }
      let lang = args["locale"] as! String
      self.startRecognition(lang: lang, result: result)

    case "speech.cancel":
      self.cancelRecognition(result: result)

    case "speech.stop":
      self.stopRecognition(result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func activateRecognition(result: @escaping FlutterResult) {
    speechRecognizerEn.delegate = self
    speechRecognizerFr.delegate = self
    speechRecognizerIt.delegate = self
    speechRecognizerKo.delegate = self
    speechRecognizerRu.delegate = self

    SFSpeechRecognizer.requestAuthorization { authStatus in
      OperationQueue.main.addOperation {
        switch authStatus {
        case .authorized:
          result(true)
          self.speechChannel?.invokeMethod("speech.onCurrentLocale", arguments: Locale.preferredLanguages.first)

        case .denied:
          result(false)

        case .restricted:
          result(false)

        case .notDetermined:
          result(false)
        }
        print("SFSpeechRecognizer.requestAuthorization \(authStatus.rawValue)")
      }
    }
  }

  private func startRecognition(lang: String, result: FlutterResult) {
    print("startRecognition...")
    if audioEngine.isRunning {
      audioEngine.stop()
      recognitionRequest?.endAudio()
      result(false)
    } else {
      try! start(lang: lang)
      result(true)
    }
  }

  private func cancelRecognition(result: FlutterResult?) {
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
      if let r = result {
        r(false)
      }
    }
  }

  private func stopRecognition(result: FlutterResult) {
    print("stopRecognition...")
    if audioEngine.isRunning {
      audioEngine.stop()
      recognitionRequest?.endAudio()
    }
    result(false)
  }

  private func start(lang: String) throws {

    cancelRecognition(result: nil)

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
    // AVAudioSessionModeVoiceChat: recognition fails with [avae] AVAEInternal.h:70:_AVAE_Check: required condition is false: [AVAudioIONodeImpl.mm:911:SetOutputFormat: (format.sampleRate == hwFormat.sampleRate)]
    // AVAudioSessionModeSpokenAudio: recognition works, but not right after TTS
    try audioSession.setMode(AVAudioSessionModeSpokenAudio)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

    let inputNode = audioEngine.inputNode
    guard let recognitionRequest = recognitionRequest else {
      fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
    }
    
    let avSampleRate = AVAudioSession.sharedInstance().sampleRate
    print("sampleRate from AVAudioSession: \(avSampleRate)")
    let inputNodeSampleRate = inputNode.inputFormat(forBus: 0).sampleRate
    print("sampleRate from inputNode: \(inputNodeSampleRate)")
    let outputNode = audioEngine.outputNode
    let outputNodeSampleRate = outputNode.outputFormat(forBus: 0).sampleRate
    print("sampleRate from outputNode: \(outputNodeSampleRate)")

    recognitionRequest.shouldReportPartialResults = true

    let speechRecognizer = getRecognizer(lang: lang)

    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
      var isFinal = false

      if let result = result {
        print("Speech : \(result.bestTranscription.formattedString)")
        self.speechChannel?.invokeMethod("speech.onSpeech", arguments: result.bestTranscription.formattedString)
        isFinal = result.isFinal
        if isFinal {
          self.speechChannel!.invokeMethod(
             "speech.onRecognitionComplete",
             arguments: result.bestTranscription.formattedString
          )
        }
      }

      if error != nil || isFinal {
        self.audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        self.recognitionRequest = nil
        self.recognitionTask = nil
      }
    }

    let recognitionFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recognitionFormat) {
      (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
      self.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()

    speechChannel!.invokeMethod("speech.onRecognitionStarted", arguments: nil)
  }

  private func getRecognizer(lang: String) -> Speech.SFSpeechRecognizer {
    switch (lang) {
    case "fr-FR":
      return speechRecognizerFr
    case "it-IT":
      return speechRecognizerIt
    case "ko-KR":
      return speechRecognizerKo
    case "ru-RU":
      return speechRecognizerRu
    default:
      return speechRecognizerEn
    }
  }

  public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    if available {
      speechChannel?.invokeMethod("speech.onSpeechAvailability", arguments: true)
    } else {
      speechChannel?.invokeMethod("speech.onSpeechAvailability", arguments: false)
    }
  }
}
