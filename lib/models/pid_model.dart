// ignore_for_file: unused_import, unused_element

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// PID设置模型 - 管理近端瞄准控制相关的数据
class PidModel extends ChangeNotifier {
  // 默认值和配置项定义
  final Map<String, dynamic> _defaults = {
    'nearMoveFactor': 1.0,       // 近端移动系数
    'nearStabilizer': 0.5,       // 近端稳定器强度
    'nearResponseRate': 0.3,     // 近端响应速率
    'nearAssistZone': 3.0,       // 近端辅助区域
    'nearResponseDelay': 1.0,    // 近端响应延迟
    'nearMaxAdjustment': 2.0,    // 近端最大调整量
    'farFactor': 1.0,            // 远端系数
  };
  
  // PID参数
  double _nearMoveFactor = 1.0;      // 近端移动系数
  double _nearStabilizer = 0.5;      // 近端稳定器强度
  double _nearResponseRate = 0.3;    // 近端响应速率
  double _nearAssistZone = 3.0;      // 近端辅助区域
  double _nearResponseDelay = 1.0;   // 近端响应延迟
  double _nearMaxAdjustment = 2.0;   // 近端最大调整量
  double _farFactor = 1.0;           // 远端系数
  
  // 元数据
  String _username = 'admin';
  String _gameName = 'csgo2';
  String _createdAt = '';
  String _updatedAt = '';
  
  // Getters
  double get nearMoveFactor => _nearMoveFactor;
  double get nearStabilizer => _nearStabilizer;
  double get nearResponseRate => _nearResponseRate;
  double get nearAssistZone => _nearAssistZone;
  double get nearResponseDelay => _nearResponseDelay;
  double get nearMaxAdjustment => _nearMaxAdjustment;
  double get farFactor => _farFactor;
  String get username => _username;
  String get gameName => _gameName;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  // Setters
  set nearMoveFactor(double value) {
    if (_nearMoveFactor != value) {
      _nearMoveFactor = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set nearStabilizer(double value) {
    if (_nearStabilizer != value) {
      _nearStabilizer = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set nearResponseRate(double value) {
    if (_nearResponseRate != value) {
      _nearResponseRate = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set nearAssistZone(double value) {
    if (_nearAssistZone != value) {
      _nearAssistZone = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set nearResponseDelay(double value) {
    if (_nearResponseDelay != value) {
      _nearResponseDelay = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set nearMaxAdjustment(double value) {
    if (_nearMaxAdjustment != value) {
      _nearMaxAdjustment = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set farFactor(double value) {
    if (_farFactor != value) {
      _farFactor = value;
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
  PidModel() {
    loadSettings();
  }
  
  /// 更新时间戳
  void _updateTimestamp() {
    _updatedAt = DateTime.now().toIso8601String();
  }
  
  /// 重置为默认值
  void resetToDefaults() {
    _nearMoveFactor = _defaults['nearMoveFactor'];
    _nearStabilizer = _defaults['nearStabilizer'];
    _nearResponseRate = _defaults['nearResponseRate'];
    _nearAssistZone = _defaults['nearAssistZone'];
    _nearResponseDelay = _defaults['nearResponseDelay'];
    _nearMaxAdjustment = _defaults['nearMaxAdjustment'];
    _farFactor = _defaults['farFactor'];
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从配置中加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载PID参数
    _nearMoveFactor = prefs.getDouble('pid_nearMoveFactor') ?? _defaults['nearMoveFactor'];
    _nearStabilizer = prefs.getDouble('pid_nearStabilizer') ?? _defaults['nearStabilizer'];
    _nearResponseRate = prefs.getDouble('pid_nearResponseRate') ?? _defaults['nearResponseRate'];
    _nearAssistZone = prefs.getDouble('pid_nearAssistZone') ?? _defaults['nearAssistZone'];
    _nearResponseDelay = prefs.getDouble('pid_nearResponseDelay') ?? _defaults['nearResponseDelay'];
    _nearMaxAdjustment = prefs.getDouble('pid_nearMaxAdjustment') ?? _defaults['nearMaxAdjustment'];
    _farFactor = prefs.getDouble('pid_farFactor') ?? _defaults['farFactor'];
    
    // 加载元数据
    _username = prefs.getString('pid_username') ?? _username;
    _gameName = prefs.getString('pid_gameName') ?? _gameName;
    _createdAt = prefs.getString('pid_createdAt') ?? '';
    _updatedAt = prefs.getString('pid_updatedAt') ?? '';
    
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
    
    // 保存PID参数
    await prefs.setDouble('pid_nearMoveFactor', _nearMoveFactor);
    await prefs.setDouble('pid_nearStabilizer', _nearStabilizer);
    await prefs.setDouble('pid_nearResponseRate', _nearResponseRate);
    await prefs.setDouble('pid_nearAssistZone', _nearAssistZone);
    await prefs.setDouble('pid_nearResponseDelay', _nearResponseDelay);
    await prefs.setDouble('pid_nearMaxAdjustment', _nearMaxAdjustment);
    await prefs.setDouble('pid_farFactor', _farFactor);
    
    // 保存元数据
    await prefs.setString('pid_username', _username);
    await prefs.setString('pid_gameName', _gameName);
    await prefs.setString('pid_createdAt', _createdAt);
    await prefs.setString('pid_updatedAt', _updatedAt);
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
      
      // 使用统一的方式设置参数
      if (content['nearMoveFactor'] != null) {
        _nearMoveFactor = _parseDoubleValue(content['nearMoveFactor']);
      }
      
      if (content['nearStabilizer'] != null) {
        _nearStabilizer = _parseDoubleValue(content['nearStabilizer']);
      }
      
      if (content['nearResponseRate'] != null) {
        _nearResponseRate = _parseDoubleValue(content['nearResponseRate']);
      }
      
      if (content['nearAssistZone'] != null) {
        _nearAssistZone = _parseDoubleValue(content['nearAssistZone']);
      }
      
      if (content['nearResponseDelay'] != null) {
        _nearResponseDelay = _parseDoubleValue(content['nearResponseDelay']);
      }
      
      if (content['nearMaxAdjustment'] != null) {
        _nearMaxAdjustment = _parseDoubleValue(content['nearMaxAdjustment']);
      }
      
      if (content['farFactor'] != null) {
        _farFactor = _parseDoubleValue(content['farFactor']);
      }
      
      // 设置元数据
      if (content['username'] != null) _username = content['username'].toString();
      if (content['gameName'] != null) _gameName = content['gameName'].toString();
      if (content['createdAt'] != null) _createdAt = content['createdAt'].toString();
      if (content['updatedAt'] != null) _updatedAt = content['updatedAt'].toString();
    }
    
    notifyListeners();
  }
  
  /// 安全解析double值，处理各种可能的输入类型
  double _parseDoubleValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
  
  /// 安全解析int值，处理各种可能的输入类型
  int _parseIntValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        try {
          return double.parse(value).toInt();
        } catch (e) {
          return 0;
        }
      }
    }
    return 0;
  }
} 