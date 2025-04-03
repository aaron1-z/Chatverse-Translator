import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_tts/flutter_tts.dart';

// Define callback types
typedef SpeakCompleteCallback = void Function();
typedef SpeakErrorCallback = void Function(String error);

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // --- Initialization ---
  // Call this once when setting up the service
  Future<void> initialize() async {
    // Basic setup, error handler is important
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      if (kDebugMode) print("TTS: Speaking Complete");
      // Notify listeners if needed using a callback passed to speak()
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (kDebugMode) print("TTS Error: $msg");
      // Notify listeners if needed
    });

     // Optional: Set await for completion (useful on iOS)
     if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        await _flutterTts.awaitSpeakCompletion(true);
     }

    _isInitialized = true;
    if (kDebugMode) print("TTS Service Initialized.");
  }

  // --- Properties ---
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  // --- Control Methods ---
  Future<void> speak(
      String text,
      {String language = "en-US", // Default language
      double volume = 1.0,
      double pitch = 1.0,
      double rate = 0.5, // 0.5 is normal speed
      SpeakCompleteCallback? onComplete, // Optional callback on completion
      SpeakErrorCallback? onError} // Optional callback on error
      ) async {

    if (!_isInitialized || text.isEmpty) {
      if (kDebugMode) print("TTS Warning: Not initialized or text is empty.");
      onError?.call("TTS not ready or text empty");
      return;
    }
    if (_isSpeaking) {
      // Option 1: Stop current speech and speak new text
      await stop();
      // Option 2: Queue (more complex, FlutterTts has basic queueing but might need manual management)
      // Option 3: Ignore new request (simple)
      if (kDebugMode) print("TTS Warning: Already speaking. Stopping previous and starting new.");
      // return; // Uncomment this for option 3
    }

    try {
      _isSpeaking = true;

      // Set language (important for correct pronunciation)
      // Check available languages using getLanguages() if needed
      await _flutterTts.setLanguage(language);
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0)); // Ensure volume is 0-1
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));   // Ensure pitch is 0.5-2
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0)); // Ensure rate is 0-1 (0.5 normal)

      // Set specific callbacks for this utterance
      if(onComplete != null) _flutterTts.setCompletionHandler((){ _isSpeaking = false; onComplete(); });
      if(onError != null) _flutterTts.setErrorHandler((msg){ _isSpeaking = false; onError(msg); });


      var result = await _flutterTts.speak(text);
      if (result == 1) {
        // Success (meaning speaking has started)
        if (kDebugMode) print("TTS: Speaking started for '$text'");
      } else {
        // Failure
        _isSpeaking = false;
         if (kDebugMode) print("TTS Error: speak command failed.");
         onError?.call("Speak command failed");
      }
    } catch (e) {
       _isSpeaking = false;
       if (kDebugMode) print("TTS Exception during speak: $e");
       onError?.call("Exception during speak: $e");
    }
  }

  Future<void> stop() async {
    if (!_isInitialized || !_isSpeaking) return;

    var result = await _flutterTts.stop();
    if (result == 1) {
       _isSpeaking = false;
       if (kDebugMode) print("TTS: Speaking stopped.");
    }
  }

  // --- Information Methods (Optional) ---
  Future<List<dynamic>> getLanguages() async {
     if (!_isInitialized) return [];
     try {
       // Returns a list of language strings (e.g., "en-US", "es-ES")
       return await _flutterTts.getLanguages;
     } catch(e) {
        if(kDebugMode) print("TTS Error getting languages: $e");
        return [];
     }
  }

   Future<List<dynamic>> getVoices() async {
      if (!_isInitialized) return [];
      try {
        // Returns a list of maps, each map representing a voice (name, locale)
        return await _flutterTts.getVoices;
      } catch(e) {
         if(kDebugMode) print("TTS Error getting voices: $e");
         return [];
      }
   }

   // Optional: Set a specific voice by name (requires knowing available voices)
   // Future<void> setVoice(String voiceName) async {
   //    if (!_isInitialized) return;
   //    await _flutterTts.setVoice({"name": voiceName, "locale": "some-locale"}); // Locale might be needed too
   // }

   // --- Dispose ---
   // Call this when the service is no longer needed (e.g., in dispose of a page/app)
   void dispose() {
      stop(); // Ensure TTS stops when service is disposed
      // Additional cleanup if necessary
       _isInitialized = false;
      if (kDebugMode) print("TTS Service Disposed.");
   }
}