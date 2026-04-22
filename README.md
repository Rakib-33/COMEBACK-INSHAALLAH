# TARGET FINAL

> MIST students' academic companion for syncing courses, tracking progress, and planning results with less friction.

---

## What This App Does

Target Final is a Flutter app built for MIST students who want a cleaner way to:

- sync academic course data
- review course progress in one place
- estimate outcomes and final targets
- move from raw portal data to quick academic decisions

It is designed to feel fast, focused, and practical instead of crowded.

---

## Why It Matters

Students often have to jump between portals, notes, and manual calculations.

Target Final brings that workflow into one app so academic planning becomes:

- quicker
- clearer
- less repetitive
- easier to trust

---

## Run The App

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run in development

```bash
flutter run
```

### 3. Build a release APK

```bash
flutter build apk --release
```

### 4. Build the smaller arm64 APK

```bash
flutter build apk --release --target-platform android-arm64 --shrink
```

---

## Project Stack

- Flutter
- Dart
- GetX
- SQLite
- Shared Preferences
- InAppWebView

---

## Entry Point

The app starts from:

```text
lib/main.dart
```

---

## Current APK

The kept release APK is:

```text
app-release-v1.0.1+2.apk
```

This is the reduced `arm64` build, which keeps the file size smaller for modern Android phones.
