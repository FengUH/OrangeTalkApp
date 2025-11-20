import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../repositories/history_repo.dart';
import '../repositories/settings_repo.dart';
import '../services/detect_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  bool _running = false;
  _Result? _result; // UI 层使用的结果模型（与 DetectResult 对齐）

  // 选择：拍照
  Future<void> _takePhoto() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (x != null) {
        setState(() {
          _imageFile = File(x.path);
          _result = null;
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前设备不支持拍照，请使用真机，或从相册选择。')));
    }
  }

  // 选择：相册
  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() {
        _imageFile = File(x.path);
        _result = null;
      });
    }
  }

  // 开始识别：根据个人中心设置选择 Mock 或 HTTP
  Future<void> _runDetect() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先拍照或选择一张柑橘叶片照片')));
      return;
    }
    setState(() {
      _running = true;
      _result = null;
    });

    try {
      final mode = await SettingsRepo().getApiMode(); // 0: 本地Mock, 1: HTTP
      final base = await SettingsRepo().getApiBase();

      DetectResult dr;
      if (mode == 1) {
        // HTTP 接口
        if (base.isEmpty) {
          throw Exception('HTTP 模式已开启，但 API 基础地址为空，请前往“个人中心”设置。');
        }
        dr = await DetectService.I.diagnoseHttp(
          apiBase: base,
          imageFile: _imageFile!,
        );
      } else {
        // 本地 Mock
        dr = await DetectService.I.diagnoseMock();
      }

      setState(() {
        _running = false;
        _result = _Result(
          name: dr.name,
          confidence: dr.confidence,
          advice: dr.advice,
        );
      });
    } catch (e) {
      setState(() => _running = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('识别失败'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 保存到病例库
  Future<void> _saveToCases() async {
    if (_imageFile == null || _result == null) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final casesDir = Directory(p.join(docDir.path, 'cases'));
      if (!await casesDir.exists()) {
        await casesDir.create(recursive: true);
      }
      final fileName =
          'case_${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path).isEmpty ? ".jpg" : p.extension(_imageFile!.path)}';
      final savedPath = p.join(casesDir.path, fileName);
      await _imageFile!.copy(savedPath);

      await HistoryRepo().addCase(
        imagePath: savedPath,
        title: _result!.name,
        advice: _result!.advice,
        confidence: _result!.confidence,
        time: DateTime.now(),
      );

      // 读一次总量做提示
      final all = await HistoryRepo().load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已保存到病例库 ✅（共 ${all.length} 条）')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识别'),
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('请选择或拍摄柑橘叶片照片 🍊', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('拍照'),
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('相册'),
                  onPressed: _pickFromGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_imageFile != null)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
                color: Colors.white,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            )
          else
            _PlaceholderCard(),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_running ? '识别中...' : '开始识别'),
              onPressed: _running ? null : _runDetect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_result != null) ...[
            _ResultCard(result: _result!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                label: const Text('保存到病例库'),
                onPressed: _saveToCases,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ====== 小部件与 UI 层数据结构 ======

class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Text(
        '未选择图片',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}

class _Result {
  final String name;
  final double confidence;
  final String advice;
  const _Result({
    required this.name,
    required this.confidence,
    required this.advice,
  });
}

class _ResultCard extends StatelessWidget {
  final _Result result;
  const _ResultCard({required this.result});

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
          Text('识别结果', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('病害：${result.name}'),
          Text('置信度：${(result.confidence * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          Text('建议：${result.advice}'),
        ],
      ),
    );
  }
}
