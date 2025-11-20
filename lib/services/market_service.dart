import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../repositories/settings_repo.dart';

/// —— 行情品类（按 UI 顺序） —— ///
enum MarketVariety {
  shatangJu, // 沙糖桔
  satangJu, // 砂糖橘
  wogan, // 沃柑
  jinJu, // 金桔
  shatianYou, // 沙田柚
  huangdiGan, // 皇帝柑
}

/// 中文显示名
const Map<MarketVariety, String> kVarietyName = {
  MarketVariety.shatangJu: '沙糖桔',
  MarketVariety.satangJu: '砂糖橘',
  MarketVariety.wogan: '沃柑',
  MarketVariety.jinJu: '金桔',
  MarketVariety.shatianYou: '沙田柚',
  MarketVariety.huangdiGan: '皇帝柑',
};

/// 简单的价格点
class PricePoint {
  final DateTime date;
  final double price; // 元/斤
  PricePoint(this.date, this.price);
}

/// 行情数据包：最近7日历史 + 未来7日预测
class MarketBundle {
  final String city;
  final List<PricePoint> history7; // 升序，最后一天是“昨日”
  final List<PricePoint> forecast7; // 升序，第一天是“今日/明日”
  MarketBundle({
    required this.city,
    required this.history7,
    required this.forecast7,
  });

  double get yesterdayPrice => history7.isNotEmpty ? history7.last.price : 0;
  double get dayBeforeYesterday => history7.length >= 2
      ? history7[history7.length - 2].price
      : yesterdayPrice;
  double get momDiff => yesterdayPrice - dayBeforeYesterday;
  double get momPct =>
      dayBeforeYesterday == 0 ? 0 : (momDiff / dayBeforeYesterday) * 100.0;
}

class MarketService {
  MarketService._();
  static final MarketService I = MarketService._();

  /// 统一入口：优先 HTTP（按设置），失败则回退 Mock
  Future<MarketBundle> loadMarket(String city, MarketVariety variety) async {
    final settings = SettingsRepo();
    final mode = await settings.getMarketApiMode(); // 0: Mock, 1: HTTP
    final base = (await settings.getMarketApiBase()).trim();

    if (mode == 1 && base.isNotEmpty) {
      try {
        final httpData = await _loadHttp(base, city, variety);
        return httpData;
      } catch (e) {
        // HTTP 失败回退到 Mock
        // ignore: avoid_print
        print('[MarketService] HTTP 失败，回退 Mock：$e');
      }
    }
    return _loadMock(city, variety);
  }

  // =======================
  // HTTP 数据源
  // =======================
  Future<MarketBundle> _loadHttp(
    String base,
    String city,
    MarketVariety variety,
  ) async {
    final cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final path = '/market/${variety.name}';
    final uri = Uri.parse(
      '$cleanBase$path',
    ).replace(queryParameters: {'city': city, 'h': '7'});

    final resp = await http.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final jsonMap =
        json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    // 兼容字段名：trend/history、forecast、yesterday_price（可缺省）
    final hisRaw = (jsonMap['trend'] ?? jsonMap['history']) as List<dynamic>?;
    final fcRaw = jsonMap['forecast'] as List<dynamic>?;

    if (hisRaw == null || fcRaw == null || hisRaw.isEmpty || fcRaw.isEmpty) {
      throw Exception('响应缺少必要字段 trend/forecast');
    }

    List<PricePoint> parseList(List<dynamic> arr) {
      return arr.map((e) {
        final m = e as Map<String, dynamic>;
        final dateStr = (m['date'] ?? m['dt'] ?? m['d']) as String;
        final priceNum = m['price'] ?? m['p'];
        final p = priceNum is num
            ? priceNum.toDouble()
            : double.parse('$priceNum');
        return PricePoint(DateTime.parse(dateStr), p);
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
    }

    final history = parseList(hisRaw);
    final forecast = parseList(fcRaw);

    // 仅取“最近7天历史”；后端若返回>7天我们裁剪尾部7天
    final history7 = history.length <= 7
        ? history
        : history.sublist(history.length - 7);

    return MarketBundle(
      city: (jsonMap['city'] as String?) ?? city,
      history7: history7,
      forecast7: forecast.length <= 7 ? forecast : forecast.sublist(0, 7),
    );
  }

  // =======================
  // 本地 Mock（与你现有算法一致，按城市和品类产生稳定随机）
  // =======================
  Future<MarketBundle> _loadMock(String city, MarketVariety variety) async {
    final now = DateTime.now();
    final seedBase = _stableHash(
      '$city-${variety.name}-${now.year}-${now.month}-${now.day}',
    );
    final rand = Random(seedBase);

    final base =
        _cityBase(city) *
        _varietyFactor(variety) *
        (0.96 + rand.nextDouble() * 0.08);

    // 近7日历史（包含昨日）
    final history = <PricePoint>[];
    double price = base * (0.98 + rand.nextDouble() * 0.04);
    for (int i = 6; i >= 1; i--) {
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      price = _step(price, base, rand, dayOffset: -i);
      history.add(PricePoint(dt, _clip(price)));
    }
    final ydt = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    price = _step(price, base, rand, dayOffset: -1);
    history.add(PricePoint(ydt, _clip(price)));

    // 未来7日预测
    final forecast = <PricePoint>[];
    double f = history.last.price;
    for (int i = 0; i < 7; i++) {
      final dt = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      f = _step(f, base, rand, dayOffset: i + 1, forward: true);
      forecast.add(PricePoint(dt, _clip(f)));
    }

    return MarketBundle(city: city, history7: history, forecast7: forecast);
  }

  // —— Helpers —— //

  /// 各品类相对系数（可按真实价差再调）
  double _varietyFactor(MarketVariety v) {
    switch (v) {
      case MarketVariety.shatangJu:
        return 1.10;
      case MarketVariety.satangJu:
        return 1.06;
      case MarketVariety.wogan:
        return 1.08;
      case MarketVariety.jinJu:
        return 1.15;
      case MarketVariety.shatianYou:
        return 0.90;
      case MarketVariety.huangdiGan:
        return 1.05;
    }
  }

  // 价格演化：回归基准 + 周期项 + 微噪声
  double _step(
    double current,
    double base,
    Random r, {
    required int dayOffset,
    bool forward = false,
  }) {
    final meanRevert = 0.6;
    final noise = (r.nextDouble() - 0.5) * 0.12; // ±6%
    final seasonal = 0.03 * sin((dayOffset / 7.0) * pi * 2);
    final drift = forward ? 0.002 : 0.0;
    final target = base * (1.0 + seasonal + drift);
    final next =
        current + meanRevert * (target - current) + current * noise * 0.3;
    return next;
  }

  // 限幅
  double _clip(double v) => v.clamp(1.2, 15.0);

  // 城市基准价
  double _cityBase(String city) {
    final c = city.toLowerCase();
    if (c.contains('南宁') || c.contains('nanning')) return 4.2;
    if (c.contains('桂林') || c.contains('guilin')) return 4.6;
    if (c.contains('柳州') || c.contains('liuzhou')) return 4.0;
    if (c.contains('百色') || c.contains('baise')) return 4.1;
    if (c.contains('北京') || c.contains('beijing')) return 5.5;
    if (c.contains('广州') || c.contains('guangzhou')) return 4.8;
    if (c.contains('上海') || c.contains('shanghai')) return 5.2;
    return 4.5;
  }

  // 稳定哈希
  int _stableHash(String s) {
    int h = 0;
    for (final code in s.codeUnits) {
      h = 0x1fffffff & (h + code);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= (h >> 11);
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    return h;
  }
}
