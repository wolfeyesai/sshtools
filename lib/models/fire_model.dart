import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 射击设置模型 - 管理射击相关的数据
class FireModel extends ChangeNotifier {
  // 射击参数
  double _fireSpeed = 0.1;
  int _fireDelay = 100;
  double _recoilControl = 0.5;
  bool _autoFire = false;
  int _burstCount = 3;
  
  // 元数据
  String _username = 'admin';
  String _gameName = 'csgo2';
  String _createdAt = '';
  String _updatedAt = '';
  
  // 默认值 - 用于重置
  final double _defaultFireSpeed = 0.1;
  final int _defaultFireDelay = 100;
  final double _defaultRecoilControl = 0.5;
  final bool _defaultAutoFire = false;
  final int _defaultBurstCount = 3;
  
  // Getters
  double get fireSpeed => _fireSpeed;
  int get fireDelay => _fireDelay;
  double get recoilControl => _recoilControl;
  bool get autoFire => _autoFire;
  int get burstCount => _burstCount;
  String get username => _username;
  String get gameName => _gameName;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  // Setters
  set fireSpeed(double value) {
    if (_fireSpeed != value) {
      _fireSpeed = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set fireDelay(int value) {
    if (_fireDelay != value) {
      _fireDelay = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set recoilControl(double value) {
    if (_recoilControl != value) {
      _recoilControl = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set autoFire(bool value) {
    if (_autoFire != value) {
      _autoFire = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set burstCount(int value) {
    if (_burstCount != value) {
      _burstCount = value;
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
  FireModel() {
    loadSettings();
  }
  
  /// 更新时间戳
  void _updateTimestamp() {
    _updatedAt = DateTime.now().toIso8601String();
  }
  
  /// 重置为默认值
  void resetToDefaults() {
    _fireSpeed = _defaultFireSpeed;
    _fireDelay = _defaultFireDelay;
    _recoilControl = _defaultRecoilControl;
    _autoFire = _defaultAutoFire;
    _burstCount = _defaultBurstCount;
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从配置中加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载射击参数
    _fireSpeed = prefs.getDouble('fire_fireSpeed') ?? _defaultFireSpeed;
    _fireDelay = prefs.getInt('fire_fireDelay') ?? _defaultFireDelay;
    _recoilControl = prefs.getDouble('fire_recoilControl') ?? _defaultRecoilControl;
    _autoFire = prefs.getBool('fire_autoFire') ?? _defaultAutoFire;
    _burstCount = prefs.getInt('fire_burstCount') ?? _defaultBurstCount;
    
    // 加载元数据
    _username = prefs.getString('fire_username') ?? _username;
    _gameName = prefs.getString('fire_gameName') ?? _gameName;
    _createdAt = prefs.getString('fire_createdAt') ?? '';
    _updatedAt = prefs.getString('fire_updatedAt') ?? '';
    
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
    
    // 保存射击参数
    await prefs.setDouble('fire_fireSpeed', _fireSpeed);
    await prefs.setInt('fire_fireDelay', _fireDelay);
    await prefs.setDouble('fire_recoilControl', _recoilControl);
    await prefs.setBool('fire_autoFire', _autoFire);
    await prefs.setInt('fire_burstCount', _burstCount);
    
    // 保存元数据
    await prefs.setString('fire_username', _username);
    await prefs.setString('fire_gameName', _gameName);
    await prefs.setString('fire_createdAt', _createdAt);
    await prefs.setString('fire_updatedAt', _updatedAt);
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
      _fireSpeed = content['fireSpeed'] ?? _fireSpeed;
      _fireDelay = content['fireDelay'] ?? _fireDelay;
      _recoilControl = content['recoilControl'] ?? _recoilControl;
      _autoFire = content['autoFire'] ?? _autoFire;
      _burstCount = content['burstCount'] ?? _burstCount;
      
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
      'action': 'fire_modify',
      'content': {
        'username': _username,
        'gameName': _gameName,
        'fireSpeed': _fireSpeed,
        'fireDelay': _fireDelay,
        'recoilControl': _recoilControl,
        'autoFire': _autoFire,
        'burstCount': _burstCount,
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