// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 瞄准设置模型 - 管理瞄准相关的数据
class AimModel extends ChangeNotifier {
  // 默认值和配置项定义
  final Map<String, double> _defaults = {
    'aimRange': 100.0,
    'trackRange': 50.0,
    'headHeight': 10.0,
    'neckHeight': 8.0,
    'chestHeight': 6.0,
    'headRangeX': 0.5,
    'headRangeY': 0.5,
    'neckRangeX': 0.4,
    'neckRangeY': 0.4,
    'chestRangeX': 0.6,
    'chestRangeY': 0.6,
  };
  
  // 瞄准参数
  double _aimRange = 100.0;
  double _trackRange = 50.0;
  double _headHeight = 10.0;
  double _neckHeight = 8.0;
  double _chestHeight = 6.0;
  double _headRangeX = 0.5;
  double _headRangeY = 0.5;
  double _neckRangeX = 0.4;
  double _neckRangeY = 0.4;
  double _chestRangeX = 0.6;
  double _chestRangeY = 0.6;
  
  // 元数据
  String _username = 'admin';
  String _gameName = 'csgo2';
  String _createdAt = '';
  String _updatedAt = '';
  
  // Getters
  double get aimRange => _aimRange;
  double get trackRange => _trackRange;
  double get headHeight => _headHeight;
  double get neckHeight => _neckHeight;
  double get chestHeight => _chestHeight;
  double get headRangeX => _headRangeX;
  double get headRangeY => _headRangeY;
  double get neckRangeX => _neckRangeX;
  double get neckRangeY => _neckRangeY;
  double get chestRangeX => _chestRangeX;
  double get chestRangeY => _chestRangeY;
  String get username => _username;
  String get gameName => _gameName;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  // Setters
  set aimRange(double value) {
    if (_aimRange != value) {
      _aimRange = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set trackRange(double value) {
    if (_trackRange != value) {
      _trackRange = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set headHeight(double value) {
    if (_headHeight != value) {
      _headHeight = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set neckHeight(double value) {
    if (_neckHeight != value) {
      _neckHeight = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set chestHeight(double value) {
    if (_chestHeight != value) {
      _chestHeight = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set headRangeX(double value) {
    if (_headRangeX != value) {
      _headRangeX = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set headRangeY(double value) {
    if (_headRangeY != value) {
      _headRangeY = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set neckRangeX(double value) {
    if (_neckRangeX != value) {
      _neckRangeX = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set neckRangeY(double value) {
    if (_neckRangeY != value) {
      _neckRangeY = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set chestRangeX(double value) {
    if (_chestRangeX != value) {
      _chestRangeX = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set chestRangeY(double value) {
    if (_chestRangeY != value) {
      _chestRangeY = value;
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
  AimModel() {
    // 从默认值初始化
    _initFromDefaults();
    loadSettings();
  }
  
  /// 从默认值初始化所有参数
  void _initFromDefaults() {
    _aimRange = _defaults['aimRange']!;
    _trackRange = _defaults['trackRange']!;
    _headHeight = _defaults['headHeight']!;
    _neckHeight = _defaults['neckHeight']!;
    _chestHeight = _defaults['chestHeight']!;
    _headRangeX = _defaults['headRangeX']!;
    _headRangeY = _defaults['headRangeY']!;
    _neckRangeX = _defaults['neckRangeX']!;
    _neckRangeY = _defaults['neckRangeY']!;
    _chestRangeX = _defaults['chestRangeX']!;
    _chestRangeY = _defaults['chestRangeY']!;
  }
  
  /// 更新时间戳
  void _updateTimestamp() {
    _updatedAt = DateTime.now().toIso8601String();
  }
  
  /// 重置为默认值
  void resetToDefaults() {
    _initFromDefaults();
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从配置中加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载瞄准参数
    _aimRange = prefs.getDouble('aim_aimRange') ?? _defaults['aimRange']!;
    _trackRange = prefs.getDouble('aim_trackRange') ?? _defaults['trackRange']!;
    _headHeight = prefs.getDouble('aim_headHeight') ?? _defaults['headHeight']!;
    _neckHeight = prefs.getDouble('aim_neckHeight') ?? _defaults['neckHeight']!;
    _chestHeight = prefs.getDouble('aim_chestHeight') ?? _defaults['chestHeight']!;
    _headRangeX = prefs.getDouble('aim_headRangeX') ?? _defaults['headRangeX']!;
    _headRangeY = prefs.getDouble('aim_headRangeY') ?? _defaults['headRangeY']!;
    _neckRangeX = prefs.getDouble('aim_neckRangeX') ?? _defaults['neckRangeX']!;
    _neckRangeY = prefs.getDouble('aim_neckRangeY') ?? _defaults['neckRangeY']!;
    _chestRangeX = prefs.getDouble('aim_chestRangeX') ?? _defaults['chestRangeX']!;
    _chestRangeY = prefs.getDouble('aim_chestRangeY') ?? _defaults['chestRangeY']!;
    
    // 加载元数据
    _username = prefs.getString('aim_username') ?? _username;
    _gameName = prefs.getString('aim_gameName') ?? _gameName;
    _createdAt = prefs.getString('aim_createdAt') ?? '';
    _updatedAt = prefs.getString('aim_updatedAt') ?? '';
    
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
    
    // 保存瞄准参数
    await prefs.setDouble('aim_aimRange', _aimRange);
    await prefs.setDouble('aim_trackRange', _trackRange);
    await prefs.setDouble('aim_headHeight', _headHeight);
    await prefs.setDouble('aim_neckHeight', _neckHeight);
    await prefs.setDouble('aim_chestHeight', _chestHeight);
    await prefs.setDouble('aim_headRangeX', _headRangeX);
    await prefs.setDouble('aim_headRangeY', _headRangeY);
    await prefs.setDouble('aim_neckRangeX', _neckRangeX);
    await prefs.setDouble('aim_neckRangeY', _neckRangeY);
    await prefs.setDouble('aim_chestRangeX', _chestRangeX);
    await prefs.setDouble('aim_chestRangeY', _chestRangeY);
    
    // 保存元数据
    await prefs.setString('aim_username', _username);
    await prefs.setString('aim_gameName', _gameName);
    await prefs.setString('aim_createdAt', _createdAt);
    await prefs.setString('aim_updatedAt', _updatedAt);
  }
  
  /// 更新用户游戏信息
  void updateUserGameInfo(String username, String gameName) {
    _username = username;
    _gameName = gameName;
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从JSON获取配置
  void fromJson(Map<String, dynamic> json) {
    if (json['content'] != null) {
      final content = json['content'];
      
      // 设置参数值，使用当前值作为默认值
      if (content['aimRange'] != null) _aimRange = content['aimRange'];
      if (content['trackRange'] != null) _trackRange = content['trackRange'];
      if (content['headHeight'] != null) _headHeight = content['headHeight'];
      if (content['neckHeight'] != null) _neckHeight = content['neckHeight'];
      if (content['chestHeight'] != null) _chestHeight = content['chestHeight'];
      if (content['headRangeX'] != null) _headRangeX = content['headRangeX'];
      if (content['headRangeY'] != null) _headRangeY = content['headRangeY'];
      if (content['neckRangeX'] != null) _neckRangeX = content['neckRangeX'];
      if (content['neckRangeY'] != null) _neckRangeY = content['neckRangeY'];
      if (content['chestRangeX'] != null) _chestRangeX = content['chestRangeX'];
      if (content['chestRangeY'] != null) _chestRangeY = content['chestRangeY'];
      
      // 设置元数据
      if (content['username'] != null) _username = content['username'];
      if (content['gameName'] != null) _gameName = content['gameName'];
      if (content['createdAt'] != null) _createdAt = content['createdAt'];
      if (content['updatedAt'] != null) _updatedAt = content['updatedAt'];
    }
    
    notifyListeners();
  }
  
  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'action': 'aim_modify',
      'content': {
        'username': _username,
        'gameName': _gameName,
        'aimRange': _aimRange,
        'trackRange': _trackRange,
        'headHeight': _headHeight,
        'neckHeight': _neckHeight,
        'chestHeight': _chestHeight,
        'headRangeX': _headRangeX,
        'headRangeY': _headRangeY,
        'neckRangeX': _neckRangeX,
        'neckRangeY': _neckRangeY,
        'chestRangeX': _chestRangeX,
        'chestRangeY': _chestRangeY,
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