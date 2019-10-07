#import "SpeechRecognitionPlugin.h"
#import <speech_recognition/speech_recognition-Swift.h>

@implementation SpeechRecognitionPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (@available(iOS 10.0, *)) {
        [SwiftSpeechRecognitionPlugin registerWithRegistrar:registrar];
    } else {
        // Fallback on earlier versions
    }
}
@end
