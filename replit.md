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
- **Charts**: fl_chart

## Running the App
The app runs automatically via the configured workflow which serves the built Flutter web app on port 5000.

## Features
- User authentication (Email/Password, Google Sign-in)
- Grocery list management
- Pantry tracking
- Offline support with sync
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

## Recent Changes
- December 8, 2025: Insights Dashboard Enhancement
  - Added InsightsProvider for aggregated spending analytics across all lists
  - Implemented Smart Spend AI suggestions with local logic:
    - Budget exhaustion alerts (90%+ utilization)
    - Week-over-week spending trend analysis
    - Category concentration warnings (40%+ of total)
    - Per-list over-budget alerts
    - Projected overspend calculations
    - Bulk buying suggestions (3+ purchases of same item)
    - Peak shopping day pattern detection
  - Added weekly spending bar chart with fl_chart
  - Added spending overview with 4-stat grid and budget utilization
  - Timezone-aware date handling for accurate analytics
  - Category field added to purchase log entries

- December 8, 2025: Budget Notifications & Spending Trends
  - Added budget notification system with warning (90%) and exceeded alerts
  - Implemented mutex-based serialization for notification status persistence
  - Added purchase logging at item check-off with atomic Firestore updates
  - Created spending trends visualization showing 7-day spending patterns
  - Added lastAlertStatus and purchaseLog fields to GroceryList model
  - Defensive parsing for spending trends to handle legacy/malformed data

- December 8, 2025: Real-Time Sharing & Collaboration
  - Added MemberRole enum with owner/editor/viewer roles
  - Created ShareListBottomSheet widget with WhatsApp sharing
  - Implemented role validation at service and repository layers
  - Added role-based UI controls in lists and list detail screens
  - Updated acceptInvite to write normalized roles back to documents
  - Changed sharing from email to WhatsApp with shareable invite links

- December 8, 2025: Initial setup on Replit
  - Extracted project from archive
  - Fixed SDK version compatibility (3.8.0)
  - Fixed DropdownButtonFormField initialValue parameter issue
  - Built Flutter web release
  - Configured HTTP server workflow for web serving

## Technical Notes
- **Notification spam prevention**: Uses static caches and Firestore-persisted lastAlertStatus with mutex-based write serialization
- **Spending trends**: Uses purchaseLog entries (logged at time of purchase with exact price/quantity/category) for accurate historical data
- **Atomic updates**: Purchase logging uses FieldValue.arrayUnion to prevent race conditions in collaborative environments
- **Timezone handling**: Insights provider converts Firestore UTC timestamps to local time for accurate calendar day matching
- **Week boundary handling**: Uses normalized midnight dates with explicit upper/lower bounds for accurate week-over-week comparisons

## Firebase Configuration
The app uses Firebase for authentication and data storage. Firebase options are configured in `lib/firebase_options.dart`.
