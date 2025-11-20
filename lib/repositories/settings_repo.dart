// lib/repositories/settings_repo.dart
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置仓库（精简版）
/// 负责：
///  - 识别服务模式：0=本地Mock，1=HTTP接口
///  - 识别 API 基础地址
///  - 行情服务模式：0=本地Mock，1=HTTP接口（新增）
///  - 行情 API 基础地址（新增）
///  - 行情页选择的 城市 / 品类 记忆
class SettingsRepo {
  // —— 识别服务 —— //
  static const String _kApiMode = 'api_mode'; // 0: Mock, 1: HTTP
  static const String _kApiBase = 'api_base';

  /// 读取识别服务模式（默认 0 = 本地Mock）
  Future<int> getApiMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kApiMode) ?? 0;
  }

  /// 设置识别服务模式（0=Mock，1=HTTP）
  Future<void> setApiMode(int mode) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kApiMode, mode);
  }

  /// 读取识别 API 基础地址（默认空字符串）
  Future<String> getApiBase() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kApiBase) ?? '';
  }

  /// 设置识别 API 基础地址（例如：https://api.example.com）
  Future<void> setApiBase(String base) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kApiBase, base.trim());
  }

  /// （可选）重置与识别接口相关的设置
  Future<void> resetDetectApi() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kApiMode);
    await sp.remove(_kApiBase);
  }

  // —— 行情服务（新增） —— //
  static const String _kMarketApiMode = 'market_api_mode'; // 0: Mock, 1: HTTP
  static const String _kMarketApiBase = 'market_api_base';

  /// 读取行情服务模式（默认 0 = 本地Mock）
  Future<int> getMarketApiMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kMarketApiMode) ?? 0;
  }

  /// 设置行情服务模式（0=Mock，1=HTTP）
  Future<void> setMarketApiMode(int mode) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kMarketApiMode, mode);
  }

  /// 读取行情 API 基础地址（默认空字符串）
  Future<String> getMarketApiBase() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kMarketApiBase) ?? '';
  }

  /// 设置行情 API 基础地址（例如：https://market.example.com）
  Future<void> setMarketApiBase(String base) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kMarketApiBase, base.trim());
  }

  /// （可选）重置行情接口相关的设置
  Future<void> resetMarketApi() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kMarketApiMode);
    await sp.remove(_kMarketApiBase);
  }

  // —— 行情页 城市/品类 记忆 —— //
  static const String _kSelectedCity = 'selected_city';
  static const String _kSelectedVariety = 'selected_variety'; // 存枚举的 name

  Future<void> setSelectedCity(String city) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSelectedCity, city);
  }

  Future<String?> getSelectedCity() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSelectedCity);
  }

  /// 存储所选品类（用 name 字符串：如 'satangJu'）
  Future<void> setSelectedVarietyName(String varietyName) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSelectedVariety, varietyName);
  }

  Future<String?> getSelectedVarietyName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSelectedVariety);
  }
}
