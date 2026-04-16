import 'package:flutter/material.dart';

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