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

/// Talks to the Node.js backend (see /backend). The backend returns the
/// OpenWeatherMap JSON unchanged, so the models work as before.
class WeatherService {
  Future<Map<String, dynamic>> _get(String path, String city) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/$path').replace(
      queryParameters: {'city': city},
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
            const Duration(seconds: 20),
          );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }

      // The backend sends {"error": "..."} with a readable message.
      String? serverMessage;
      try {
        serverMessage = (jsonDecode(body) as Map<String, dynamic>)['error']
            as String?;
      } catch (_) {}

      throw WeatherException(
        serverMessage ?? 'Server error (${response.statusCode}).',
      );
    } on SocketException {
      throw const WeatherException(
        'Can\'t reach the server. Is the backend running and is baseUrl in config.dart correct?',
      );
    } on TimeoutException {
      throw const WeatherException('The request timed out. Try again.');
    } on FormatException {
      throw const WeatherException('Unexpected response from the server.');
    } on HandshakeException {
      throw const WeatherException('Secure connection failed.');
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