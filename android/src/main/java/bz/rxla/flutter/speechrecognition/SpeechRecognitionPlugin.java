package bz.rxla.flutter.speechrecognition;

import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.util.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Locale;

/**
 * SpeechRecognitionPlugin
 */
public class SpeechRecognitionPlugin implements MethodCallHandler, RecognitionListener {

    private static final String LOG_TAG = "SpeechRecognitionPlugin";

    private SpeechRecognizer speech;
    private MethodChannel speechChannel;
    String transcription = "";
    private Intent recognizerIntent;
    private Activity activity;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "speech_recognition");
        channel.setMethodCallHandler(new SpeechRecognitionPlugin(registrar.activity(), channel));
    }

    private SpeechRecognitionPlugin(Activity activity, MethodChannel channel) {
        this.speechChannel = channel;
        this.speechChannel.setMethodCallHandler(this);
        this.activity = activity;

        speech = SpeechRecognizer.createSpeechRecognizer(activity.getApplicationContext());
        speech.setRecognitionListener(this);

        recognizerIntent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("speech.activate")) {
            // we assume that speech recognition permission is declared in the manifest and accepted during installation (AndroidSDK 21+)
            result.success(true);
            speechChannel.invokeMethod("speech.onCurrentLocale", getContextLocale().toString());
        } else if (call.method.equals("speech.listen")) {
            String locale = call.argument("locale");
            recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, getLocale(locale));

            int completeDelayMillis = call.argument("completeDelayMillis");
            recognizerIntent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, completeDelayMillis);
            recognizerIntent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, completeDelayMillis);
            recognizerIntent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, completeDelayMillis);

            speech.startListening(recognizerIntent);
            result.success(true);
        } else if (call.method.equals("speech.cancel")) {
            speech.stopListening();
            result.success(true);
        } else if (call.method.equals("speech.stop")) {
            speech.stopListening();
            result.success(true);
        } else {
            result.notImplemented();
        }
    }

    @SuppressWarnings("deprecation")
    private Locale getContextLocale() {
        Configuration config = activity.getResources().getConfiguration();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return config.getLocales().get(0);
        }
        return config.locale;
    }

    private Locale getLocale(String code) {
        String[] localeParts = code.split("_");
        return localeParts.length > 1 ? new Locale(localeParts[0], localeParts[1]) : new Locale(localeParts[0]);
    }

    private void sendTranscription(Bundle results, boolean isFinal) {
        ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
        if (matches.size() > 0) {
            String match = matches.get(0);
            if (match != null && !match.isEmpty() && !match.equals(transcription)) {
                transcription = match;
                if (isFinal) {
                    speechChannel.invokeMethod("speech.onRecognitionComplete", transcription);
                } else {
                    speechChannel.invokeMethod("speech.onSpeech", transcription);
                }
            }
        }
    }

    // RecognitionListener

    @Override
    public void onBeginningOfSpeech() {
        Log.d(LOG_TAG, "onRecognitionStarted");
        transcription = "";
        speechChannel.invokeMethod("speech.onRecognitionStarted", null);
    }

    @Override
    public void onEndOfSpeech() {
        Log.d(LOG_TAG, "onEndOfSpeech");
        speechChannel.invokeMethod("speech.onRecognitionComplete", transcription);
    }

    @Override
    public void onError(int error) {
        Log.d(LOG_TAG, "onError with error=" + error);
        speechChannel.invokeMethod("speech.onSpeechAvailability", false);
        String errorString;
        switch(error) {
            case 1: errorString = "ERROR_NETWORK_TIMEOUT"; break;
            case 2: errorString = "ERROR_NETWORK"; break;
            case 3: errorString = "ERROR_AUDIO"; break;
            case 4: errorString = "ERROR_SERVER"; break;
            case 5: errorString = "ERROR_CLIENT"; break;
            case 6: errorString = "ERROR_SPEECH_TIMEOUT"; break;
            case 7: errorString = "ERROR_NO_MATCH"; break;
            case 8: errorString = "ERROR_RECOGNIZER_BUSY"; break;
            case 9: errorString = "ERROR_INSUFFICIENT_PERMISSIONS"; break;
            default: errorString = "UNKNOWN_CODE_" + error; break;
        }
        speechChannel.invokeMethod("speech.onError", errorString);
    }

    @Override
    public void onReadyForSpeech(Bundle params) {
        Log.d(LOG_TAG, "onReadyForSpeech");
        speechChannel.invokeMethod("speech.onSpeechAvailability", true);
    }

    @Override
    public void onPartialResults(Bundle results) {
        sendTranscription(results, false);
    }

    @Override
    public void onResults(Bundle results) {
        sendTranscription(results, true);
    }

    @Override
    public void onBufferReceived(byte[] buffer) {}

    @Override
    public void onRmsChanged(float rmsdB) {}

    @Override
    public void onEvent(int eventType, Bundle params) {
        Log.d(LOG_TAG, "onEvent with eventType=" + eventType);
    }
}
