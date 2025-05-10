import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 视野设置模型 - 管理FOV相关的数据
class FovModel extends ChangeNotifier {
  // FOV参数
  double _fov = 90.0;
  int _fovTime = 1000;
  
  // 元数据
  String _username = 'admin';
  String _gameName = 'csgo2';
  String _createdAt = '';
  String _updatedAt = '';
  
  // 默认值 - 用于重置
  final double _defaultFov = 0.7;
  final int _defaultFovTime = 500;
  
  // Getters
  double get fov => _fov;
  int get fovTime => _fovTime;
  String get username => _username;
  String get gameName => _gameName;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  // Setters
  set fov(double value) {
    if (_fov != value) {
      _fov = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set fovTime(int value) {
    if (_fovTime != value) {
      _fovTime = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set username(String value) {
    if (_username != value) {
      _username = value;
      notifyListeners();
    }
  }
  
  set gameName(String value) {
    if (_gameName != value) {
      _gameName = value;
      notifyListeners();
    }
  }
  
  /// 构造函数
  FovModel() {
    loadSettings();
  }
  
  /// 更新时间戳
  void _updateTimestamp() {
    _updatedAt = DateTime.now().toIso8601String();
  }
  
  /// 重置为默认值
  void resetToDefaults() {
    _fov = _defaultFov;
    _fovTime = _defaultFovTime;
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从配置中加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载FOV参数
    _fov = prefs.getDouble('fov_fov') ?? _defaultFov;
    _fovTime = prefs.getInt('fov_fovTime') ?? _defaultFovTime;
    
    // 加载元数据
    _username = prefs.getString('fov_username') ?? _username;
    _gameName = prefs.getString('fov_gameName') ?? _gameName;
    _createdAt = prefs.getString('fov_createdAt') ?? '';
    _updatedAt = prefs.getString('fov_updatedAt') ?? '';
    
    // 如果是首次加载，创建时间戳
    if (_createdAt.isEmpty) {
      _createdAt = DateTime.now().toIso8601String();
      _updatedAt = _createdAt;
    }
    
    notifyListeners();
  }
  
  /// 保存设置到持久化存储
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存FOV参数
    await prefs.setDouble('fov_fov', _fov);
    await prefs.setInt('fov_fovTime', _fovTime);
    
    // 保存元数据
    await prefs.setString('fov_username', _username);
    await prefs.setString('fov_gameName', _gameName);
    await prefs.setString('fov_createdAt', _createdAt);
    await prefs.setString('fov_updatedAt', _updatedAt);
  }
  
  /// 更新用户和游戏信息
  void updateUserGameInfo(String username, String gameName) {
    _username = username;
    _gameName = gameName;
    _updatedAt = DateTime.now().toIso8601String();
    notifyListeners();
  }
  
  /// 从JSON获取配置
  void fromJson(Map<String, dynamic> json) {
    if (json['content'] != null) {
      final content = json['content'];
      _fov = content['fov'] ?? _fov;
      _fovTime = content['fovTime'] ?? _fovTime;
      
      _username = content['username'] ?? _username;
      _gameName = content['gameName'] ?? _gameName;
      _createdAt = content['createdAt'] ?? _createdAt;
      _updatedAt = content['updatedAt'] ?? _updatedAt;
    }
    
    notifyListeners();
  }
  
  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'action': 'fov_modify',
      'content': {
        'username': _username,
        'gameName': _gameName,
        'fov': _fov,
        'fovTime': _fovTime,
        'createdAt': _createdAt,
        'updatedAt': _updatedAt,
      }
    };
  }
  
  /// 获取JSON字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }
} 