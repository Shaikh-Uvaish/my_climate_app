class CurrentWeather {
  final String city;
  final String country;
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed; // m/s
  final int visibility; // metres
  final int clouds;
  final String main;
  final String description;
  final bool isNight;
  final DateTime sunrise;
  final DateTime sunset;

  const CurrentWeather({
    required this.city,
    required this.country,
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.visibility,
    required this.clouds,
    required this.main,
    required this.description,
    required this.isNight,
    required this.sunrise,
    required this.sunset,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> j) {
    final w = (j['weather'] as List).first as Map<String, dynamic>;
    final m = j['main'] as Map<String, dynamic>;
    final sys = (j['sys'] ?? {}) as Map<String, dynamic>;
    final wind = (j['wind'] ?? {}) as Map<String, dynamic>;
    final tz = (j['timezone'] ?? 0) as int;

    DateTime local(int unix) => DateTime.fromMillisecondsSinceEpoch(
          (unix + tz) * 1000,
          isUtc: true,
        );

    return CurrentWeather(
      city: (j['name'] ?? '') as String,
      country: (sys['country'] ?? '') as String,
      temp: (m['temp'] as num).toDouble(),
      feelsLike: (m['feels_like'] as num).toDouble(),
      tempMin: (m['temp_min'] as num).toDouble(),
      tempMax: (m['temp_max'] as num).toDouble(),
      humidity: (m['humidity'] as num).toInt(),
      pressure: (m['pressure'] as num).toInt(),
      windSpeed: ((wind['speed'] ?? 0) as num).toDouble(),
      visibility: ((j['visibility'] ?? 0) as num).toInt(),
      clouds: ((((j['clouds'] ?? {}) as Map)['all'] ?? 0) as num).toInt(),
      main: w['main'] as String,
      description: w['description'] as String,
      isNight: (w['icon'] as String).endsWith('n'),
      sunrise: local((sys['sunrise'] ?? 0) as int),
      sunset: local((sys['sunset'] ?? 0) as int),
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final String main;
  final bool isNight;
  final int rainChance; // percent

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.main,
    required this.isNight,
    required this.rainChance,
  });
}

class DailyForecast {
  final DateTime date;
  final double min;
  final double max;
  final String main;

  const DailyForecast({
    required this.date,
    required this.min,
    required this.max,
    required this.main,
  });
}

class ForecastBundle {
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  const ForecastBundle({required this.hourly, required this.daily});

  factory ForecastBundle.fromJson(Map<String, dynamic> j) {
    final tz = (((j['city'] ?? {}) as Map)['timezone'] ?? 0) as int;
    final list = (j['list'] as List).cast<Map<String, dynamic>>();

    final items = <HourlyForecast>[];
    for (final e in list) {
      final w = (e['weather'] as List).first as Map<String, dynamic>;
      final t = DateTime.fromMillisecondsSinceEpoch(
        ((e['dt'] as int) + tz) * 1000,
        isUtc: true,
      );
      items.add(HourlyForecast(
        time: t,
        temp: ((e['main'] as Map)['temp'] as num).toDouble(),
        main: w['main'] as String,
        isNight: (w['icon'] as String).endsWith('n'),
        rainChance: ((((e['pop'] ?? 0) as num) * 100).round()),
      ));
    }

    // Group into days.
    final byDay = <String, List<HourlyForecast>>{};
    for (final h in items) {
      final key = '${h.time.year}-${h.time.month}-${h.time.day}';
      byDay.putIfAbsent(key, () => []).add(h);
    }

    final days = <DailyForecast>[];
    for (final group in byDay.values) {
      double lo = group.first.temp, hi = group.first.temp;
      for (final h in group) {
        if (h.temp < lo) lo = h.temp;
        if (h.temp > hi) hi = h.temp;
      }
      // Representative condition: slot closest to midday.
      final rep = group.reduce((a, b) =>
          (a.time.hour - 12).abs() <= (b.time.hour - 12).abs() ? a : b);
      days.add(DailyForecast(
        date: group.first.time,
        min: lo,
        max: hi,
        main: rep.main,
      ));
    }

    return ForecastBundle(
      hourly: items.take(8).toList(),
      daily: days.take(5).toList(),
    );
  }
}