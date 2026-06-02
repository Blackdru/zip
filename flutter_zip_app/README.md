# Flutter ZIP Puzzle Game

A premium competitive puzzle game built with Flutter + Flame, integrating with the existing Node.js backend.

## Project Overview

This is a complete Flutter + Flame implementation that replaces the React Native frontend while preserving all existing backend logic, APIs, and business rules.

## Tech Stack

- **Flutter** - UI Framework
- **Flame Engine** - Game rendering and interactions
- **Riverpod** - State management
- **Dio** - HTTP client
- **go_router** - Navigation
- **Hive** - Local storage
- **freezed** - Immutable models
- **json_serializable** - JSON serialization

## Architecture

The project follows clean architecture with feature-based modular structure:

```
lib/
├── core/              # Core utilities, constants, extensions
├── shared/            # Shared widgets and utilities
├── features/          # Feature modules
│   ├── auth/
│   ├── leaderboard/
│   ├── tournaments/
│   ├── puzzle/
│   ├── profile/
│   ├── practice/
│   └── settings/
├── flame/             # Flame game engine components
├── services/          # API services
├── models/            # Data models
├── repositories/      # Data repositories
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development

### Installation

```bash
cd flutter_zip_app
flutter pub get
flutter run
```

## Backend Integration

This app integrates with the existing Node.js backend at:
- Development: `http://localhost:3000/api/v1`
- Production: `https://your-api-domain.com/api/v1`

All API endpoints, authentication flow, and business logic remain unchanged.

## Game Features

### Weekly Tournament Mode
- 5-10 official puzzles per week
- Global competition
- Combined solve time leaderboard
- Real-time ranking updates

### Practice Mode
- Infinite generated puzzles
- Three difficulty levels (Easy, Medium, Hard)
- No leaderboard impact

### Gameplay
- Connect numbered nodes in sequence
- Draw continuous paths
- Timer-based competition
- Premium visual effects with Flame

## Visual Design

- Dark theme with charcoal backgrounds
- Subtle neon glow effects
- Minimalist and elegant UI
- Premium futuristic aesthetic
- Centered path rendering (35-50% cell width)
- Smooth animations at 60 FPS

## Performance Targets

- Stable 60 FPS gameplay
- Smooth gesture tracking
- Low memory usage
- Optimized rendering
- Responsive touch interactions

## Security

- Secure JWT handling
- Encrypted local storage
- Server-authoritative validation
- Anti-cheat integration

## License

Proprietary
