import 'dart:convert';
import 'package:http/http.dart' as http;

/// 轻量天气数据模型
class WeatherNow {
  final double temperature; // ℃
  final double windspeed; // km/h
  final String weathercode; // Open-Meteo weather code

  WeatherNow({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
  });

  factory WeatherNow.fromJson(Map<String, dynamic> j) => WeatherNow(
    temperature: (j['temperature'] as num?)?.toDouble() ?? 0,
    windspeed: (j['windspeed'] as num?)?.toDouble() ?? 0,
    weathercode: '${j['weathercode'] ?? ''}',
  );
}

class DailyWeather {
  final DateTime date;
  final double tmax;
  final double tmin;
  final double precipitation; // mm

  DailyWeather({
    required this.date,
    required this.tmax,
    required this.tmin,
    required this.precipitation,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> j, int idx) =>
      DailyWeather(
        date: DateTime.parse((j['time'] as List)[idx]),
        tmax: ((j['temperature_2m_max'] as List)[idx] as num?)?.toDouble() ?? 0,
        tmin: ((j['temperature_2m_min'] as List)[idx] as num?)?.toDouble() ?? 0,
        precipitation:
            ((j['precipitation_sum'] as List)[idx] as num?)?.toDouble() ?? 0,
      );
}

class WeatherBundle {
  final String city;
  final double lat;
  final double lon;
  final WeatherNow now;
  final List<DailyWeather> daily;

  WeatherBundle({
    required this.city,
    required this.lat,
    required this.lon,
    required this.now,
    required this.daily,
  });
}

class CityLocation {
  final String name;
  final double lat;
  final double lon;
  CityLocation({required this.name, required this.lat, required this.lon});
}

class WeatherService {
  WeatherService._();
  static final WeatherService I = WeatherService._();

  /// 城市名 ➜ 经纬度（使用 Open-Meteo Geocoding）
  Future<CityLocation?> geocodeCity(
    String cityName, {
    String lang = 'zh',
  }) async {
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(cityName)}&count=1&language=$lang&format=json',
    );
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) return null;

    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (j['results'] as List?) ?? [];
    if (results.isEmpty) return null;

    final r = results.first as Map<String, dynamic>;
    return CityLocation(
      name: (r['name'] ?? cityName).toString(),
      lat: (r['latitude'] as num).toDouble(),
      lon: (r['longitude'] as num).toDouble(),
    );
  }

  /// 经纬度 ➜ 天气数据（当前 + 7日）
  Future<WeatherBundle> fetchWeather({
    required double lat,
    required double lon,
    String city = '',
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current_weather=true'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&timezone=auto',
    );
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Weather API error: ${resp.statusCode}');
    }

    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    final now = WeatherNow.fromJson(
      j['current_weather'] as Map<String, dynamic>,
    );
    final dailyJson = j['daily'] as Map<String, dynamic>;
    final times = (dailyJson['time'] as List?) ?? [];
    final days = <DailyWeather>[];
    for (var i = 0; i < times.length; i++) {
      days.add(DailyWeather.fromJson(dailyJson, i));
    }

    return WeatherBundle(city: city, lat: lat, lon: lon, now: now, daily: days);
  }
}
