import 'package:flutter/material.dart';
import '../services/market_service.dart';
import '../repositories/settings_repo.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _settings = SettingsRepo();

  // 一级热门（本批上线）
  static const List<String> kHotCities = ['南宁', '桂林', '柳州', '百色'];
  // 二级更多（可按需增减）
  static const List<String> kMoreCities = [
    '北海',
    '钦州',
    '防城港',
    '梧州',
    '玉林',
    '贵港',
    '贺州',
    '河池',
    '来宾',
    '崇左',
    '广州',
    '深圳',
    '佛山',
    '东莞',
    '珠海',
    '中山',
    '北京',
    '上海',
    '杭州',
    '成都',
    '重庆',
  ];

  String _city = '南宁';
  MarketVariety _variety = MarketVariety.satangJu;

  MarketBundle? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSelections().then((_) {
      _load(_city, variety: _variety);
    });
  }

  Future<void> _restoreSelections() async {
    final sc = await _settings.getSelectedCity();
    final svName = await _settings.getSelectedVarietyName();
    if (sc != null && sc.isNotEmpty) _city = sc;
    if (svName != null && svName.isNotEmpty) {
      final matched = MarketVariety.values
          .where((e) => e.name == svName)
          .toList();
      if (matched.isNotEmpty) _variety = matched.first;
    }
  }

  Future<void> _saveSelections() async {
    await _settings.setSelectedCity(_city);
    await _settings.setSelectedVarietyName(_variety.name);
  }

  Future<void> _load(String city, {MarketVariety? variety}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = variety ?? _variety;
      final bundle = await MarketService.I.loadMarket(city, v);
      setState(() {
        _city = city;
        _variety = v;
        _data = bundle;
        _loading = false;
      });
      await _saveSelections();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '获取行情失败：$e';
      });
    }
  }

  Future<void> _refresh() async => _load(_city, variety: _variety);

  // —— 城市选择：右上角按钮 → 底部弹窗（一级热门 + 更多…）—— //
  Future<void> _pickCitySheet() async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _CitySheet(
          hot: kHotCities,
          onPick: (c) => Navigator.pop(ctx, c),
          onMore: () async {
            Navigator.pop(ctx); // 先关一级
            final moreSel = await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx2) => _MoreCitySheet(
                all: kMoreCities,
                current: _city,
                onPick: (c) => Navigator.pop(ctx2, c),
              ),
            );
            if (moreSel != null && moreSel.isNotEmpty) {
              // ignore: use_build_context_synchronously
              await _load(moreSel, variety: _variety);
            }
          },
          current: _city,
        );
      },
    );
    if (sel != null && sel.isNotEmpty) {
      await _load(sel, variety: _variety);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('柑橘行情与预测'),
        actions: [
          // 紧凑的“当前城市 + 定位图标”
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2), // 原先 4 → 2，更紧凑
                child: Text(
                  _city,
                  style: const TextStyle(
                    fontSize: 14, // 与图标协调
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: '选择城市',
                icon: const Icon(Icons.place_outlined),
                onPressed: _pickCitySheet,
                padding: EdgeInsets.zero, // 去除默认内边距
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36, // 收紧触控区，仍可点
                ),
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -2, // 进一步压缩占位
                ),
              ),
              const SizedBox(width: 6), // 与“刷新”按钮之间留一点空
            ],
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
                // 品类选择面板
                _VarietyPanel(
                  current: _variety,
                  onChanged: (v) => _load(_city, variety: v),
                ),
                const SizedBox(height: 12),

                // 顶部卡片：昨日均价 + 环比
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
                              '${_data!.city} · ${kVarietyName[_variety]}',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '昨日均价',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _fmtPrice(_data!.yesterdayPrice),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                _MoMChip(
                                  diff: _data!.momDiff,
                                  pct: _data!.momPct,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.trending_up,
                        size: 40,
                        color: Colors.orange.shade600,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 价格趋势（近7日历史 + 未来7日）
                Text(
                  '价格趋势（近7日历史 + 未来7日预测）',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  height: 160,
                  child: _PriceTrendChart(
                    history: _data!.history7,
                    forecast: _data!.forecast7,
                  ),
                ),

                const SizedBox(height: 16),

                // 未来7日预测列表
                Text('未来 7 日预测（元/斤）', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._data!.forecast7.map((p) => _ForecastTile(p: p)).toList(),
              ],
            ),
    );
  }

  String _fmtPrice(double v) => v.toStringAsFixed(2);
}

