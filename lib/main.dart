import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:geocoding/geocoding.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SunProvider()..initialize(),
      child: MaterialApp(
        title: 'Sunrise Sunset',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ------------------------------------------------------------
// Provider: handles location, API calls, and state
// ------------------------------------------------------------
class SunProvider extends ChangeNotifier {
  SunTimes? _today;
  SunTimes? get today => _today;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _locationName = 'Detecting location...';
  String get locationName => _locationName;

  String? _error;
  String? get error => _error;

  DateTime? _nextEventTime;
  DateTime? get nextEventTime => _nextEventTime;

  String _nextEventName = '';
  String get nextEventName => _nextEventName;

  double _sunAngle = 0.0;
  double get sunAngle => _sunAngle;

  TimePeriod _timePeriod = TimePeriod.day;
  TimePeriod get timePeriod => _timePeriod;

  Future<void> initialize() async {
    await _getCurrentLocationAndFetch();
  }

  Future<void> _getCurrentLocationAndFetch() async {
    _setLoading(true);
    _error = null;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Reverse geocode for city name
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _locationName = '${place.locality ?? place.administrativeArea ?? 'Unknown'}';
        } else {
          _locationName = 'Current Location';
        }
      } catch (_) {
        _locationName = 'Current Location';
      }

      await _fetchSunTimes(position.latitude, position.longitude);
    } catch (e) {
      _error = e.toString();
      _locationName = 'Location unavailable';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchSunTimes(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.sunrisesunset.io/json?lat=$lat&lng=$lng&date=today',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];
        _today = SunTimes.fromJson(results);

        _calculateNextEvent();
        _calculateSunAngle();
        _determineTimePeriod();
      } else {
        throw Exception('Failed to load sun times');
      }
    } catch (e) {
      _error = e.toString();
      _today = null;
    }
    notifyListeners();
  }

  void _calculateNextEvent() {
    if (_today == null) return;

    final now = DateTime.now();
    final todaySunrise = _today!.sunriseDateTime;
    final todaySunset = _today!.sunsetDateTime;

    if (now.isBefore(todaySunrise)) {
      _nextEventTime = todaySunrise;
      _nextEventName = 'Sunrise';
    } else if (now.isBefore(todaySunset)) {
      _nextEventTime = todaySunset;
      _nextEventName = 'Sunset';
    } else {
      // After sunset – next event is tomorrow's sunrise
      _nextEventTime = todaySunrise.add(const Duration(days: 1));
      _nextEventName = 'Sunrise';
    }
  }

  void _calculateSunAngle() {
    if (_today == null) {
      _sunAngle = 0.0;
      return;
    }

    final now = DateTime.now();
    final sunrise = _today!.sunriseDateTime;
    final sunset = _today!.sunsetDateTime;

    if (now.isBefore(sunrise) || now.isAfter(sunset)) {
      _sunAngle = 0.0; // sun below horizon
      return;
    }

    final totalDaylight = sunset.difference(sunrise).inMinutes;
    final elapsed = now.difference(sunrise).inMinutes;
    // Map elapsed time to angle: 0 at sunrise, pi at sunset
    _sunAngle = (elapsed / totalDaylight) * math.pi;
  }

  void _determineTimePeriod() {
    if (_today == null) {
      _timePeriod = TimePeriod.day;
      return;
    }

    final now = DateTime.now();
    final sunrise = _today!.sunriseDateTime;
    final sunset = _today!.sunsetDateTime;

    if (now.isBefore(sunrise)) {
      _timePeriod = TimePeriod.night;
    } else if (now.isBefore(sunset)) {
      _timePeriod = TimePeriod.day;
    } else {
      _timePeriod = TimePeriod.night;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Called when user taps refresh
  Future<void> refresh() async {
    await _getCurrentLocationAndFetch();
  }
}

// ------------------------------------------------------------
// Models
// ------------------------------------------------------------
class SunTimes {
  final String sunrise;
  final String sunset;
  final String solarNoon;
  final String dayLength;

  SunTimes({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.dayLength,
  });

  factory SunTimes.fromJson(Map<String, dynamic> json) {
    return SunTimes(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      solarNoon: json['solar_noon'] ?? '',
      dayLength: json['day_length'] ?? '',
    );
  }

  DateTime get sunriseDateTime {
    final now = DateTime.now();
    final parts = sunrise.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ')[0]);
    final isPM = sunrise.contains('PM');
    return DateTime(
      now.year,
      now.month,
      now.day,
      isPM && hour != 12 ? hour + 12 : hour,
      minute,
    );
  }

  DateTime get sunsetDateTime {
    final now = DateTime.now();
    final parts = sunset.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ')[0]);
    final isPM = sunset.contains('PM');
    return DateTime(
      now.year,
      now.month,
      now.day,
      isPM && hour != 12 ? hour + 12 : hour,
      minute,
    );
  }

  String get formattedDayLength => dayLength;
}

enum TimePeriod { day, night }

// ------------------------------------------------------------
// Custom Fade Pulse (replaces Shimmer)
// ------------------------------------------------------------
class FadePulse extends StatefulWidget {
  final Widget child;
  const FadePulse({super.key, required this.child});

  @override
  State<FadePulse> createState() => _FadePulseState();
}

class _FadePulseState extends State<FadePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: widget.child,
      ),
    );
  }
}

