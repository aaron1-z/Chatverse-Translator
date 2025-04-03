import 'package:flutter/foundation.dart'; // For kDebugMode
// Import the google_generative_ai package
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // --- API Key Handling ---
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // --- Gemini Model ---
  // Make the model variable nullable, we initialize it in the constructor
  GenerativeModel? _model;

  // --- Constructor ---
  GeminiService() {
    if (_apiKey.isEmpty) {
      // Only print in debug mode to avoid noise in production logs
      if (kDebugMode) {
        print("----------------------------------------------------------");
        print("ERROR: GEMINI_API_KEY is not set.");
        print("Please run the app using:");
        print("flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY");
        print("----------------------------------------------------------");
      }
      // Don't initialize the model if the key is missing
    } else {
      // Initialize the GenerativeModel
      try {
         _model = GenerativeModel(
           // Specify the model name.
           // Check Google AI documentation for available models.
           // 'gemini-pro' is a common choice for text tasks.
           // Use 'gemini-1.5-flash-latest' or 'gemini-1.5-pro-latest' if available and preferred.
           // Update to 'gemini-2.5-pro' when it's officially released and named.
           model: 'gemini-1.5-flash-latest', // Using Flash for potentially faster responses
           apiKey: _apiKey,
           // Optional: Add safety settings if needed
           // safetySettings: [ SafetySetting(...) ],
           // Optional: Add generation config if needed
           // generationConfig: GenerationConfig(
           //   temperature: 0.7, // Example: control creativity
           // ),
         );
         if (kDebugMode) {
           print("GeminiService: Model initialized successfully with API Key.");
         }
      } catch (e) {
         if (kDebugMode) {
           print("Error initializing Gemini Model: $e");
         }
         // Handle initialization error (e.g., invalid key format)
         _model = null;
      }
    }
  }

  // --- Check if Ready ---
  // Helper to check if the service is ready to make calls
  bool isReady() {
    return _model != null;
  }

  // --- Translation Method ---
  Future<String?> translateText({
    required String textToTranslate,
    String sourceLanguage = "auto", // Let Gemini attempt auto-detection
    required String targetLanguage,
  }) async {
    // Check if the model was initialized successfully
    if (_model == null) {
      if (kDebugMode) {
        print("Error: Gemini model not initialized (API Key missing or init failed?). Cannot translate.");
      }
      return "Error: Translation service not ready."; // Or return null
    }
    if (textToTranslate.trim().isEmpty) {
      return ""; // Don't call API for empty text
    }

    // Construct a clear prompt for the AI model
    // Including "Strictly return only the translated text." helps reduce extra conversational output.
    final prompt = '''Translate the following text from $sourceLanguage to $targetLanguage. Strictly return only the translated text, without any additional explanations or introductions:

    Input Text:
    ```
    $textToTranslate
    ```

    Translated Text:''';

    if (kDebugMode) {
      print("--- Sending Prompt to Gemini ---");
      print(prompt);
      print("---------------------------------");
    }

    try {
      // Create the content object for the API call
      final content = [Content.text(prompt)];

      // Record start time for latency measurement (optional)
      final startTime = DateTime.now();

      // Call the Gemini API
      final response = await _model!.generateContent(content);

      // Record end time and calculate duration (optional)
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      if (kDebugMode) {
         print("Gemini API call duration: ${duration.inMilliseconds}ms");
      }

      // --- Process the Response ---
      if (response.text != null) {
        if (kDebugMode) {
          print("--- Gemini Raw Response ---");
          print(response.text);
          print("--------------------------");
        }
        // Trim potential whitespace from the result
        return response.text!.trim();
      } else {
        if (kDebugMode) {
          print("Error: Gemini response text is null.");
          // You could inspect response.promptFeedback or response.candidates here for more details
          print("Prompt Feedback: ${response.promptFeedback}");
        }
        return "Error: Received no translation from API."; // Indicate failure
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling Gemini API: $e");
        // Log the specific error type if needed
      }
      // Handle specific exceptions if needed (e.g., API errors, network errors)
      return "Error: API call failed (${e.runtimeType})"; // Indicate failure
    }
  }
}