/// —— 城市一级选择 —— ///
class _CitySheet extends StatelessWidget {
  final List<String> hot;
  final String current;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  const _CitySheet({
    required this.hot,
    required this.onPick,
    required this.onMore,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '选择城市（快捷）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in hot)
                  _pill(
                    context: context,
                    text: c,
                    selected: c == current,
                    onTap: () => onPick(c),
                  ),
                _pill(
                  context: context,
                  text: '更多…',
                  selected: false,
                  onTap: onMore,
                  leading: const Icon(Icons.more_horiz, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required BuildContext context,
    required String text,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    final bg = selected ? Colors.orange.shade100 : Colors.white;
    final bd = selected ? Colors.orange.shade300 : const Color(0xFFE6DACE);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16),
                const SizedBox(width: 6),
              ] else if (leading != null) ...[
                leading,
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// —— 城市二级更多 —— ///
class _MoreCitySheet extends StatelessWidget {
  final List<String> all;
  final String current;
  final ValueChanged<String> onPick;

  const _MoreCitySheet({
    required this.all,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '更多城市',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in all)
                  _pill(
                    context: context,
                    text: c,
                    selected: c == current,
                    onTap: () => onPick(c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required BuildContext context,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bg = selected ? Colors.orange.shade100 : Colors.white;
    final bd = selected ? Colors.orange.shade300 : const Color(0xFFE6DACE);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======= 下方组件：品类、图表、预测条目 =======

class _VarietyPanel extends StatelessWidget {
  final MarketVariety current;
  final ValueChanged<MarketVariety> onChanged;
  const _VarietyPanel({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF7F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEDFD1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_grocery_store_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                '选择品类',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _VarietyGrid(current: current, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _VarietyGrid extends StatelessWidget {
  final MarketVariety current;
  final ValueChanged<MarketVariety> onChanged;
  const _VarietyGrid({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        const cols = 3;
        const hGap = 8.0;
        const vGap = 8.0;
        final itemW = (cons.maxWidth - hGap * (cols - 1)) / cols;

        final items = MarketVariety.values.map((v) {
          final selected = v == current;
          return SizedBox(
            width: itemW,
            height: 40,
            child: _VarietyPill(
              text: kVarietyName[v] ?? v.name,
              selected: selected,
              onTap: () => onChanged(v),
            ),
          );
        }).toList();

        return Wrap(spacing: hGap, runSpacing: vGap, children: items);
      },
    );
  }
}

class _VarietyPill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _VarietyPill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.orange.shade100 : Colors.white;
    final bd = selected ? Colors.orange.shade300 : const Color(0xFFE6DACE);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoMChip extends StatelessWidget {
  final double diff; // 元
  final double pct; // %
  const _MoMChip({required this.diff, required this.pct});

  @override
  Widget build(BuildContext context) {
    final up = diff >= 0;
    final color = up ? Colors.red.shade600 : Colors.green.shade700;
    final icon = up ? Icons.arrow_upward : Icons.arrow_downward;
    final text =
        '${up ? '+' : ''}${diff.toStringAsFixed(2)}（${up ? '+' : ''}${pct.toStringAsFixed(1)}%）';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final PricePoint p;
  const _ForecastTile({required this.p});

  @override
  Widget build(BuildContext context) {
    final dt = p.date;
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
          Expanded(child: Text('${p.price.toStringAsFixed(2)} 元/斤')),
        ],
      ),
    );
  }
}

/// 极简折线图：历史为实线，预测为虚线
class _PriceTrendChart extends StatelessWidget {
  final List<PricePoint> history;
  final List<PricePoint> forecast;
  const _PriceTrendChart({required this.history, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(history: history, forecast: forecast),
      size: Size.infinite,
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<PricePoint> history;
  final List<PricePoint> forecast;
  _TrendPainter({required this.history, required this.forecast});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || forecast.isEmpty) return;

    final all = [...history, ...forecast];
    final minP = all.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxP = all.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final n = all.length;
    double xAt(int i) => pad + (w * i / (n - 1));
    double yAt(double p) {
      final span = (maxP - minP).abs() < 1e-6 ? 1.0 : (maxP - minP);
      final t = (p - minP) / span;
      return pad + (h * (1 - t));
    }

    final paintHist = Paint()
      ..color = const Color(0xFFFB8C00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintForecast = Paint()
      ..color = const Color(0xFFFB8C00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 历史（实线）
    final histPath = Path()..moveTo(xAt(0), yAt(history.first.price));
    for (int i = 1; i < history.length; i++) {
      histPath.lineTo(xAt(i), yAt(history[i].price));
    }
    canvas.drawPath(histPath, paintHist);

    // 预测（虚线）
    final startIndex = history.length - 1;
    const dash = 6.0, gap = 6.0;
    for (int i = startIndex; i < all.length - 1; i++) {
      final p1 = Offset(xAt(i), yAt(all[i].price));
      final p2 = Offset(xAt(i + 1), yAt(all[i + 1].price));
      _drawDashedLine(canvas, p1, p2, paintForecast, dash, gap);
    }

    // 端点标记
    final dotPaint = Paint()..color = const Color(0xFFFB8C00);
    canvas.drawCircle(
      Offset(xAt(history.length - 1), yAt(history.last.price)),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(xAt(all.length - 1), yAt(all.last.price)),
      3,
      dotPaint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    double dash,
    double gap,
  ) {
    final total = (p2 - p1).distance;
    final dir = (p2 - p1) / total;
    double drawn = 0;
    while (drawn < total) {
      final s = p1 + dir * drawn;
      drawn += dash;
      final e = p1 + dir * drawn.clamp(0, total);
      canvas.drawLine(s, e, paint);
      drawn += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.history != history || oldDelegate.forecast != forecast;
}
