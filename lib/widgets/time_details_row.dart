import 'package:flutter/material.dart';
import '../models/sun_times.dart';

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