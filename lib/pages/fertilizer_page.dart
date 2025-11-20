import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FertilizerPage extends StatefulWidget {
  const FertilizerPage({super.key});

  @override
  State<FertilizerPage> createState() => _FertilizerPageState();
}

class _FertilizerPageState extends State<FertilizerPage> {
  final TextEditingController _areaCtrl = TextEditingController(text: '200');
  String _unit = '亩';
  double _age = 10;
  final TextEditingController _targetYieldCtrl = TextEditingController(
    text: '2',
  );
  String _soil = '红壤（南方常见）';
  String _season = '春季';

  bool _hasResult = false;
  double? _nPerMu;
  double? _p2o5PerMu;
  double? _k2oPerMu;
  double? _nTotal;
  double? _p2o5Total;
  double? _k2oTotal;

  void _calc() {
    final double area = double.tryParse(_areaCtrl.text.trim()) ?? 0;
    final double target = double.tryParse(_targetYieldCtrl.text.trim()) ?? 0;

    double soilK = switch (_soil) {
      '红壤（南方常见）' => 1.0,
      '黄壤（酸性）' => 1.05,
      '沙壤（保肥差）' => 1.15,
      '壤土（综合性好）' => 0.95,
      _ => 1.0,
    };

    double seasonK = switch (_season) {
      '春季' => 1.0,
      '夏季' => 1.1,
      '秋季' => 0.95,
      '冬季' => 0.9,
      _ => 1.0,
    };

    double ageK = (8 <= _age && _age <= 15) ? 1.0 : (_age < 8 ? 0.85 : 1.1);

    const baseN = 3.5, baseP2O5 = 1.4, baseK2O = 2.3;

    _nPerMu = baseN * target * soilK * seasonK * ageK;
    _p2o5PerMu = baseP2O5 * target * soilK * seasonK * ageK;
    _k2oPerMu = baseK2O * target * soilK * seasonK * ageK;

    _nTotal = _nPerMu! * area;
    _p2o5Total = _p2o5PerMu! * area;
    _k2oTotal = _k2oPerMu! * area;

    setState(() => _hasResult = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已根据当前参数计算推荐用量（演示）。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyResult() {
    if (!_hasResult) return;
    final text =
        '''
【施肥推荐】
按亩推荐（kg/亩）
氮 N：${_nPerMu!.toStringAsFixed(2)}
磷 P₂O₅：${_p2o5PerMu!.toStringAsFixed(2)}
钾 K₂O：${_k2oPerMu!.toStringAsFixed(2)}

全园合计（kg）
氮 N：${_nTotal!.toStringAsFixed(2)}
磷 P₂O₅：${_p2o5Total!.toStringAsFixed(2)}
钾 K₂O：${_k2oTotal!.toStringAsFixed(2)}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制推荐用量到剪贴板 ✅'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('施肥计算器')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TextFieldBox(
                        label: '面积',
                        controller: _areaCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DropdownBox<String>(
                        label: '单位',
                        value: _unit,
                        onChanged: (v) => setState(() => _unit = v!),
                        items: const ['亩', '公顷'],
                        singleLine: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _LabelRow(
                  label: '树龄：',
                  trailing: Text(
                    '${_age.round()} 年',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Slider(
                  value: _age,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  activeColor: Colors.orange.shade800,
                  onChanged: (v) => setState(() => _age = v),
                ),
                const SizedBox(height: 8),
                _TextFieldBox(
                  label: '目标产量（kg/亩）',
                  controller: _targetYieldCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DropdownBox<String>(
                        label: '土壤类型',
                        value: _soil,
                        onChanged: (v) => setState(() => _soil = v!),
                        items: const [
                          '红壤（南方常见）',
                          '黄壤（酸性）',
                          '沙壤（保肥差）',
                          '壤土（综合性好）',
                        ],
                        singleLine: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DropdownBox<String>(
                        label: '当前季节/计划',
                        value: _season,
                        onChanged: (v) => setState(() => _season = v!),
                        items: const ['春季', '夏季', '秋季', '冬季'],
                        singleLine: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('计算推荐用量'),
                    onPressed: _calc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_hasResult) ...[
            Row(
              children: [
                Expanded(
                  child: _ResultCard(
                    title: '按亩推荐（kg/亩）',
                    n: _nPerMu!,
                    p: _p2o5PerMu!,
                    k: _k2oPerMu!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResultCard(
                    title: '全园合计（kg）',
                    n: _nTotal!,
                    p: _p2o5Total!,
                    k: _k2oTotal!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ✅ 新增复制按钮
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_all_outlined, size: 20),
                label: const Text('复制推荐用量'),
                onPressed: _copyResult,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            _AdviceCard(season: _season),
          ],

          const SizedBox(height: 20),
          Text(
            '提示：本页为演示用经验模型。后续可接入专家规则/土壤检测/叶片营养数据，自动生成更精准的配方与品牌推荐。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== 小部件 ==================

class _TextFieldBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _TextFieldBox({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final bool singleLine;

  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.singleLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          alignment: AlignmentDirectional.centerStart,
          menuMaxHeight: 360,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    e.toString(),
                    maxLines: singleLine ? 1 : null,
                    overflow: singleLine
                        ? TextOverflow.ellipsis
                        : TextOverflow.clip,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _LabelRow({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final double n;
  final double p;
  final double k;

  const _ResultCard({
    required this.title,
    required this.n,
    required this.p,
    required this.k,
  });

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Text('氮 N：${_fmt(n)}'),
          Text('磷 P₂O₅：${_fmt(p)}'),
          Text('钾 K₂O：${_fmt(k)}'),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String season;
  const _AdviceCard({super.key, required this.season});

  String seasonAdvice(String s) {
    switch (s) {
      case '春季':
        return '春季以促梢促花为主，氮磷钾均衡，适量补镁锌。';
      case '夏季':
        return '夏季高温多雨，控氮稳钾，注意补钙和硼以防裂果落果。';
      case '秋季':
        return '秋季增钾提糖，适量补磷促根，减少氮肥以利转色。';
      case '冬季':
        return '冬季以基肥为主，腐熟有机肥+中微量元素，提升来年树势。';
      default:
        return '根据物候期动态调整：抽梢期偏氮，坐果期偏钾，转色期控氮增钾。';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.12)),
      ),
      child: Text(
        '全年施肥节奏建议（$season）\n${seasonAdvice(season)}',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
