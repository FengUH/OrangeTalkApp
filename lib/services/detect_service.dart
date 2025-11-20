// lib/services/detect_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 统一的识别结果数据结构
class DetectResult {
  final String name;
  final double confidence;
  final String advice;

  DetectResult({
    required this.name,
    required this.confidence,
    required this.advice,
  });

  /// 尝试从多种后端 JSON 结构里解析，尽量兼容：
  /// A) {"label": "...", "confidence": 0.86, "advice": "..."}
  /// B) {"disease": "...", "prob": 0.86, "suggestion": "..."}
  /// C) {"result": {"name": "...", "score": 0.86, "advice": "..."}}
  factory DetectResult.fromDynamicJson(Map<String, dynamic> j) {
    String? name;
    double? conf;
    String? advice;

    if (j.containsKey('label')) name = j['label']?.toString();
    if (j.containsKey('disease')) name = j['disease']?.toString();
    if (j.containsKey('name')) name = j['name']?.toString();

    if (j.containsKey('confidence'))
      conf = (j['confidence'] as num?)?.toDouble();
    if (j.containsKey('prob')) conf = (j['prob'] as num?)?.toDouble();
    if (j.containsKey('score')) conf = (j['score'] as num?)?.toDouble();

    if (j.containsKey('advice')) advice = j['advice']?.toString();
    if (j.containsKey('suggestion')) advice = j['suggestion']?.toString();

    if ((name == null || conf == null) && j['result'] is Map) {
      final r = Map<String, dynamic>.from(j['result']);
      return DetectResult.fromDynamicJson(r);
    }

    return DetectResult(
      name: name ?? '未识别',
      confidence: conf ?? 0.0,
      advice: advice ?? '暂无建议',
    );
  }
}

class DetectService {
  DetectService._();
  static final DetectService I = DetectService._();

  /// 本地 Mock：用于演示/离线调试
  Future<DetectResult> diagnoseMock({
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    return DetectResult(
      name: '炭疽病（演示）',
      confidence: 0.86,
      advice: '建议修剪病叶并喷施含咪鲜胺或代森锰锌的药剂；雨季注意排水，减少孢子传播。',
    );
  }

  /// 真实接口：multipart/form-data 上传图片
  /// 期望后端地址： POST {apiBase}/diagnose
  /// - 默认表单字段名：file（可通过 fieldName 调整）
  /// - 可传自定义 headers/extraFields
  Future<DetectResult> diagnoseHttp({
    required String apiBase,
    required File imageFile,
    String fieldName = 'file',
    Map<String, String>? extraFields,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final base = apiBase.trim();

    if (base.isEmpty) {
      throw Exception('HTTP 模式已开启，但 API 基础地址为空，请先在“个人中心”设置。');
    }
    // 防呆：示例域名直接提示
    if (base.contains('api.example.com')) {
      throw Exception('当前 API 地址是示例域名（api.example.com），请改为你的真实后端地址。');
    }

    // 协议校验
    final uriBase = Uri.tryParse(base);
    if (uriBase == null ||
        !(uriBase.isScheme('https') || uriBase.isScheme('http'))) {
      throw Exception(
        'API 基础地址必须以 http:// 或 https:// 开头，例如：https://your.domain.com',
      );
    }

    final uri = Uri.parse(_join(base, '/diagnose'));
    final req = http.MultipartRequest('POST', uri);

    if (extraFields != null) req.fields.addAll(extraFields);
    if (headers != null) req.headers.addAll(headers);

    final file = await http.MultipartFile.fromPath(fieldName, imageFile.path);
    req.files.add(file);

    http.StreamedResponse streamed;
    try {
      streamed = await req.send().timeout(timeout);
    } on SocketException catch (e) {
      throw Exception('无法连接服务：${e.message}（检查域名/IP、网络、防火墙/VPN、是否同一网络）');
    } on TimeoutException {
      throw Exception('请求超时，请检查服务是否可达，或增大超时时间');
    }

    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception(
        'HTTP ${resp.statusCode}: ${resp.reasonPhrase}\nBody: ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body);
    if (data is Map<String, dynamic>) {
      return DetectResult.fromDynamicJson(data);
    } else {
      throw Exception('响应格式不正确：${resp.body}');
    }
  }

  String _join(String base, String path) {
    var b = base;
    var p = path;
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    if (!p.startsWith('/')) p = '/$p';
    return '$b$p';
  }
}
