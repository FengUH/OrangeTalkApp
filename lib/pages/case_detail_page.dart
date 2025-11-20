import 'dart:io';
import 'package:flutter/material.dart';

class CaseDetailPage extends StatelessWidget {
  final Map<String, String> item;
  const CaseDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final path = item['imagePath'] ?? '';
    final title = item['title'] ?? '未命名';
    final advice = item['advice'] ?? '';
    final conf = item['confidence'] ?? '';
    final time = item['time'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('病例详情')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (path.isNotEmpty && File(path).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(path), fit: BoxFit.cover),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.06),
                border: Border.all(color: Colors.orange.withOpacity(.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('图片不可用'),
            ),
          const SizedBox(height: 12),
          _KV('病害', title),
          _KV('置信度', '${conf.isEmpty ? '-' : conf}%'),
          _KV('时间', time),
          const SizedBox(height: 8),
          Text('建议：\n$advice'),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$k：',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
