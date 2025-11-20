import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _city = '南宁';
  CityLocation? _loc;
  WeatherBundle? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadByCity(_city);
  }

  Future<void> _loadByCity(String city) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await WeatherService.I.geocodeCity(city);
      if (loc == null) {
        setState(() {
          _loading = false;
          _error = '未找到该城市：$city';
        });
        return;
      }
      final bundle = await WeatherService.I.fetchWeather(
        lat: loc.lat,
        lon: loc.lon,
        city: loc.name,
      );
      setState(() {
        _city = loc.name;
        _loc = loc;
        _data = bundle;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '获取天气失败：$e';
      });
    }
  }

  Future<void> _refresh() async {
    if (_loc != null) {
      await _loadByCity(_city);
    } else {
      await _loadByCity(_city);
    }
  }

  Future<void> _pickCity() async {
    final controller = TextEditingController(text: _city);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择地区'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '城市名（如：南宁、桂林、柳州）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _loadByCity(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('天气'),
        actions: [
          IconButton(
            tooltip: '选择地区',
            icon: const Icon(Icons.place_outlined),
            onPressed: _pickCity,
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            )
          : _data == null
          ? const Center(child: Text('暂无数据'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // 当前天气卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _data!.city.isEmpty ? _city : _data!.city,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '纬度 ${_data!.lat.toStringAsFixed(2)}，经度 ${_data!.lon.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '当前温度：${_data!.now.temperature.toStringAsFixed(1)} ℃',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '风速：${_data!.now.windspeed.toStringAsFixed(1)} km/h',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 40,
                        color: Colors.orange.shade600,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 7日预报
                Text('未来 7 日', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._data!.daily.take(7).map((d) => _DailyTile(day: d)).toList(),
              ],
            ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  final DailyWeather day;
  const _DailyTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final dt = day.date;
    final md =
        '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(md)),
          Expanded(
            child: Text(
              '最高 ${day.tmax.toStringAsFixed(1)}℃ / 最低 ${day.tmin.toStringAsFixed(1)}℃',
            ),
          ),
          Text('降水 ${day.precipitation.toStringAsFixed(1)}mm'),
        ],
      ),
    );
  }
}
