import 'package:flutter/material.dart';

class WeatherStyle {
  final List<Color> background;
  final Color accent;
  final Color accentDeep;
  final IconData icon;

  const WeatherStyle({
    required this.background,
    required this.accent,
    required this.accentDeep,
    required this.icon,
  });

  static WeatherStyle of(String main, {bool night = false}) {
    switch (main) {
      case 'Clear':
        return night
            ? const WeatherStyle(
                background: [Color(0xFF0B1030), Color(0xFF1D2A6B), Color(0xFF3B2F7A)],
                accent: Color(0xFFE8E4FF),
                accentDeep: Color(0xFF7C74D6),
                icon: Icons.nightlight_round,
              )
            : const WeatherStyle(
                background: [Color(0xFF1E88E5), Color(0xFF42A5F5), Color(0xFFFFB74D)],
                accent: Color(0xFFFFE082),
                accentDeep: Color(0xFFFF8F00),
                icon: Icons.wb_sunny_rounded,
              );
      case 'Clouds':
        return const WeatherStyle(
          background: [Color(0xFF37474F), Color(0xFF607D8B), Color(0xFF90A4AE)],
          accent: Color(0xFFECEFF1),
          accentDeep: Color(0xFF78909C),
          icon: Icons.cloud_rounded,
        );
      case 'Rain':
      case 'Drizzle':
        return const WeatherStyle(
          background: [Color(0xFF0D1B2A), Color(0xFF1B3A5C), Color(0xFF3A6EA5)],
          accent: Color(0xFF9BD1FF),
          accentDeep: Color(0xFF2F7FD1),
          icon: Icons.water_drop_rounded,
        );
      case 'Thunderstorm':
        return const WeatherStyle(
          background: [Color(0xFF12101F), Color(0xFF2B2447), Color(0xFF4A3F7A)],
          accent: Color(0xFFFFE066),
          accentDeep: Color(0xFF8E7CC3),
          icon: Icons.thunderstorm_rounded,
        );
      case 'Snow':
        return const WeatherStyle(
          background: [Color(0xFF5C7FA3), Color(0xFF8FB3D9), Color(0xFFD6E6F5)],
          accent: Color(0xFFFFFFFF),
          accentDeep: Color(0xFF8FB8E0),
          icon: Icons.ac_unit_rounded,
        );
      default: // Mist, Haze, Smoke, Fog, Dust...
        return const WeatherStyle(
          background: [Color(0xFF3E4A52), Color(0xFF6B7B84), Color(0xFFA7B4BA)],
          accent: Color(0xFFE0E6E8),
          accentDeep: Color(0xFF7F9099),
          icon: Icons.blur_on_rounded,
        );
    }
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

String hourLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String clockLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);