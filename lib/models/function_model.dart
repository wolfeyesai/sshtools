// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 功能配置模型 - 管理功能页面所需的数据
class FunctionModel extends ChangeNotifier {
  // 默认值
  final Map<String, List<String>> _defaults = {
    'hotkeys': ['左键', '右键', '中键', '前侧', '后侧'],
    'aiModes': ['PID', 'FOV', 'FOVPID'],
    'lockPositions': ['头部', '颈部', '胸部'],
  };
  
  List<String> _hotkeys = [];
  List<String> _aiModes = [];
  List<String> _lockPositions = [];
  List<Map<String, dynamic>> _configs = [];
  String _createdAt = DateTime.now().toIso8601String();
  String _updatedAt = DateTime.now().toIso8601String();
  
  // Getters
  List<String> get hotkeys => _hotkeys;
  List<String> get aiModes => _aiModes;
  List<String> get lockPositions => _lockPositions;
  List<Map<String, dynamic>> get configs => _configs;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  FunctionModel() {
    _hotkeys = List.from(_defaults['hotkeys']!);
    _aiModes = List.from(_defaults['aiModes']!);
    _lockPositions = List.from(_defaults['lockPositions']!);
    _initDefaultConfigs();
  }
  
  /// 初始化默认配置
  void _initDefaultConfigs() {
    _configs = [
      {
        'presetName': '配置1',
        'hotkey': '右键',
        'aiMode': 'FOV',
        'lockPosition': '头部',
        'triggerSwitch': true,
        'enabled': true,
      },
      {
        'presetName': '配置2',
        'hotkey': '右键',
        'aiMode': 'FOV',
        'lockPosition': '颈部',
        'triggerSwitch': false,
        'enabled': false,
      },
      {
        'presetName': '配置3',
        'hotkey': '左键',
        'aiMode': 'FOV',
        'lockPosition': '胸部',
        'triggerSwitch': true,
        'enabled': false,
      },
      {
        'presetName': '配置4',
        'hotkey': '左键',
        'aiMode': 'FOV',
        'lockPosition': '颈部',
        'triggerSwitch': false,
        'enabled': false,
      }
    ];
    
    notifyListeners();
  }
  
  /// 从持久化存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载列表数据
    _hotkeys = prefs.getStringList('function_hotkeys') ?? _defaults['hotkeys']!;
    _aiModes = prefs.getStringList('function_aiModes') ?? _defaults['aiModes']!;
    _lockPositions = prefs.getStringList('function_lockPositions') ?? _defaults['lockPositions']!;
    
    // 加载配置列表
    final savedConfigsJson = prefs.getString('function_configs');
    if (savedConfigsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedConfigsJson);
        _configs = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print('解析配置时出错: $e');
      }
    }
    
    // 加载时间戳
    _createdAt = prefs.getString('function_createdAt') ?? _createdAt;
    _updatedAt = prefs.getString('function_updatedAt') ?? _updatedAt;
    
    notifyListeners();
  }
  
  /// 保存设置到持久化存储
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList('function_hotkeys', _hotkeys);
    await prefs.setStringList('function_aiModes', _aiModes);
    await prefs.setStringList('function_lockPositions', _lockPositions);
    await prefs.setString('function_configs', jsonEncode(_configs));
    await prefs.setString('function_createdAt', _createdAt);
    await prefs.setString('function_updatedAt', _updatedAt);
  }
  
  /// 添加配置
  void addConfig({
    required String presetName,
    String? hotkey,
    String? aiMode,
    String? lockPosition,
    bool? triggerSwitch,
    bool? enabled,
  }) {
    final newConfig = {
      'presetName': presetName,
      'hotkey': hotkey ?? _hotkeys.first,
      'aiMode': aiMode ?? _aiModes.first,
      'lockPosition': lockPosition ?? _lockPositions.first,
      'triggerSwitch': triggerSwitch ?? false,
      'enabled': enabled ?? true,
    };
    
    _configs.add(newConfig);
    _updatedAt = DateTime.now().toIso8601String();
    saveSettings();
    notifyListeners();
  }
  
  /// 更新配置
  void updateConfig(String presetName, String property, dynamic value) {
    for (var config in _configs) {
      if (config['presetName'] == presetName) {
        config[property] = value;
        _updatedAt = DateTime.now().toIso8601String();
        saveSettings();
        notifyListeners();
        break;
      }
    }
  }
  
  /// 设置整个配置列表
  void setConfigs(List<Map<String, dynamic>> configs) {
    _configs = List<Map<String, dynamic>>.from(configs);
    _updatedAt = DateTime.now().toIso8601String();
    saveSettings();
    notifyListeners();
  }
  
  /// 从JSON字符串加载配置
  void loadFromJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      if (data.containsKey('hotkey')) {
        _hotkeys = (data['hotkey'] as List).cast<String>();
      }
      
      if (data.containsKey('aiMode')) {
        _aiModes = (data['aiMode'] as List).cast<String>();
      }
      
      if (data.containsKey('lockPosition')) {
        _lockPositions = (data['lockPosition'] as List).cast<String>();
      }
      
      if (data.containsKey('content') && data['content'].containsKey('configs')) {
        _configs = (data['content']['configs'] as List).cast<Map<String, dynamic>>();
      }
      
      _updatedAt = DateTime.now().toIso8601String();
      saveSettings();
      notifyListeners();
    } catch (e) {
      print('解析JSON时出错: $e');
    }
  }
  
  /// 转换为JSON字符串
  String toJson() {
    final Map<String, dynamic> data = {
      'hotkey': _hotkeys,
      'aiMode': _aiModes,
      'lockPosition': _lockPositions,
      'content': {
        'configs': _configs,
        'createdAt': _createdAt,
        'updatedAt': _updatedAt,
      }
    };
    
    return jsonEncode(data);
  }
} 