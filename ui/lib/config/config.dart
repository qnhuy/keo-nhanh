import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Base URL của Backend API. Đọc từ file .env (BASE_API_URL), mặc định fallback là http://localhost:3000
  static String get apiBaseUrl {
    final envUrl = dotenv.env['BASE_API_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }
    return 'http://localhost:3000';
  }

  // Tương thích ngược với thuộc tính cũ
  static String get apiUrl => apiBaseUrl;
}

// Alias cho tương thích ngược
typedef Config = AppConfig;
