import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

// Define callback types for clarity
typedef SpeechResultCallback = void Function(String text);
typedef SpeechErrorCallback = void Function(String error);
typedef SpeechStatusCallback = void Function(String status);

class SpeechToTextService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  // --- Initialization ---
  Future<bool> initialize() async {
    // Request microphone permission first
    var status = await Permission.microphone.request();
    if (!status.isGranted && !kIsWeb) { // kIsWeb check might be needed if running on web
      if (kDebugMode) {
        print("STT Error: Microphone permission denied.");
      }
      _isAvailable = false;
      return false;
    }

    // On iOS/macOS, speech recognition permission is also needed
    // Add platform checks if necessary, e.g., using Platform.isIOS
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
        status = await Permission.speech.request();
         if (!status.isGranted) {
            if (kDebugMode) {
               print("STT Error: Speech recognition permission denied.");
            }
           _isAvailable = false;
           return false;
         }
    }

    // Initialize the speech_to_text plugin
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (errorNotification) {
          if (kDebugMode) {
            print("STT Initialization Error: ${errorNotification.errorMsg}");
          }
          _isAvailable = false; // Mark as unavailable on error
        },
        onStatus: (status) {
          if (kDebugMode) {
            print("STT Status: $status");
          }
        },
      );
    } catch (e) {
       if (kDebugMode) {
         print("STT Exception during initialization: $e");
       }
       _isAvailable = false;
    }

    if (kDebugMode) {
      print("STT Service Initialized. Available: $_isAvailable");
    }
    return _isAvailable;
  }

  // --- Properties ---
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  // --- Control Methods (For Microphone Input) ---
  void startListening({
    required SpeechResultCallback onResult,
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatusUpdate,
    String localeId = 'en_US',
  }) {
    if (!_isAvailable || _isListening) {
      if (kDebugMode) {
        print("STT Warning: Cannot start listening. Available: $_isAvailable, Listening: $_isListening");
      }
      onError(_isAvailable ? "Already listening" : "STT Service not available");
      return;
    }

    _isListening = true;
    onStatusUpdate("listening");

    _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
           onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      cancelOnError: true,
      partialResults: false,
      listenMode: stt.ListenMode.confirmation,
    ).catchError((error) {
      if (kDebugMode) {
        print("STT Listening Error: $error");
      }
      onError("Listening error: $error");
      _isListening = false;
      onStatusUpdate("error");
    });

    _speechToText.statusListener = (status) {
        if (kDebugMode) {
           print("STT Runtime Status: $status");
        }
        bool previousListeningState = _isListening;
        _isListening = status == stt.SpeechToText.listeningStatus;
        if(previousListeningState != _isListening) { // Only update if state changed
           onStatusUpdate(status);
        }

        if (status == stt.SpeechToText.notListeningStatus || status == stt.SpeechToText.doneStatus) {
             _isListening = false;
             // Ensure final status update if needed
             if(previousListeningState) onStatusUpdate(status);
        }
    };
  }

  void stopListening({required SpeechStatusCallback onStatusUpdate}) {
    if (!_isListening) return;

    _speechToText.stop().then((_) {
       // It's better to rely on the status listener, but provide immediate feedback
       if (_isListening) { // Check if still marked as listening
           _isListening = false;
           onStatusUpdate("notListening");
       }
    });
    // Don't set _isListening false immediately, wait for status listener confirmation
    if (kDebugMode) {
      print("STT Stop Listening called.");
    }
  }

  void cancelListening({required SpeechStatusCallback onStatusUpdate}) {
     if (!_isListening) return;

    _speechToText.cancel().then((_) {
       // It's better to rely on the status listener, but provide immediate feedback
       if (_isListening) { // Check if still marked as listening
          _isListening = false;
          onStatusUpdate("notListening");
       }
    });
    // Don't set _isListening false immediately, wait for status listener confirmation
    if (kDebugMode) {
      print("STT Cancel Listening called.");
    }
  }

  // --- Locale Information ---
  Future<List<stt.LocaleName>> getLocales() async {
    // No need to check _isAvailable here, initialize should handle it
    try {
       if (!_speechToText.isAvailable) {
          bool success = await initialize();
          if (!success) return [];
       }
       return await _speechToText.locales();
    } catch (e) {
       if (kDebugMode) print("Error fetching locales: $e");
       return [];
    }
  }

  // --- REMOVED INCORRECT transcribeAudioFile METHOD ---
  // Future<String> transcribeAudioFile(String audioFilePath) async { ... }
}