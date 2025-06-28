# Expense Tracker Flutter Client

A comprehensive Flutter frontend application for tracking personal expenses and income, designed to work with the Django REST API backend.

## Features

- **Authentication**: User registration, login, and profile management
- **Transaction Management**: Add, edit, delete income and expense transactions
- **Categories**: Organize transactions with customizable categories
- **Dashboard**: Overview of financial status with balance, income, and expenses
- **Analytics**: Visual insights into spending patterns (coming soon)
- **Multi-currency Support**: Support for multiple currencies
- **Responsive Design**: Works on both mobile and tablet devices

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── user_model.dart
│   ├── transaction_model.dart
│   └── category_model.dart
├── providers/                  # State management
│   ├── auth_provider.dart
│   ├── transaction_provider.dart
│   └── category_provider.dart
├── services/                   # API and external services
│   └── api_service.dart
├── screens/                    # UI screens
│   ├── auth/
│   ├── home/
│   ├── transactions/
│   ├── categories/
│   ├── profile/
│   └── analytics/
├── widgets/                    # Reusable UI components
│   ├── custom_text_field.dart
│   └── custom_button.dart
├── utils/                      # Utilities and helpers
│   ├── constants.dart
│   └── theme.dart
└── routes/                     # Navigation
    └── app_routes.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Expense Tracker Django Backend running

### Installation

1. **Clone the repository**
   ```bash
   cd Expense-Tracker-Client
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure API endpoint**
   
   Update the `baseUrl` in `lib/utils/constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-backend-url:8000';
   ```
   
   For local development:
   - Android Emulator: `http://10.0.2.2:8000`
   - iOS Simulator: `http://localhost:8000`
   - Physical Device: `http://YOUR_COMPUTER_IP:8000`

5. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Backend Integration

The app is configured to work with the Django backend. Make sure your backend is running and accessible. The API endpoints used include:

- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `GET /api/auth/profile/` - Get user profile
- `GET /api/transactions/` - Get transactions
- `POST /api/transactions/create/` - Create transaction
- `GET /api/categories/list/` - Get categories

### Environment Setup

For different environments (development, staging, production), you can modify the constants in `lib/utils/constants.dart`.

## Architecture

### State Management
The app uses the **Provider** pattern for state management:
- `AuthProvider`: Manages user authentication state
- `TransactionProvider`: Handles transaction-related operations
- `CategoryProvider`: Manages categories and their operations

### API Integration
- `ApiService`: Centralized service for all HTTP requests
- JWT token-based authentication
- Automatic token refresh handling
- Error handling with user-friendly messages

### Routing
- Named routes with `AppRoutes` class
- Type-safe navigation helpers
- Route arguments handling

## Dependencies

### Core Dependencies
- `flutter`: UI framework
- `provider`: State management
- `http`: HTTP client for API calls
- `shared_preferences`: Local storage
- `intl`: Internationalization

### UI Dependencies
- `google_fonts`: Custom fonts
- `flutter_spinkit`: Loading animations
- `fl_chart`: Charts for analytics

### Development Dependencies
- `build_runner`: Code generation
- `json_serializable`: JSON serialization
- `flutter_lints`: Code linting

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Follow the existing code structure and naming conventions
2. Use meaningful commit messages
3. Add appropriate comments for complex logic
4. Update documentation for new features
5. Test thoroughly before submitting

## Known Issues

- Some screens are still in development (marked as "Coming Soon")
- Analytics features are planned for future releases
- Image upload for receipts needs implementation

## Future Enhancements

- [ ] Complete transaction list with filtering and search
- [ ] Advanced analytics with charts and insights
- [ ] Receipt image capture and storage
- [ ] Budget planning and alerts
- [ ] Export data functionality
- [ ] Dark mode support
- [ ] Offline mode with data synchronization

## Support

For issues and questions:
1. Check the existing issues in the repository
2. Create a new issue with detailed description
3. Include steps to reproduce the problem

## License

This project is part of the Expense Tracker application suite. 