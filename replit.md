# SmartBuy - Grocery Shopping App

## Overview
SmartBuy is a Flutter-based grocery shopping companion app that helps users organize their shopping lists, track pantry items, and manage their grocery shopping more efficiently.

## Project Structure
- `smartbuy/` - Main Flutter project directory
  - `lib/` - Dart source code
    - `main.dart` - Application entry point
    - `src/` - Core application code
      - `core/` - Theme, constants, Firebase initialization
      - `models/` - Data models (grocery items, lists, users)
      - `providers/` - Riverpod providers for state management
      - `services/` - Firebase, auth, analytics services
      - `ui/` - Screens, widgets, and routing
  - `build/web/` - Built Flutter web files (served by HTTP server)
  - `assets/` - Icons, fonts, and Lottie animations

## Technologies
- **Framework**: Flutter 3.32.0 (Web)
- **Language**: Dart 3.8.0
- **State Management**: Flutter Riverpod
- **Backend**: Firebase (Auth, Firestore)
- **Routing**: GoRouter

## Running the App
The app runs automatically via the configured workflow which serves the built Flutter web app on port 5000.

## Features
- User authentication (Email/Password, Google Sign-in)
- Grocery list management
- Pantry tracking
- Insights and analytics
- Offline support with sync

## Recent Changes
- December 8, 2025: Initial setup on Replit
  - Extracted project from archive
  - Fixed SDK version compatibility (3.8.0)
  - Fixed DropdownButtonFormField initialValue parameter issue
  - Built Flutter web release
  - Configured HTTP server workflow for web serving

## Firebase Configuration
The app uses Firebase for authentication and data storage. Firebase options are configured in `lib/firebase_options.dart`.