// ------------------------------------------------------------
// Home Screen
// ------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SunProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: _getSkyGradient(provider.timePeriod),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Header with location and refresh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 4),
                            if (provider.isLoading)
                              const FadePulse(
                                child: Text(
                                  'Loading...',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 18),
                                ),

              )
              else
              Text(
              provider.locationName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20),
            ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: provider.refresh,
          ),
          ],
        ),
        const SizedBox(height: 30),
                    // Sun Arc Visual
                    SizedBox(
                      height: 180,
                      child: SunArcWidget(
                        sunAngle: provider.sunAngle,
                        isLoading: provider.isLoading,
                        timePeriod: provider.timePeriod,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Next Event Countdown
                    if (provider.isLoading)
                      const FadePulse(
                        child: Column(
                          children: [
                            Text('Updating...',
                                style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 8),
                            Text('--:--',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (provider.error != null)
                      Text('Error: ${provider.error}',
                          style: const TextStyle(color: Colors.redAccent))
                    else if (provider.nextEventTime != null)
                        NextEventCountdown(
                          eventName: provider.nextEventName,
                          eventTime: provider.nextEventTime!,
                        ),
                    const SizedBox(height: 30),

                    // Time Details Row
                    if (provider.isLoading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FadePulse(child: _TimeDetailPlaceholder()),
                          FadePulse(child: _TimeDetailPlaceholder()),
                          FadePulse(child: _TimeDetailPlaceholder()),
                        ],
                      )
                    else if (provider.today != null)
                      TimeDetailsRow(times: provider.today!),
                    const Spacer(),

                    // Golden hour chip (simplified)
                    if (!provider.isLoading && provider.today != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Day length: ${provider.today!.formattedDayLength}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getSkyGradient(TimePeriod period) {
    if (period == TimePeriod.night) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B0F1C), Color(0xFF1A1F33)],
      );
    } else {
      // Day gradient
      final hour = DateTime.now().hour;
      if (hour < 10) {
        // Morning
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9A5C), Color(0xFFFFD6A5)],
        );
      } else if (hour > 17) {
        // Evening
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
        );
      } else {
        // Midday
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90E2), Color(0xFF90CAF9)],
        );
      }
    }
  }
}

// Placeholder for loading
class _TimeDetailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('--:--', style: TextStyle(color: Colors.white54, fontSize: 24)),
        Text('-----', style: TextStyle(color: Colors.white38)),
      ],
    );
  }
}

// ------------------------------------------------------------
// Sun Arc Custom Painter
// ------------------------------------------------------------
class SunArcWidget extends StatelessWidget {
  final double sunAngle;
  final bool isLoading;
  final TimePeriod timePeriod;

  const SunArcWidget({
    super.key,
    required this.sunAngle,
    required this.isLoading,
    required this.timePeriod,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SunArcPainter(
        sunAngle: sunAngle,
        arcColor: timePeriod == TimePeriod.night
            ? Colors.white24
            : Colors.white.withOpacity(0.6),
        showSun: !isLoading,
      ),
      size: const Size(double.infinity, 180),
    );
  }
}

class SunArcPainter extends CustomPainter {
  final double sunAngle;
  final Color arcColor;
  final bool showSun;

  SunArcPainter({
    required this.sunAngle,
    required this.arcColor,
    required this.showSun,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width / 2 - 20;

    // Draw arc (semi-circle from left to right)
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi,      // start at left (sunrise)
      math.pi,      // sweep to right (sunset)
      false,
      arcPaint,
    );

    if (!showSun) return;

    // Draw sun at the given angle (0 = sunrise/left, pi = sunset/right)
    final sunX = center.dx - radius * math.cos(sunAngle);
    final sunY = center.dy - radius * math.sin(sunAngle);

    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(sunX, sunY), 16, glowPaint);

    // Sun body
    final sunPaint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(sunX, sunY), 10, sunPaint);

    // Inner highlight
    final highlightPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(sunX - 2, sunY - 2), 5, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant SunArcPainter oldDelegate) {
    return oldDelegate.sunAngle != sunAngle ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.showSun != showSun;
  }
}

// ------------------------------------------------------------
// Countdown Widget
// ------------------------------------------------------------
class NextEventCountdown extends StatelessWidget {
  final String eventName;
  final DateTime eventTime;

  const NextEventCountdown({
    super.key,
    required this.eventName,
    required this.eventTime,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Duration>(
      duration: const Duration(seconds: 1),
      tween: Tween(
        begin: Duration.zero,
        end: eventTime.difference(DateTime.now()),
      ),
      builder: (context, value, child) {
        final hours = value.inHours;
        final minutes = value.inMinutes.remainder(60);
        final seconds = value.inSeconds.remainder(60);

        return Column(
          children: [
            Text(
              '$eventName in',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$hours',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'h',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Text(
                  minutes.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'm',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Text(
                  seconds.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                  ),
                ),
                const Text(
                  's',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------
// Time Details Row (Sunrise / Sunset / Day Length)
// ------------------------------------------------------------
class TimeDetailsRow extends StatelessWidget {
  final SunTimes times;

  const TimeDetailsRow({super.key, required this.times});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TimeDetail(
          label: 'Sunrise',
          value: times.sunrise,
          icon: Icons.wb_sunny,
        ),
        _TimeDetail(
          label: 'Sunset',
          value: times.sunset,
          icon: Icons.nights_stay,
        ),
        _TimeDetail(
          label: 'Day Length',
          value: times.dayLength,
          icon: Icons.timelapse,
        ),
      ],
    );
  }
}

class _TimeDetail extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TimeDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}