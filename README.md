# Chatverse Translator

A standalone AI-powered voice and text translation application built with Flutter. Translate text or use your voice with selectable input languages, leveraging the power of Google's Gemini API.

## Features

*   **Text Translation:** Enter text manually and translate it to various target languages.
*   **Voice Input (Speech-to-Text):** Speak into the microphone for translation.
*   **Selectable Input Language:** Choose the language you are speaking from a device-supported list for accurate STT recognition.
*   **Selectable Target Language:** Choose the language you want the text translated into from a predefined list.
*   **Speech Output (Text-to-Speech):** Listen to the translated text spoken aloud in the selected target language.
*   **Powered by Gemini:** Utilizes Google's Gemini API via the `google_generative_ai` package for translation.

## Screenshots
![WhatsApp Image 2025-04-03 at 19 29 23_fb8c92b6](https://github.com/user-attachments/assets/f04d8737-2be4-4ae5-b711-be610ae89f43)


## Prerequisites

Before you begin, ensure you have met the following requirements:

*   **Flutter SDK:** Version compatible with the range specified in `pubspec.yaml` (currently `sdk: '>=3.3.0 <4.0.0'`). You can check your version with `flutter --version`. Download from [flutter.dev](https://flutter.dev/docs/get-started/install).
*   **Android Device or Emulator:** The app is currently configured primarily for Android. Ensure you have a connected device or a running emulator.
*   **Google AI Gemini API Key:** You need an API key from Google AI Studio to use the translation feature. You can get one here: [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

## Setup Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/aaron1-z/Chatverse-Translator.git
    ```
2.  **Navigate to the project directory:**
    ```bash
    cd Chatverse-Translator
    ```
3.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

## Running the App

To run the application, you **must** provide your Gemini API key using the `--dart-define` flag.

1.  **Connect an Android device or start an emulator.**
2.  **Run the app from the terminal:**

    ```bash
    flutter run --debug --dart-define=GEMINI_API_KEY=YOUR_API_KEY_HERE
    ```

    *   **IMPORTANT:** Replace `YOUR_API_KEY_HERE` with your actual Gemini API key obtained from Google AI Studio. **Do not commit your API key directly into the code.**
    *   The `--debug` flag builds and runs the debug version, suitable for testing and development.

## Building the APK (Optional)

To create a standalone debug APK file that you can install manually:

```bash
# First, clean previous builds (optional but recommended)
flutter clean

# Build the debug APK, providing the API key
flutter build apk --debug --dart-define=GEMINI_API_KEY=YOUR_API_KEY_HERE


