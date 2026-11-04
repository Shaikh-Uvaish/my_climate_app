/// App-wide configuration.
///
/// Get a free key at https://openweathermap.org/api and paste it below.
/// New keys can take up to ~2 hours to activate.
class AppConfig {
  static const String weatherApiKey = 'YOUR_API_KEY_HERE';

  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  static const String defaultCity = 'Pune';

  static const List<String> quickCities = [
    'Pune',
    'Mumbai',
    'Delhi',
    'London',
    'New York',
    'Tokyo',
  ];

  static bool get hasApiKey =>
      weatherApiKey.isNotEmpty && !weatherApiKey.startsWith('PASTE_');
}