/// The OpenWeatherMap key now lives on the Node.js backend (backend/server.js),
/// not in the app.
class AppConfig {
  /// Where the backend is running:
  ///  - Android emulator:        http://10.0.2.2:3000/api
  ///  - Real phone (same Wi-Fi): http://<your-PC-IP>:3000/api 
  ///  - Chrome / Windows app:    http://localhost:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static const String defaultCity = 'Pune';

  static const List<String> quickCities = [
    'Pune',
    'Mumbai',
    'Delhi',
    'London',
    'New York',
    'Tokyo',
  ];
}