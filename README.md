# Shop Manager

A modern Flutter application for managing shop inventory, recording sales, and generating reports. Built with a clean UI and robust state management using Provider.

## Features

- **Dashboard**: View today's sales, profit, and low-stock alerts with quick actions to add products or record sales.
- **Products Management**: Browse, search, and sort products by name, stock level, or price. Tap any product to edit or delete it.
- **Add Products**: Easily add new products with validation for prices, stock levels, and low-stock thresholds.
- **Sales Recording**: Select products, adjust quantities, and record sales with real-time stock updates.
- **Reports**: Visualize sales trends over 7 or 30 days with interactive charts, daily breakdowns, and top-selling products.
- **Offline Support**: Works offline with local SQLite database; optional backend integration for multi-device sync.

## Screenshots

*(Add screenshots here if available)*

## Installation

### Prerequisites

- Flutter SDK (version 3.3.0 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd shop_manager
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

For Android emulator with local backend, use:
```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

## Backend Integration

The app includes an optional Python backend for data synchronization. By default, it connects to a deployed backend on Render.

### Configuration

The backend URL can be configured using the `BACKEND_URL` environment variable:

- **Production (default)**: `https://shop-manager-backend-xe9d.onrender.com`
- **Development**: `http://localhost:8000` or `http://10.0.2.2:8000` (Android emulator)

### Running with Different Backends

```bash
# Use default production backend
flutter run

# Use custom backend URL
flutter run --dart-define=BACKEND_URL=https://your-custom-backend.com

# Use local development backend
flutter run --dart-define=BACKEND_URL=http://localhost:8000

# Build APK with custom backend
flutter build apk --dart-define=BACKEND_URL=https://your-production-backend.com
```

### Running the Local Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Start the server:
   ```bash
   uvicorn app:app --reload --host 0.0.0.0 --port 8000
   ```

5. Run the Flutter app with local backend:
   ```bash
   flutter run --dart-define=BACKEND_URL=http://localhost:8000
   ```

**Note**: Local URLs are automatically blocked in release builds to prevent accidental deployment with development URLs.

## Architecture

- **State Management**: Provider for reactive UI updates.
- **Local Storage**: SQLite database via sqflite package.
- **Networking**: HTTP client for backend communication.
- **UI**: Material Design with custom themes and responsive layouts.

## Dependencies

- `provider`: State management
- `sqflite`: SQLite database
- `path`: File path utilities
- `http`: HTTP client for backend

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
