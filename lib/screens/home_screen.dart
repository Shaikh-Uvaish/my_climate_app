import 'package:flutter/material.dart';

import '../config.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../widgets/tilt_card.dart';
import '../widgets/weather_orb.dart';
import '../widgets/weather_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _display = 'Spartan MB';

  final _service = WeatherService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  String _city = AppConfig.defaultCity;
  CurrentWeather? _weather;
  ForecastBundle? _forecast;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(_city);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load(String city) async {
    final query = city.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchCurrent(query),
        _service.fetchForecast(query),
      ]);
      if (!mounted) return;
      setState(() {
        _city = query;
        _weather = results[0] as CurrentWeather;
        _forecast = results[1] as ForecastBundle;
        _loading = false;
      });
    } on WeatherException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Try again.';
        _loading = false;
      });
    }
  }

  void _submit(String value) {
    _focus.unfocus();
    _load(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final w = _weather;
    final style = w == null
        ? WeatherStyle.of('Clouds')
        : WeatherStyle.of(w.main, night: w.isNight);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.background,
          ),
        ),
        child: Stack(
          children: [
            _glow(top: -80, left: -60, size: 260, color: style.accent, a: 0.22),
            _glow(bottom: 120, right: -90, size: 300, color: style.accentDeep, a: 0.28),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _load(_city),
                color: style.accentDeep,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _searchBar(),
                    const SizedBox(height: 12),
                    _quickCities(),
                    const SizedBox(height: 18),
                    if (_error != null)
                      _errorCard()
                    else if (w == null || _forecast == null)
                      const _Loading()
                    else ...[
                      _hero(w, style),
                      const SizedBox(height: 24),
                      _statsGrid(w),
                      const SizedBox(height: 24),
                      _sectionTitle('Next 24 hours'),
                      const SizedBox(height: 12),
                      _hourly(_forecast!.hourly),
                      const SizedBox(height: 24),
                      _sectionTitle('5-day forecast'),
                      const SizedBox(height: 12),
                      _daily(_forecast!.daily),
                    ],
                  ],
                ),
              ),
            ),
            if (_loading && w != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _glow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double a,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(a), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search a city',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(_city),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _quickCities() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConfig.quickCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = AppConfig.quickCities[i];
          final selected = c.toLowerCase() == _city.toLowerCase();
          return GestureDetector(
            onTap: () => _load(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: selected
                    ? Colors.white.withOpacity(0.92)
                    : Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero(CurrentWeather w, WeatherStyle style) {
    return Column(
      children: [
        Text(
          w.city,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _display,
            fontSize: 30,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          w.country.isEmpty ? '' : w.country,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Center(child: WeatherOrb(style: style, size: 190)),
        Text(
          '${w.temp.round()}°',
          style: const TextStyle(
            fontFamily: _display,
            fontSize: 92,
            height: 1,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          capitalize(w.description),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'H ${w.tempMax.round()}°   L ${w.tempMin.round()}°   Feels like ${w.feelsLike.round()}°',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _statsGrid(CurrentWeather w) {
    final km = (w.visibility / 1000);
    final stats = <_Stat>[
      _Stat(Icons.water_drop_outlined, 'Humidity', '${w.humidity}%'),
      _Stat(Icons.air_rounded, 'Wind', '${(w.windSpeed * 3.6).toStringAsFixed(0)} km/h'),
      _Stat(Icons.speed_rounded, 'Pressure', '${w.pressure} hPa'),
      _Stat(Icons.visibility_outlined, 'Visibility', '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km'),
      _Stat(Icons.wb_twilight_rounded, 'Sunrise', clockLabel(w.sunrise)),
      _Stat(Icons.nights_stay_outlined, 'Sunset', clockLabel(w.sunset)),
    ];

    return LayoutBuilder(builder: (context, c) {
      const gap = 12.0;
      final cols = c.maxWidth > 560 ? 3 : 2;
      final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in stats)
            SizedBox(
              width: tileW,
              child: Tilt3D(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s.icon, color: Colors.white70, size: 22),
                      const SizedBox(height: 14),
                      Text(
                        s.value,
                        style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: _display,
          fontSize: 18,
          color: Colors.white,
        ),
      );

  Widget _hourly(List<HourlyForecast> items) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final h = items[i];
          final st = WeatherStyle.of(h.main, night: h.isNight);
          return SizedBox(
            width: 82,
            child: Tilt3D(
              child: GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      i == 0 ? 'Now' : hourLabel(h.time),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Icon(st.icon, color: st.accent, size: 30),
                    Text(
                      '${h.temp.round()}°',
                      style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${h.rainChance}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: h.rainChance >= 40
                            ? const Color(0xFF9BD1FF)
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _daily(List<DailyForecast> days) {
    double lo = days.first.min, hi = days.first.max;
    for (final d in days) {
      if (d.min < lo) lo = d.min;
      if (d.max > hi) hi = d.max;
    }
    final span = (hi - lo) == 0 ? 1.0 : (hi - lo);

    return Tilt3D(
      maxAngle: 0.08,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            for (int i = 0; i < days.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        i == 0 ? 'Today' : weekdayShort(days[i].date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      WeatherStyle.of(days[i].main).icon,
                      color: WeatherStyle.of(days[i].main).accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${days[i].min.round()}°',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _rangeBar(days[i], lo, span)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${days[i].max.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rangeBar(DailyForecast d, double lo, double span) {
    final start = ((d.min - lo) / span).clamp(0.0, 1.0);
    final end = ((d.max - lo) / span).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, c) {
      final left = c.maxWidth * start;
      final width = (c.maxWidth * (end - start)).clamp(8.0, c.maxWidth);
      return SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Positioned(
              left: left.clamp(0.0, c.maxWidth - width),
              child: Container(
                width: width,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9BD1FF), Color(0xFFFFE082)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _errorCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 14),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _load(_weather == null ? AppConfig.defaultCity : _city),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;
  const _Stat(this.icon, this.label, this.value);
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}