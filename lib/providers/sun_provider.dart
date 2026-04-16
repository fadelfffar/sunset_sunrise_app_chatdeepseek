import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/sun_times.dart';

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
          _locationName = place.locality ?? place.administrativeArea ?? 'Unknown';
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
      _sunAngle = 0.0;
      return;
    }

    final totalDaylight = sunset.difference(sunrise).inMinutes;
    final elapsed = now.difference(sunrise).inMinutes;
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

  Future<void> refresh() async {
    await _getCurrentLocationAndFetch();
  }
}