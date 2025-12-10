# SmartBuy - Grocery Shopping App

## Overview
SmartBuy is a Flutter-based grocery shopping companion app that helps users organize their shopping lists, track pantry items, and manage their grocery shopping more efficiently.

## Project Structure
- `smartbuy/` - Main Flutter project directory
  - `lib/` - Dart source code
    - `main.dart` - Application entry point
    - `src/` - Core application code
      - `core/` - Theme, constants, Firebase initialization
      - `models/` - Data models (grocery items, lists, users, subscriptions)
      - `providers/` - Riverpod providers for state management
      - `services/` - Firebase, auth, analytics, subscription services
      - `ui/` - Screens, widgets, and routing
  - `build/web/` - Built Flutter web files (served by HTTP server)
  - `assets/` - Icons, fonts, and Lottie animations

## Technologies
- **Framework**: Flutter 3.32.0 (Web)
- **Language**: Dart 3.8.0
- **State Management**: Flutter Riverpod
- **Backend**: Firebase (Auth, Firestore)
- **Payments**: Razorpay (INR)
- **Routing**: GoRouter
- **Charts**: fl_chart

## Running the App
The app runs automatically via the configured workflow which serves the built Flutter web app on port 5000.

## Features
- User authentication (Email/Password, Google Sign-in)
- Grocery list management
- Pantry tracking
- Offline support with sync
- **SaaS Subscription System (Razorpay)**
  - Four-tier pricing: Free, Plus (₹99/mo), Family (₹199/mo), Pro (₹299/mo)
  - Feature-based access control with paywall dialogs
  - Razorpay payment gateway integration
  - Subscription management in Profile screen
  - Plan limits: lists, sharing, reminders, collaboration, AI insights
- **Real-Time Sharing & Collaboration**
  - Share lists via WhatsApp with invite links
  - Three-tier role system: Owner, Editor, Viewer
  - Role-based access control (owners can share, editors can modify, viewers read-only)
  - Real-time sync for collaborative shopping
- **Budget Management**
  - Set budget limits per shopping list
  - Real-time spent tracking as items are checked off
  - Visual budget progress bar with color-coded status
  - Budget notifications when approaching (90%) or exceeding limits
  - Persisted alert status to prevent notification spam across sessions
- **Insights Dashboard**
  - Smart Spend AI suggestions with local logic
  - Weekly spending bar chart with daily breakdown
  - Spending overview stats (this week, this month, daily avg, items bought)
  - Budget utilization progress bar
  - Category breakdown with horizontal progress bars
  - Category spend distribution pie chart
  - Shopping frequency and saving opportunity insights
  - Pantry consumption forecast
- **Spending Trends**
  - 7-day spending visualization with bar chart
  - Accurate historical data from purchase logs
  - Atomic purchase logging with FieldValue.arrayUnion for collaboration

## Subscription Plans
| Plan | Price (INR) | Features |
|------|-------------|----------|
| 🆓 Free | ₹0 | 1 List, Basic features, No sharing |
| ⚡ Plus | ₹99/mo | 5 Lists, Share lists, Reminders, Budget tracking |
| 👨‍👩‍👧 Family | ₹199/mo | Unlimited lists, Real-time collaboration, Family sharing |
| 💎 Pro | ₹299/mo | Everything + AI Smart Insights, Cloud backup, Priority support |

## Recent Changes
- December 10, 2025: SaaS Subscription System
  - Implemented complete Razorpay payment integration
  - Created subscription data model with plan tiers
  - Built pricing/paywall UI screen with plan comparison
  - Added feature lock logic with paywall dialogs
  - Integrated subscription checks for list creation and sharing
  - Dynamic subscription card on Profile screen
  - Subscription service for Firestore billing schema

- December 10, 2025: Performance Optimizations
  - Optimistic list creation - lists appear instantly before Firestore confirms
  - Fire-and-forget item addition - dialog closes immediately
  - Improved checkbox state management with proper equality operators

- December 9, 2025: Profile Image Upload
  - Added round profile picture with camera icon overlay on Profile screen
  - Profile image appears above user name
  - Camera icon button to select/change profile photo
  - Image picker integration for gallery selection
  - Images stored as base64 in Firestore for persistence
  - Shows user initials when no photo is set
  - Loading indicator during upload

- December 9, 2025: Lists Screen UI Redesign
  - Completely redesigned home/lists screen with modern UI:
    - Greeting header with time-based message (Good Morning/Afternoon/Evening)
    - User name display and quick access buttons for Insights and Profile
    - Search bar for filtering lists and items
    - Categories section with horizontal scroll (Fruits, Vegetables, Dairy, Bakery, Meat, Beverages)
    - Tab buttons for "My Lists" and "Shared" with item counts
    - "+ New" button for creating lists
    - Redesigned list cards with progress bar showing completion percentage
    - Budget display on list cards when set
    - More options menu (3-dot) for share and delete actions
    - Bottom sheet dialog for creating new lists

- December 9, 2025: Authentication & Navigation Improvements
  - Updated Google Sign-In to use Firebase Auth's signInWithPopup for better web compatibility
  - Added Forgot Password route to GoRouter
  - Implemented password reset functionality using Firebase Auth sendPasswordResetEmail
  - Updated sign-in screen navigation to use GoRouter instead of Navigator
  - Added success/error message display on forgot password screen
  - Consistent UI styling matching sign-in screen design

- December 8, 2025: Pantry Screen Enhancement & Bug Fixes
  - Completely redesigned Pantry Stock screen with color-coded cards
  - Fixed checkbox issue when marking items as purchased
  - Added defensive type checking for usageLog parsing

- December 8, 2025: Initial setup on Replit
  - Extracted project from archive
  - Fixed SDK version compatibility (3.8.0)
  - Built Flutter web release
  - Configured HTTP server workflow for web serving

## Technical Notes
- **Razorpay Integration**: Uses JavaScript interop for web checkout, stores subscription in Firestore /users/{uid}/subscription/current
- **Feature Gates**: Subscription providers check plan limits before allowing actions
- **Optimistic Updates**: List creation uses pre-generated Firestore IDs for instant UI feedback
- **Notification spam prevention**: Uses static caches and Firestore-persisted lastAlertStatus with mutex-based write serialization
- **Spending trends**: Uses purchaseLog entries (logged at time of purchase with exact price/quantity/category) for accurate historical data
- **Atomic updates**: Purchase logging uses FieldValue.arrayUnion to prevent race conditions in collaborative environments

## Environment Variables
- `RAZORPAY_KEY_ID` - Razorpay API Key ID (stored as secret)
- `RAZORPAY_KEY_SECRET` - Razorpay API Key Secret (stored as secret)

## Firebase Configuration
The app uses Firebase for authentication and data storage. Firebase options are configured in `lib/firebase_options.dart`.
