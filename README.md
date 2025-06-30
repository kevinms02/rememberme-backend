# rememberme_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
Launching lib\main.dart on RMX2170 in debug mode...
Running Gradle task 'assembleDebug'...
Your project is configured with Android NDK 26.3.11579264, but the following plugin(s) depend on a different Android NDK version:
- flutter_plugin_android_lifecycle requires Android NDK 27.0.12077973
- image_picker_android requires Android NDK 27.0.12077973
- nfc_manager requires Android NDK 27.0.12077973
- url_launcher_android requires Android NDK 27.0.12077973
  Fix this issue by using the highest Android NDK version (they are backward compatible).
  Add the following to C:\FlutterProject\rememberme_app\android\app\build.gradle.kts:

  android {
  ndkVersion = "27.0.12077973"
  ...
  }
 
