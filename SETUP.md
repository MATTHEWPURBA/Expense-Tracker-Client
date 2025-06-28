# Flutter Expense Tracker Setup Guide

This guide will help you set up the Flutter frontend for the Expense Tracker application.

## Prerequisites

### 1. Install Flutter

Follow the official Flutter installation guide for your operating system:
- [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

Make sure to:
- Download and install Flutter SDK
- Add Flutter to your PATH
- Run `flutter doctor` to verify installation

### 2. Install Development Tools

**Recommended IDEs:**
- [Android Studio](https://developer.android.com/studio) with Flutter plugin
- [VS Code](https://code.visualstudio.com/) with Flutter extension

**Required:**
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)

## Project Setup

### 1. Navigate to Project Directory
```bash
cd Expense-Tracker-Client
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Model Files
The project uses JSON serialization. Generate the required files:
```bash
flutter packages pub run build_runner build
```

If you need to rebuild (when models change):
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Backend Connection

Edit `lib/utils/constants.dart` and update the `baseUrl`:

```dart
class AppConstants {
  // Update this URL to match your Django backend
  static const String baseUrl = 'http://localhost:8000';
  // ... rest of the constants
}
```

**Important:** Use appropriate URLs for different environments:

- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:8000`
- **Production**: `https://your-domain.com`

### 5. Verify Backend Connection

Make sure your Django backend is running and accessible:
1. Start your Django server: `python manage.py runserver`
2. Test API accessibility from your device/emulator

## Running the Application

### Development Mode
```bash
flutter run
```

### Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d device_id
```

### Build Modes
```bash
# Debug mode (default)
flutter run

# Profile mode (performance testing)
flutter run --profile

# Release mode (production)
flutter run --release
```

## Project Structure Overview

```
Expense-Tracker-Client/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models with JSON serialization
│   ├── providers/             # State management (Provider pattern)
│   ├── services/              # API services
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable UI components
│   ├── utils/                 # Constants and utilities
│   └── routes/                # Navigation routes
├── assets/                    # Images, fonts, icons
├── android/                   # Android-specific files
├── ios/                       # iOS-specific files
└── pubspec.yaml              # Dependencies and configuration
```

## Troubleshooting

### Common Issues

1. **Build Runner Issues**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Connection Issues**
   - Check if backend is running
   - Verify correct IP address/URL
   - Check network permissions on device
   - For Android: Add network security config if using HTTP

3. **Dependencies Issues**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **iOS Build Issues**
   ```bash
   cd ios
   pod install
   cd ..
   flutter run
   ```

### Network Security (Android HTTP)

If using HTTP in production (not recommended), add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

## Development Workflow

### 1. Starting Development
```bash
# Pull latest changes
git pull origin main

# Install/update dependencies
flutter pub get

# Generate files if models changed
flutter packages pub run build_runner build

# Run the app
flutter run
```

### 2. Adding New Features
1. Create new screens in `lib/screens/`
2. Add routes in `lib/routes/app_routes.dart`
3. Update providers if needed
4. Test thoroughly

### 3. Building for Production

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Backend Integration

### API Endpoints Used
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/profile/` - Get user profile
- `PUT /api/auth/profile/` - Update user profile
- `GET /api/transactions/` - Get transactions
- `POST /api/transactions/create/` - Create transaction
- `PUT /api/transactions/{id}/update/` - Update transaction
- `DELETE /api/transactions/{id}/delete/` - Delete transaction
- `GET /api/categories/list/` - Get categories
- `POST /api/categories/create/` - Create category

### Authentication Flow
1. User registers/logs in
2. JWT tokens stored locally
3. Tokens included in API requests
4. Automatic token refresh handling
5. Logout clears tokens

## Performance Tips

1. **Use Release Mode for Testing Performance**
   ```bash
   flutter run --release
   ```

2. **Profile Your App**
   ```bash
   flutter run --profile
   ```

3. **Analyze Bundle Size**
   ```bash
   flutter build apk --analyze-size
   ```

## Next Steps

After setup:
1. Test basic authentication flow
2. Try adding a transaction
3. Explore different screens
4. Check backend integration
5. Customize themes and colors if needed

## Getting Help

- Check Flutter documentation: https://docs.flutter.dev/
- Review error logs in the console
- Check GitHub issues for common problems
- Verify backend is properly configured and running

## Future Development

Areas for expansion:
- Complete remaining screens (Analytics, Profile management)
- Add advanced filtering and search
- Implement offline mode
- Add data export functionality
- Include receipt image capture
- Add budget planning features 