import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/history_repo.dart';
import 'case_detail_page.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  State<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  List<Map<String, String>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await HistoryRepo().load();
    // 按时间倒序
    list.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空病例库'),
        content: const Text('确定要删除全部病例记录吗？该操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistoryRepo().clear();
      if (mounted) {
        setState(() => _items.clear());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清空病例库')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('病例库'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清空',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Text(
                '暂无病例记录',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemBuilder: (_, i) {
                final m = _items[i];
                final path = m['imagePath'] ?? '';
                final title = m['title'] ?? '未命名';
                final timeStr = m['time'] ?? '';
                String nice = timeStr;
                try {
                  final dt = DateTime.parse(timeStr);
                  nice = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                } catch (_) {}
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CaseDetailPage(item: m)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: (path.isNotEmpty && File(path).existsSync())
                                ? Image.file(File(path), fit: BoxFit.cover)
                                : Container(
                                    color: Colors.orange.withOpacity(.08),
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                nice,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: _items.length,
            ),
    );
  }
}
