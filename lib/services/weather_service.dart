import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../models/weather.dart';

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

/// Talks to OpenWeatherMap using dart:io only, so pubspec.yaml
/// does not need any extra packages.
class WeatherService {
  Future<Map<String, dynamic>> _get(String path, String city) async {
    if (!AppConfig.hasApiKey) {
      throw const WeatherException(
        'Add your OpenWeatherMap API key in lib/config.dart',
      );
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/$path').replace(
      queryParameters: {
        'q': city,
        'appid': AppConfig.weatherApiKey,
        'units': 'metric',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
            const Duration(seconds: 15),
          );
      final body = await response.transform(utf8.decoder).join();

      switch (response.statusCode) {
        case 200:
          return jsonDecode(body) as Map<String, dynamic>;
        case 401:
          throw const WeatherException(
            'API key rejected. New keys can take up to 2 hours to activate.',
          );
        case 404:
          throw WeatherException('Couldn\'t find "$city". Check the spelling.');
        case 429:
          throw const WeatherException(
            'Too many requests. Wait a minute and try again.',
          );
        default:
          throw WeatherException(
            'Weather service error (${response.statusCode}).',
          );
      }
    } on SocketException {
      throw const WeatherException('No internet connection.');
    } on TimeoutException {
      throw const WeatherException('The request timed out. Try again.');
    } on FormatException {
      throw const WeatherException('Unexpected response from the server.');
    } finally {
      client.close();
    }
  }

  Future<CurrentWeather> fetchCurrent(String city) async {
    final json = await _get('weather', city);
    return CurrentWeather.fromJson(json);
  }

  Future<ForecastBundle> fetchForecast(String city) async {
    final json = await _get('forecast', city);
    return ForecastBundle.fromJson(json);
  }
}