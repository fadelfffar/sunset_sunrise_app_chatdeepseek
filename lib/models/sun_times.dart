enum TimePeriod { day, night }

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