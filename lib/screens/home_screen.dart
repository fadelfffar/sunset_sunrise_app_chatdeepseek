import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animation/fade_pulse.dart';
import '../providers/sun_provider.dart';
import '../widgets/sun_arc.dart';
import '../widgets/countdown.dart';
import '../widgets/time_details_row.dart';
import '../models/sun_times.dart';

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
                    _buildHeader(provider),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 180,
                      child: SunArcWidget(
                        sunAngle: provider.sunAngle,
                        isLoading: provider.isLoading,
                        timePeriod: provider.timePeriod,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCountdownSection(provider),
                    const SizedBox(height: 30),
                    _buildTimeDetails(provider),
                    const Spacer(),
                    _buildDayLengthChip(provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SunProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 20),
            const SizedBox(width: 4),
            if (provider.isLoading)
              const FadePulse(
                child: Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
            else
              Text(
                provider.locationName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: provider.refresh,
        ),
      ],
    );
  }

  Widget _buildCountdownSection(SunProvider provider) {
    if (provider.isLoading) {
      return const FadePulse(
        child: Column(
          children: [
            Text('Updating...', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text('--:--',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Text('Error: ${provider.error}',
          style: const TextStyle(color: Colors.redAccent));
    }

    if (provider.nextEventTime != null) {
      return NextEventCountdown(
        eventName: provider.nextEventName,
        eventTime: provider.nextEventTime!,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTimeDetails(SunProvider provider) {
    if (provider.isLoading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FadePulse(child: _TimeDetailPlaceholder()),
          FadePulse(child: _TimeDetailPlaceholder()),
          FadePulse(child: _TimeDetailPlaceholder()),
        ],
      );
    }

    if (provider.today != null) {
      return TimeDetailsRow(times: provider.today!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDayLengthChip(SunProvider provider) {
    if (provider.isLoading || provider.today == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'Day length: ${provider.today!.formattedDayLength}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
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
      final hour = DateTime.now().hour;
      if (hour < 10) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9A5C), Color(0xFFFFD6A5)],
        );
      } else if (hour > 17) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
        );
      } else {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90E2), Color(0xFF90CAF9)],
        );
      }
    }
  }
}

class _TimeDetailPlaceholder extends StatelessWidget {
  const _TimeDetailPlaceholder();

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