# Dots - Connect Colored Dots Puzzle Game

**Package:** `com.budrock.dots`  
**Version:** 1.0.0

A premium mobile puzzle game where players connect pairs of colored dots without overlapping paths.

## 🎮 Game Rules

1. **Connect the Dots** - Draw lines between matching colored dots
2. **Fill the Grid** - Every cell must be part of a path
3. **No Overlaps** - Paths cannot cross or overlap
4. **Complete All Pairs** - Solve the puzzle by connecting all dot pairs

## 📱 Features

- ✅ Three difficulty levels (Easy, Medium, Hard)
- ✅ Unlimited practice puzzles
- ✅ Beautiful neon-themed UI
- ✅ Smooth touch-based drawing
- ✅ Real-time path validation
- ✅ Timer and progress tracking
- ✅ Clean, responsive design

## 🏗️ Architecture

Built with:
- **Flutter 3.0+** - Cross-platform framework
- **Flame 1.18+** - 2D game engine for rendering
- **Riverpod 2.6+** - State management
- **GoRouter 17+** - Navigation
- **Dio 5+** - HTTP client
- **Freezed** - Immutable models
- **Google Fonts** - Typography

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   cd dots
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart      # Theme and styling
│   └── router/
│       └── app_router.dart     # Navigation routes
├── models/
│   ├── color_dot.dart          # Dot and path models
│   └── connect_dots_puzzle.dart # Puzzle and game state
├── services/
│   ├── api_client.dart         # HTTP client
│   ├── connect_dots_service.dart # Backend API
│   └── ad_service.dart         # Ad integration
├── providers/
│   ├── service_providers.dart  # Service providers
│   └── connect_dots_provider.dart # State management
├── flame/
│   ├── connect_dots_game.dart  # Main game coordinator
│   └── components/
│       ├── dots_board.dart     # Board renderer
│       ├── multi_path_renderer.dart # Path visualizer
│       ├── dot_renderer.dart   # Dot renderer
│       └── dots_gesture_controller.dart # Touch input
└── features/
    ├── home/
    │   └── home_screen.dart    # Main menu
    ├── practice/
    │   └── practice_screen.dart # Difficulty selection
    ├── puzzle/
    │   └── connect_dots_screen.dart # Game screen
    └── settings/
        └── settings_screen.dart # Settings
```

## 🎨 Color Palette

- **Background:** #0F0A1E (Dark purple-black)
- **Cards:** #1A1530 (Dark purple)
- **Primary:** #8B5CF6 (Vibrant purple)
- **Cyan:** #43C6FF (Bright cyan)
- **Pink:** #FF43B8 (Neon pink)
- **Yellow:** #FFC043 (Warm yellow)
- **Green:** #7BFF43 (Bright green)

## 🔧 Configuration

### Android (build.gradle.kts)
- **Package:** `com.budrock.dots`
- **Min SDK:** 21
- **Target SDK:** 34
- **Compile SDK:** 34

### iOS (Runner.xcodeproj)
- **Bundle ID:** `com.budrock.dots`
- **Deployment Target:** iOS 13.0+

## 🌐 Backend API

Connects to: `https://zip.robotpdf.com/api/v1/connectdots`

**Endpoints:**
- `GET /practice?difficulty={easy|medium|hard}&sequence={number}`
- `GET /:puzzleId`
- `POST /:puzzleId/submit`

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Check formatting
flutter format --set-exit-if-changed .
```

## 📝 Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🎯 Difficulty Levels

| Level | Grid Size | Dot Pairs | Complexity |
|-------|-----------|-----------|------------|
| Easy | 5×5 | 3-4 pairs | Beginner |
| Medium | 6×6 | 4-5 pairs | Intermediate |
| Hard | 7×7 | 5-6 pairs | Advanced |

## 🔐 Code Generation

The project uses code generation for:
- **Freezed** - Immutable data classes
- **JSON Serialization** - API models
- **Riverpod** - Provider generation

Run after model changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📄 License

Copyright © 2026 Budrock. All rights reserved.

## 🤝 Contributing

This is a production app. For bugs or feature requests, contact the development team.

---

**Made with ❤️ using Flutter and Flame**
