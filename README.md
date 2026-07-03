# Product Bidding System

A comprehensive Flutter application that provides both **Admin** and **User** interfaces for managing product auctions and bidding. The application leverages Firebase for backend services including authentication, real-time database, and cloud messaging.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Project Architecture](#project-architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Project Structure](#project-structure)
- [Key Technologies](#key-technologies)
- [Configuration](#configuration)
- [Development](#development)
- [Building & Deployment](#building--deployment)
- [Testing](#testing)
- [Key Services](#key-services)
- [Important Notes](#important-notes)

---

## Overview

The **Product Bidding System** is a dual-role Flutter application designed for managing product auctions. The application supports two distinct user roles:

1. **Admin**: Manages products, auction listings, user approvals, and system oversight
2. **Users**: Browse products, place bids, track auction progress, and manage their account

The application is built with Firebase as the primary backend, providing real-time data synchronization, secure authentication, and push notifications.

---

## Project Architecture

### Application Structure

```
Dual-Role Application:
├── Admin Interface (Web + Mobile)
│   ├── Product Management
│   ├── Auction Configuration
│   ├── User Management
│   └── Dashboard & Analytics
└── User Interface (Mobile)
    ├── Auction Browsing
    ├── Bidding Engine
    ├── Profile Management
    └── Notification Center
```

### Backend Architecture

- **Authentication**: Firebase Authentication (Email/Password)
- **Database**: Cloud Firestore (Real-time NoSQL)
- **Storage**: Firebase Storage (Product images, documents)
- **Messaging**: Firebase Cloud Messaging (Push notifications)
- **Notifications**: Flutter Local Notifications (Foreground FCM display)

---

## Features

### Admin Features
- ✅ Secure admin login and session management
- ✅ Product catalog management (Create, Read, Update, Delete)
- ✅ Auction creation and configuration
- ✅ Real-time dashboard with auction statistics
- ✅ User approval and management workflows
- ✅ Auction monitoring and analytics

### User Features
- ✅ User registration and authentication
- ✅ Browse active auctions and products
- ✅ Place and manage bids in real-time
- ✅ Track bidding history and won auctions
- ✅ Profile management and account settings
- ✅ Push notifications for auction updates and bid outbids
- ✅ Real-time auction status updates

### General Features
- ✅ Cross-platform support (iOS, Android, Web, Windows, macOS, Linux)
- ✅ Real-time data synchronization via Firestore
- ✅ Push notification support (FCM)
- ✅ Product image management
- ✅ Comprehensive error handling
- ✅ Material Design UI with custom theming

---

## Prerequisites

### Required Software
- **Flutter**: Version >= 3.0.0
- **Dart**: Version >= 3.0.0 (bundled with Flutter)
- **Java**: JDK 11+ (for Android development)
- **Xcode**: Latest version (for iOS development)
- **Android Studio**: Latest version with Android SDK
- **Git**: For version control

### Required Accounts
- **Firebase Project**: Create a Firebase project in [Firebase Console](https://console.firebase.google.com)
- **Google Cloud Console**: For service account configuration

---

## Installation & Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/Sajith22/Product_Bidding_app.git
cd Bidding_app/bidding_app
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Configure Firebase (Critical)

**This step is required before running the app:**

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This command will:
1. Prompt you to select your Firebase project
2. Generate `lib/firebase_options.dart` with your Firebase configuration
3. Configure Firebase for each platform (iOS, Android, Web, etc.)

**IMPORTANT**: Do NOT commit `google-services.json` or `firebase_options.dart` with real API keys to version control. Use example files and configure locally.

### Step 4: Set Firebase API Key at Build Time

For production builds, set the Firebase API key as a build-time parameter:

```bash
flutter run --dart-define=FIREBASE_API_KEY=your_api_key_here
```

Or for release builds:

```bash
flutter build apk --dart-define=FIREBASE_API_KEY=your_api_key_here
flutter build ios --dart-define=FIREBASE_API_KEY=your_api_key_here
```

### Step 5: Run the Application

```bash
# Development build
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

---

## Project Structure

```
bidding_app/
├── lib/
│   ├── main.dart                      # Application entry point & Firebase initialization
│   ├── firebase_options.dart          # Firebase configuration (generated by flutterfire configure)
│   │
│   ├── models/
│   │   ├── app_models.dart            # Core data models (User, Product, Bid, Auction)
│   │   └── product.dart               # Product model with serialization
│   │
│   ├── screens/
│   │   ├── admin/
│   │   │   ├── login_screen.dart      # Admin login interface
│   │   │   └── dashboard_screen.dart  # Admin dashboard & management UI
│   │   │
│   │   └── user/
│   │       ├── login_screen.dart      # User login & registration
│   │       └── auctions_screen.dart   # Auction browsing & bidding interface
│   │
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Authentication service
│   │   ├── product_service.dart       # Product CRUD operations
│   │   └── notification_service.dart  # Firebase Cloud Messaging setup
│   │
│   ├── theme/
│   │   ├── admin_theme.dart           # Admin UI color scheme & styling
│   │   └── user_theme.dart            # User UI color scheme & styling
│   │
│   ├── utils/                         # Utility functions & helpers
│   └── widgets/                       # Reusable custom widgets
│
├── android/
│   ├── app/
│   │   ├── google-services.json       # Android Firebase configuration
│   │   └── src/                       # Android-specific code
│   ├── build.gradle.kts               # Android project build configuration
│   └── gradle.properties              # Gradle properties
│
├── ios/
│   ├── Runner.xcworkspace/            # Xcode workspace
│   ├── Runner/
│   │   ├── Info.plist                 # iOS configuration
│   │   └── GoogleService-Info.plist   # iOS Firebase configuration
│   └── Podfile                        # CocoaPods dependencies
│
├── web/
│   ├── index.html                     # Web entry point
│   ├── manifest.json                  # PWA manifest
│   └── icons/                         # Web app icons
│
├── test/
│   └── widget_test.dart               # Widget tests
│
├── pubspec.yaml                       # Flutter project configuration & dependencies
├── firebase.json                      # Firebase CLI configuration
├── analysis_options.yaml              # Linting rules configuration
└── README.md                          # Project overview
```

---

## Key Technologies

### Frontend Framework
- **Flutter**: Cross-platform mobile, web, and desktop development framework
- **Dart**: Programming language

### Backend Services
- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Storage**: File storage for product images
- **Firebase Cloud Messaging (FCM)**: Push notifications

### Key Dependencies

```yaml
firebase_core: ^3.3.0              # Firebase initialization
firebase_auth: ^5.1.4              # Authentication
cloud_firestore: ^5.2.1            # Real-time database
firebase_messaging: ^15.0.4        # Push notifications
firebase_storage: ^12.1.3          # Cloud storage
flutter_local_notifications: ^17.2.3 # Foreground notification display
image_picker: ^1.2.1               # Image selection
cupertino_icons: ^1.0.8            # iOS icons
```

---

## Configuration

### Firebase Console Setup

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project or use existing one
   - Enable required services:
     - Authentication (Email/Password)
     - Firestore Database
     - Storage
     - Cloud Messaging

2. **Enable Authentication Methods**:
   - Go to Authentication → Sign-in method
   - Enable "Email/Password" provider

3. **Configure Firestore Database**:
   - Start in test mode for development
   - Set up security rules for production

4. **Configure Storage**:
   - Create a storage bucket
   - Set appropriate security rules

5. **Configure Cloud Messaging**:
   - Generate FCM server key
   - Configure notification templates

### Local Configuration Files

- **`firebase_options.dart.example`**: Template for Firebase configuration (rename to `firebase_options.dart` after running `flutterfire configure`)
- **`google-services.json.example`**: Template for Android Firebase configuration
- **Environment-specific configuration**: Use `--dart-define` flags for API keys

---

## Development

### Running in Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run with verbose output for debugging
flutter run -v

# Run on specific target
flutter run -d chrome    # Web
flutter run -d macos     # macOS
flutter run -d linux     # Linux
flutter run -d windows   # Windows
```

### Hot Reload

During development, use hot reload to quickly test changes:

```bash
# After making code changes, press 'r' in the terminal to reload
r - reload
R - restart
q - quit
```

### Code Analysis

```bash
# Check for linting issues
flutter analyze

# Format code according to Dart style guide
dart format .

# Fix issues automatically (where possible)
dart fix --apply
```

---

## Building & Deployment

### Android

**Debug Build**:
```bash
flutter build apk
```

**Release Build** (requires signing configuration):
```bash
flutter build apk --release --dart-define=FIREBASE_API_KEY=your_key
```

**App Bundle** (for Google Play):
```bash
flutter build appbundle --release --dart-define=FIREBASE_API_KEY=your_key
```

⚠️ **Important**: Update `android/app/build.gradle.kts` with production values:
- Application ID
- Signing key configuration
- Version code and name

### iOS

**Debug Build**:
```bash
flutter build ios
```

**Release Build**:
```bash
flutter build ios --release --dart-define=FIREBASE_API_KEY=your_key
```

### Web

```bash
flutter build web --release
```

---

## Testing

### Widget Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Model & Serialization Tests

Pure model tests (recommended first test layer):

```bash
flutter test test/models/
```

**Important**: When testing widgets that use `BiddingApp`, ensure Firebase is initialized or properly mocked to avoid initialization errors.

---

## Key Services

### 1. AuthService (`lib/services/auth_service.dart`)
Handles user authentication including:
- Login and registration
- Password reset
- Session management
- Role-based access control (Admin/User)

### 2. ProductService (`lib/services/product_service.dart`)
Manages product operations:
- Create and edit products
- Fetch product listings
- Update product status
- Handle product images

### 3. NotificationService (`lib/services/notification_service.dart`)
Manages push notifications:
- Firebase Cloud Messaging initialization
- Foreground notification display
- Notification routing and handling
- Permission management

---

## Important Notes

### ⚠️ Firebase Configuration
- **CRITICAL**: Run `flutterfire configure` before first run
- Firebase API key should be supplied at build time via `--dart-define` parameter, not hardcoded
- Never commit real `google-services.json` or `firebase_options.dart` to version control
- Use `.example` files as templates

### 🔐 Security Considerations
- Implement proper Firestore security rules for production
- Validate all user input on the backend
- Use HTTPS for all external API calls
- Store sensitive data securely (never in shared preferences without encryption)

### 📱 Platform-Specific Setup
- **Android**: Ensure Google Play Services is configured
- **iOS**: Configure APNS (Apple Push Notification service) certificates
- **Web**: Ensure service workers are properly configured for notifications
- **Windows/Linux/macOS**: Verify platform-specific requirements

### 🧪 Testing Recommendations
1. Start with pure model and serialization tests
2. Mock Firebase for widget tests
3. Avoid directly pumping `BiddingApp` unless Firebase is initialized
4. Use test fixtures for consistent test data

### 🚀 Production Deployment
- Generate and sign release builds with production credentials
- Configure Firebase production security rules
- Set up error logging and analytics
- Test thoroughly on target devices before release
- Prepare app store listings and assets

---

## Troubleshooting

### Common Issues

**Firebase Initialization Error**
```
Solution: Run `flutterfire configure` and ensure firebase_options.dart is present
```

**Android Build Fails**
```
Solution: 
- Update Google Play Services
- Check Java version (JDK 11+)
- Clear build: flutter clean && flutter pub get
```

**iOS Build Issues**
```
Solution:
- Update CocoaPods: pod repo update
- Clean: flutter clean
- Reinstall pods: cd ios && rm -rf Pods && pod install
```

---

## Contributing

When contributing to this project:
1. Follow Dart/Flutter style guidelines (`dart format`)
2. Add tests for new features
3. Update documentation for API changes
4. Use meaningful commit messages
5. Create feature branches for new work

---

## License

This project is licensed under the terms specified in the LICENSE file.

---

## Support & Contact

For issues, questions, or contributions, please reach out to the project maintainers or create an issue in the repository.

---

## Version History

- **v1.0.0**: Initial release
  - Admin and user authentication
  - Product management system
  - Real-time bidding functionality
  - Push notification support
  - Multi-platform support

---

**Last Updated**: June 2026  
**Flutter Version**: >= 3.0.0  
**Dart Version**: >= 3.0.0
