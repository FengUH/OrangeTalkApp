import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/settings_repo.dart';
import 'cases_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _settings = SettingsRepo();

  // —— 识别服务 —— //
  final TextEditingController _apiBaseCtrl = TextEditingController();
  int _apiMode = 0;

  // —— 行情服务（新增） —— //
  final TextEditingController _marketApiBaseCtrl = TextEditingController();
  int _marketApiMode = 0;

  bool _loading = true;
  bool _savingDetect = false;
  bool _savingMarket = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await _settings.getApiMode();
    final base = await _settings.getApiBase();
    final mMode = await _settings.getMarketApiMode();
    final mBase = await _settings.getMarketApiBase();
    setState(() {
      _apiMode = mode;
      _apiBaseCtrl.text = base;
      _marketApiMode = mMode;
      _marketApiBaseCtrl.text = mBase;
      _loading = false;
    });
  }

  Future<void> _saveDetect() async {
    setState(() => _savingDetect = true);
    try {
      await _settings.setApiMode(_apiMode);
      await _settings.setApiBase(_apiBaseCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存识别服务设置')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _savingDetect = false);
    }
  }

  Future<void> _saveMarket() async {
    setState(() => _savingMarket = true);
    try {
      await _settings.setMarketApiMode(_marketApiMode);
      await _settings.setMarketApiBase(_marketApiBaseCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存行情服务设置')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _savingMarket = false);
    }
  }

  @override
  void dispose() {
    _apiBaseCtrl.dispose();
    _marketApiBaseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ====== 识别服务设置卡片（原有） ======
                _SettingsCard(
                  title: '识别服务设置',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Segment(
                        value: _apiMode,
                        onChanged: (v) => setState(() => _apiMode = v),
                        left: '本地Mock',
                        right: 'HTTP接口',
                      ),
                      const SizedBox(height: 12),
                      _UrlField(
                        controller: _apiBaseCtrl,
                        label: 'API 基础地址（如：https://api.example.com）',
                        hint: 'HTTP 模式必填；Mock 可留空',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '提示：开启 HTTP 接口后，识别页会把图片通过 multipart/form-data 发送到 '
                        '“{API_BASE}/diagnose”。后端应返回包含 label / confidence / advice（或兼容字段）的 JSON。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SaveButton(
                        saving: _savingDetect,
                        onPressed: _savingDetect ? null : _saveDetect,
                        text: '保存',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ====== 行情服务设置卡片（新增） ======
                _SettingsCard(
                  title: '行情服务设置',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Segment(
                        value: _marketApiMode,
                        onChanged: (v) => setState(() => _marketApiMode = v),
                        left: '本地Mock',
                        right: 'HTTP接口',
                      ),
                      const SizedBox(height: 12),
                      _UrlField(
                        controller: _marketApiBaseCtrl,
                        label: '行情 API 基础地址（如：https://market.example.com）',
                        hint: 'HTTP 模式必填；Mock 可留空',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '说明：行情页会从 “{MARKET_API_BASE}/market/{variety}?city=南宁&h=7” 拉取数据；'
                        '若未配置或访问失败，将自动回退到本地 Mock 生成数据。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SaveButton(
                        saving: _savingMarket,
                        onPressed: _savingMarket ? null : _saveMarket,
                        text: '保存',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ====== 病例库入口 ======
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CasesPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(.18)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('病例库')),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ====== 版本信息 ======
                Text('版本', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Citrus Helper · Demo v0.1',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
    );
  }
}

/// —— 通用小组件 —— ///
class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String left;
  final String right;
  const _Segment({
    required this.value,
    required this.onChanged,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoSegmentedControl<int>(
            groupValue: value,
            padding: EdgeInsets.zero,
            children: {
              0: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(left),
              ),
              1: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(right),
              ),
            },
            onValueChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _UrlField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          tooltip: '粘贴',
          icon: const Icon(Icons.paste),
          onPressed: () async {
            try {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final txt = (data?.text ?? '').trim();
              if (txt.isNotEmpty) {
                controller
                  ..text = txt
                  ..selection = TextSelection.collapsed(offset: txt.length);
                // 轻提示
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已粘贴到输入框')));
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('剪贴板没有可粘贴的文本')));
              }
            } catch (e) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('粘贴失败：$e')));
            }
          },
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;
  final String text;
  const _SaveButton({
    required this.saving,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(saving ? '保存中...' : text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
