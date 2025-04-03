import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart'; // Comment out for now
import 'package:provider/provider.dart';

// Import the services
import 'services/gemini_service.dart';
import 'services/speech_to_text_service.dart';
import 'services/text_to_speech_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: MaterialApp(
        title: 'Chatverse Translator',
        theme: ThemeData( // --- Light Theme --- (Keep as is)
          brightness: Brightness.light,
          primaryColor: const Color(0xFF795548),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF795548), brightness: Brightness.light),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF795548)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              backgroundColor: const Color(0xFF795548),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 5,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF795548),
            foregroundColor: Colors.white,
            elevation: 5,
            sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF795548),
            contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
            actionTextColor: Colors.white,
            elevation: 8,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 3,
            centerTitle: true,
          ),
        ),
        darkTheme: ThemeData( // --- Dark Theme --- (Keep as is)
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFBCAAA4),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBCAAA4), brightness: Brightness.dark),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFBCAAA4)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[800],
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              backgroundColor: const Color(0xFFBCAAA4),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 5,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFBCAAA4),
            foregroundColor: Colors.black87,
            elevation: 5,
            sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFFBCAAA4),
            contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
            actionTextColor: Colors.black87,
            elevation: 8,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 3,
            centerTitle: true,
          ),
        ),
        themeMode: _themeMode,
        home: TranslationPage(
          onThemeModeChanged: (ThemeMode mode) {
            setState(() {
              _themeMode = mode;
            });
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class TranslationPage extends StatefulWidget {
  const TranslationPage({Key? key, required this.onThemeModeChanged}) : super(key: key);

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextService _sttService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  late AnimationController _micAnimationController;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TranslationProvider>(context, listen: false)
          .initializeServices(_sttService, _ttsService, context);
    });

    // --- Comment out Share Sheet listeners FOR NOW ---
    /*
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
       if (value.isNotEmpty && mounted) {
         final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
         // Replace with actual file transcription call when ready
         print("Received shared file: ${value.first.path}");
         translationProvider.showSnackbar("Shared file received (transcription pending)", context: context);
         // translationProvider.processSharedAudio(File(value.first.path), _sttService, context)
         //   .then((transcribedText) {
         //      if (transcribedText != null && mounted) {
         //         _textController.text = transcribedText;
         //      }
         //    });
       }
     }, onError: (err) {
       print("getIntentDataStream error: $err");
       if (mounted) {
          Provider.of<TranslationProvider>(context, listen: false).showSnackbar('Error receiving shared file', isError: true, context: context);
       }
     });

    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
       if (value.isNotEmpty && mounted) {
         final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
         // Replace with actual file transcription call when ready
          print("Received initial shared file: ${value.first.path}");
          translationProvider.showSnackbar("Shared file received (transcription pending)", context: context);
         // translationProvider.processSharedAudio(File(value.first.path), _sttService, context)
         //   .then((transcribedText) {
         //      if (transcribedText != null && mounted) {
         //         _textController.text = transcribedText;
         //      }
         //    });
       }
     });
     */
  }

  @override
  void dispose() {
    _textController.dispose();
    _micAnimationController.dispose();
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationProvider = Provider.of<TranslationProvider>(context);

    // Sync TextField with Provider (carefully)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _textController.text != translationProvider.textControllerValue) {
        final currentSelection = _textController.selection;
        _textController.text = translationProvider.textControllerValue;
        // Try to restore cursor position
        try {
           _textController.selection = TextSelection.fromPosition(TextPosition(offset: currentSelection.baseOffset.clamp(0, _textController.text.length)));
        } catch (e) {
            _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        }
      }
    });

    return Scaffold(
      appBar: AppBar( /* ... AppBar code ... */
         title: Text('Chatverse Translator', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              widget.onThemeModeChanged(
                Theme.of(context).brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // --- Input Area ---
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter text or tap mic',
                hintText: 'Type or paste text...',
                suffixIcon: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
                    parent: _micAnimationController,
                    curve: Curves.easeInOut,
                  )),
                  child: IconButton(
                    onPressed: (translationProvider.isSttAvailable)
                        ? (translationProvider.isListening ? translationProvider.stopListening : translationProvider.startListening)
                        : null,
                    tooltip: translationProvider.isListening ? 'Stop Listening' : 'Start Listening',
                    icon: Icon(translationProvider.isListening ? Icons.stop : Icons.mic, size: 28),
                    color: translationProvider.isListening ? Colors.redAccent : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              maxLines: 5,
              minLines: 3,
              onChanged: (text) => translationProvider.setTextController(text),
            ),
            Padding( /* ... STT Status Text ... */
               padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                translationProvider.sttStatus,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            // --- REMOVED Shared Audio Debug Text ---
            // if (translationProvider.sharedAudioFile != null) ...
            const SizedBox(height: 24),

            // --- Language Selector --- (Keep as is)
             Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text("Translate to:", style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: translationProvider.targetLanguage,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 32,
                        elevation: 16,
                        style: TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 18),
                        dropdownColor: Theme.of(context).inputDecorationTheme.fillColor,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            translationProvider.setTargetLanguage(newValue);
                          }
                        },
                        items: TranslationProvider.supportedLanguages
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // --- Translate Button --- (Keep as is)
             ElevatedButton(
              onPressed: translationProvider.isLoadingTranslation ? null : () {
                 // Use the text from the local controller for translation
                _performTranslation(context, _textController.text);
              },
              child: translationProvider.isLoadingTranslation
                  ? const SizedBox(
                      height: 32, width: 32,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('Translate Text'),
            ),
            const SizedBox(height: 16),

            // --- Result Area --- (Keep as is)
              Text(
              'Translation Result:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 60, 24),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 140),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[850],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    translationProvider.isLoadingTranslation
                        ? 'Translating...'
                        : (translationProvider.translatedText.isEmpty && translationProvider.translationError.isEmpty )
                            ? 'Translation will appear here...'
                            : translationProvider.translatedText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 28),
                        tooltip: 'Copy Translation',
                        color: Theme.of(context).primaryColor,
                        // Use the public method from provider
                        onPressed: translationProvider.translatedText.isNotEmpty ? translationProvider.copyToClipboard : null,
                      ),
                      IconButton(
                        // Use the public getter 'isSpeaking'
                        icon: Icon(translationProvider.isSpeaking ? Icons.volume_off : Icons.volume_up, size: 28),
                        tooltip: translationProvider.isSpeaking ? 'Stop Speaking' : 'Speak Translation',
                        color: Theme.of(context).primaryColor,
                        onPressed: (translationProvider.isTtsInitialized && translationProvider.translatedText.isNotEmpty && translationProvider.translationError.isEmpty)
                            // Use the public methods from provider
                            ? (translationProvider.isSpeaking ? translationProvider.stopSpeaking : translationProvider.speakTranslatedText)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // --- Error Display --- (Keep as is)
             if (translationProvider.translationError.isNotEmpty && !translationProvider.isLoadingTranslation)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  translationProvider.translationError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _performTranslation(BuildContext context, String text) async {
     final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
    if (text.trim().isEmpty) {
      translationProvider.showSnackbar('Please enter text to translate', context: context);
      return;
    }
    if (!translationProvider.geminiService.isReady()) {
       translationProvider.showSnackbar('Translation Service not ready. Check API Key.', isError: true, context: context);
      return;
    }

    translationProvider.setLoadingTranslation(true);

    try {
      final result = await translationProvider.geminiService.translateText(
        textToTranslate: text,
        targetLanguage: translationProvider.targetLanguage,
      );

      if (mounted) { // Check if widget is still mounted
         translationProvider.setTranslatedText(result!);
      }
    } catch (e) {
       if (mounted) { // Check if widget is still mounted
          translationProvider.setTranslationError('An unexpected error occurred: ${e.toString()}');
          translationProvider.showSnackbar(translationProvider.translationError, isError: true, context: context);
       }
    } finally {
       if (mounted) { // Check if widget is still mounted
          translationProvider.setLoadingTranslation(false);
       }
    }
  }
}

class TranslationProvider extends ChangeNotifier {
  // --- Services ---
  final GeminiService _geminiService = GeminiService();
  SpeechToTextService? _sttService; // Make nullable
  TextToSpeechService? _ttsService; // Make nullable

  // --- State Variables ---
  String _translatedText = '';
  bool _isLoadingTranslation = false;
  String _targetLanguage = 'Spanish';
  static const List<String> supportedLanguages = [
    'Spanish', 'French', 'German', 'Japanese', 'Chinese', 'Hindi', 'Arabic', 'Portuguese', 'Russian', 'Italian', 'English'
  ];
  String? _translationError;

  // --- STT State ---
  bool _isSttAvailable = false;
  bool _isListening = false;
  String _sttStatus = 'Not listening';
  List<dynamic> _sttLocales = [];
  // --- TTS State ---
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  String _textControllerValue = '';
  File? _sharedAudioFile;
  static const Map<String, String> languageLocaleMap = {
    'English': 'en-US', 'Spanish': 'es-ES', 'French': 'fr-FR', 'German': 'de-DE',
    'Japanese': 'ja-JP', 'Chinese': 'zh-CN', 'Hindi': 'hi-IN', 'Arabic': 'ar-SA',
    'Portuguese': 'pt-BR', 'Russian': 'ru-RU', 'Italian': 'it-IT',
  };

  // --- Getters ---
  String get translatedText => _translatedText;
  bool get isLoadingTranslation => _isLoadingTranslation;
  bool get isTtsInitialized => _isTtsInitialized;
  bool get isSttAvailable => _isSttAvailable;
  String get sttStatus => _sttStatus;
  List<dynamic> get sttLocales => _sttLocales;
  String get targetLanguage => _targetLanguage;
  String get translationError => _translationError ?? '';
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening; // Correct getter
  File? get sharedAudioFile => _sharedAudioFile;
  String get textControllerValue => _textControllerValue;
  GeminiService get geminiService => _geminiService;


  // --- Setters ---
  void setTextController(String text) {
    if (_textControllerValue != text) {
      _textControllerValue = text;
      notifyListeners();
    }
  }

  void setTranslatedText(String text) {
    _translatedText = text;
    _translationError = null;
    notifyListeners();
  }

  void setLoadingTranslation(bool loading) {
    _isLoadingTranslation = loading;
    notifyListeners();
  }

  void setTranslationError(String error) {
    _translationError = error;
    _translatedText = '';
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    _targetLanguage = language;
    notifyListeners();
  }

  // Internal setters
  void _setSttAvailable(bool available) {
    _isSttAvailable = available;
    notifyListeners();
  }

  void _setSttLocales(List<dynamic> locales) {
    _sttLocales = locales;
    notifyListeners();
  }

  void _setTtsInitialized(bool initialized) {
    _isTtsInitialized = initialized;
    notifyListeners();
  }

  // --- Service Initialization ---
  Future<void> initializeServices(SpeechToTextService sttService, TextToSpeechService ttsService, BuildContext context) async {
    _sttService = sttService;
    _ttsService = ttsService;
    try {
      bool sttReady = await _sttService!.initialize();
      _setSttAvailable(sttReady);
      if (sttReady) {
        _setSttLocales(await _sttService!.getLocales());
      } else if (context.mounted) {
         showSnackbar('Speech recognition not available.', isError: true, context: context);
      }

      await _ttsService!.initialize(); // Assuming initialize returns Future<void> or similar
      _setTtsInitialized(_ttsService!.isInitialized); // Check property after awaiting initialization
       if (!_ttsService!.isInitialized && context.mounted) {
         showSnackbar('Text-to-Speech not available.', isError: true, context: context);
       }

    } catch (e) {
      print("Error initializing services: $e");
      if (context.mounted) {
         showSnackbar('Error initializing services: $e', isError: true, context: context);
      }
    }
  }


  // --- STT Logic ---
  void startListening() {
    if (!_isSttAvailable || _isListening || _sttService == null) return;

    const String inputLocale = 'en_US';
    _sttService!.startListening(
      localeId: inputLocale,
      onResult: (text) {
        setTextController(text); // Use setter to notify listeners
        _sttStatus = 'Recognized successfully';
        _isListening = false;
        notifyListeners();
      },
      onError: (error) {
        _sttStatus = 'Error: $error';
        _isListening = false;
        notifyListeners();
      },
      onStatusUpdate: (status) {
        _sttStatus = status;
        _isListening = status == 'listening';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    if (!_isListening || _sttService == null) return;
    _sttService!.stopListening(onStatusUpdate: (status) {
      // The status listener within startListening should handle setting _isListening=false
      // We just update the status string here if needed, or let the listener do it.
      _sttStatus = status;
      // _isListening = false; // Let the status listener handle this ideally
      notifyListeners();
    });
  }


  // --- Helper Function for Showing Snackbars ---
  void showSnackbar(String message, {bool isError = false, required BuildContext context}) {
    // Check if the context is still valid before showing the snackbar
    if (context.mounted) {
       ScaffoldMessenger.of(context).hideCurrentSnackBar();
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(message),
           backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           duration: Duration(seconds: isError ? 4 : 2),
         ),
       );
     } else {
        print("Snackbar suppressed: Context is not mounted. Message: $message");
     }
  }

  // --- Share Sheet Logic (Placeholder - Requires Correct Implementation) ---
   Future<String?> processSharedAudio(File audioFile, SpeechToTextService sttService, BuildContext context) async {
     _sharedAudioFile = audioFile;
     _sttStatus = 'Processing shared audio...';
     notifyListeners();

     // --- THIS IS WHERE YOU'LL CALL YOUR *ACTUAL* FILE TRANSCRIPTION METHOD ---
     // Replace the following placeholder with your chosen implementation
     // e.g., using Google Cloud Speech-to-Text or another service.

     try {
        // Example placeholder - replace with real transcription logic
        showSnackbar("Audio file transcription not implemented yet.", context: context, isError: true);
        print("Placeholder: Would transcribe ${audioFile.path}");
        await Future.delayed(Duration(seconds: 1)); // Simulate work
        String transcribedText = "Transcription for ${audioFile.path.split('/').last} (Not Implemented)";


        setTextController(transcribedText); // Update internal value
        _sttStatus = 'Audio processed (Placeholder)';
        _sharedAudioFile = null; // Clear after processing
        notifyListeners();
        return transcribedText; // Return the text to update TextField

     } catch (e) {
       _sttStatus = 'Error processing audio: ${e.toString()}';
       _sharedAudioFile = null; // Clear on error
       notifyListeners();
       print('Error processing audio: $e');
       showSnackbar('Error processing audio.', isError: true, context: context);
       return null;
     }
   }

  // --- TTS Logic ---
  Future<void> speakTranslatedText() async {
    if (!_isTtsInitialized || _translatedText.isEmpty || _isSpeaking || _ttsService == null) {
       print("TTS condition not met: Initialized=$_isTtsInitialized, Text='$_translatedText', Speaking=$_isSpeaking, Service=${_ttsService != null}");
       return;
    }

    String? targetLocale = languageLocaleMap[targetLanguage];
    if (targetLocale == null) {
      print("TTS Error: Locale not found for $targetLanguage");
      // showSnackbar("TTS not supported for $targetLanguage", isError: true, context: context); // Need context
      return;
    }

    _isSpeaking = true;
    notifyListeners();
    try {
      await _ttsService!.speak(
        _translatedText,
        language: targetLocale,
        onComplete: () {
          _isSpeaking = false;
          notifyListeners();
        },
        onError: (error) {
          _isSpeaking = false;
          notifyListeners();
          print('TTS Error: $error');
          // showSnackbar("TTS Error: $error", isError: true, context: context); // Need context
        }
      );
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      print('TTS Exception: $e');
      // showSnackbar("TTS Exception: $e", isError: true, context: context); // Need context
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking || _ttsService == null) return;
    try {
       await _ttsService!.stop();
    } catch (e) {
       print("Error stopping TTS: $e");
    } finally {
       _isSpeaking = false; // Ensure state is reset
       notifyListeners();
    }
  }

  // --- Clipboard Logic ---
  Future<void> copyToClipboard() async {
    if (_translatedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _translatedText));
      // Optional: Show feedback via snackbar if context is available
      // showSnackbar('Copied to clipboard!', context: context);
    } else {
      // Optional: Show feedback via snackbar if context is available
      // showSnackbar('Nothing to copy', isError: true, context: context);
    }
    // notifyListeners(); // Not strictly needed as no state changed visually
  }
}