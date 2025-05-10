import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 数据收集模型 - 管理数据收集相关的配置和状态
class DataCollectionModel extends ChangeNotifier {
  // 数据收集参数
  bool _isEnabled = false;
  bool _collectMouseData = true;
  bool _collectKeyboardData = true;
  bool _collectGameplayData = true;
  int _sampleRate = 60;
  int _maxStorageMB = 500;
  String _uploadFrequency = 'daily'; // 'manual', 'daily', 'weekly'
  
  // 元数据
  String _username = 'admin';
  String _gameName = 'csgo2';
  String _createdAt = '';
  String _updatedAt = '';
  
  // 默认值 - 用于重置
  final bool _defaultIsEnabled = false;
  final bool _defaultCollectMouseData = true;
  final bool _defaultCollectKeyboardData = true;
  final bool _defaultCollectGameplayData = true;
  final int _defaultSampleRate = 60;
  final int _defaultMaxStorageMB = 500;
  final String _defaultUploadFrequency = 'daily';
  
  // 统计数据 (只读)
  int _totalCollectedSamples = 0;
  int _currentStorageUsedMB = 0;
  String _lastUploadDate = '';
  
  // Getters
  bool get isEnabled => _isEnabled;
  bool get collectMouseData => _collectMouseData;
  bool get collectKeyboardData => _collectKeyboardData;
  bool get collectGameplayData => _collectGameplayData;
  int get sampleRate => _sampleRate;
  int get maxStorageMB => _maxStorageMB;
  String get uploadFrequency => _uploadFrequency;
  String get username => _username;
  String get gameName => _gameName;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  
  // 统计数据 Getters
  int get totalCollectedSamples => _totalCollectedSamples;
  int get currentStorageUsedMB => _currentStorageUsedMB;
  String get lastUploadDate => _lastUploadDate;
  
  // Setters
  set isEnabled(bool value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set collectMouseData(bool value) {
    if (_collectMouseData != value) {
      _collectMouseData = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set collectKeyboardData(bool value) {
    if (_collectKeyboardData != value) {
      _collectKeyboardData = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set collectGameplayData(bool value) {
    if (_collectGameplayData != value) {
      _collectGameplayData = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set sampleRate(int value) {
    if (_sampleRate != value && value > 0) {
      _sampleRate = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set maxStorageMB(int value) {
    if (_maxStorageMB != value && value > 0) {
      _maxStorageMB = value;
      _updateTimestamp();
      notifyListeners();
    }
  }
  
  set uploadFrequency(String value) {
    if (_uploadFrequency != value && 
        (value == 'manual' || value == 'daily' || value == 'weekly')) {
      _uploadFrequency = value;
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
  DataCollectionModel() {
    loadSettings();
  }
  
  /// 更新时间戳
  void _updateTimestamp() {
    _updatedAt = DateTime.now().toIso8601String();
  }
  
  /// 重置为默认值
  void resetToDefaults() {
    _isEnabled = _defaultIsEnabled;
    _collectMouseData = _defaultCollectMouseData;
    _collectKeyboardData = _defaultCollectKeyboardData;
    _collectGameplayData = _defaultCollectGameplayData;
    _sampleRate = _defaultSampleRate;
    _maxStorageMB = _defaultMaxStorageMB;
    _uploadFrequency = _defaultUploadFrequency;
    _updateTimestamp();
    notifyListeners();
  }
  
  /// 从配置中加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载数据收集参数
    _isEnabled = prefs.getBool('data_isEnabled') ?? _defaultIsEnabled;
    _collectMouseData = prefs.getBool('data_collectMouseData') ?? _defaultCollectMouseData;
    _collectKeyboardData = prefs.getBool('data_collectKeyboardData') ?? _defaultCollectKeyboardData;
    _collectGameplayData = prefs.getBool('data_collectGameplayData') ?? _defaultCollectGameplayData;
    _sampleRate = prefs.getInt('data_sampleRate') ?? _defaultSampleRate;
    _maxStorageMB = prefs.getInt('data_maxStorageMB') ?? _defaultMaxStorageMB;
    _uploadFrequency = prefs.getString('data_uploadFrequency') ?? _defaultUploadFrequency;
    
    // 加载统计数据
    _totalCollectedSamples = prefs.getInt('data_totalCollectedSamples') ?? 0;
    _currentStorageUsedMB = prefs.getInt('data_currentStorageUsedMB') ?? 0;
    _lastUploadDate = prefs.getString('data_lastUploadDate') ?? '';
    
    // 加载元数据
    _username = prefs.getString('data_username') ?? _username;
    _gameName = prefs.getString('data_gameName') ?? _gameName;
    _createdAt = prefs.getString('data_createdAt') ?? '';
    _updatedAt = prefs.getString('data_updatedAt') ?? '';
    
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
    
    // 保存数据收集参数
    await prefs.setBool('data_isEnabled', _isEnabled);
    await prefs.setBool('data_collectMouseData', _collectMouseData);
    await prefs.setBool('data_collectKeyboardData', _collectKeyboardData);
    await prefs.setBool('data_collectGameplayData', _collectGameplayData);
    await prefs.setInt('data_sampleRate', _sampleRate);
    await prefs.setInt('data_maxStorageMB', _maxStorageMB);
    await prefs.setString('data_uploadFrequency', _uploadFrequency);
    
    // 保存统计数据
    await prefs.setInt('data_totalCollectedSamples', _totalCollectedSamples);
    await prefs.setInt('data_currentStorageUsedMB', _currentStorageUsedMB);
    await prefs.setString('data_lastUploadDate', _lastUploadDate);
    
    // 保存元数据
    await prefs.setString('data_username', _username);
    await prefs.setString('data_gameName', _gameName);
    await prefs.setString('data_createdAt', _createdAt);
    await prefs.setString('data_updatedAt', _updatedAt);
  }
  
  /// 更新用户和游戏信息
  void updateUserGameInfo(String username, String gameName) {
    _username = username;
    _gameName = gameName;
    _updatedAt = DateTime.now().toIso8601String();
    notifyListeners();
  }
  
  /// 更新统计数据
  void updateStatistics({int? samplesCount, int? storageMB, String? uploadDate}) {
    bool hasChanges = false;
    
    if (samplesCount != null) {
      _totalCollectedSamples = samplesCount;
      hasChanges = true;
    }
    
    if (storageMB != null) {
      _currentStorageUsedMB = storageMB;
      hasChanges = true;
    }
    
    if (uploadDate != null) {
      _lastUploadDate = uploadDate;
      hasChanges = true;
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// 从JSON获取配置
  void fromJson(Map<String, dynamic> json) {
    if (json['content'] != null) {
      final content = json['content'];
      _isEnabled = content['isEnabled'] ?? _isEnabled;
      _collectMouseData = content['collectMouseData'] ?? _collectMouseData;
      _collectKeyboardData = content['collectKeyboardData'] ?? _collectKeyboardData;
      _collectGameplayData = content['collectGameplayData'] ?? _collectGameplayData;
      _sampleRate = content['sampleRate'] ?? _sampleRate;
      _maxStorageMB = content['maxStorageMB'] ?? _maxStorageMB;
      _uploadFrequency = content['uploadFrequency'] ?? _uploadFrequency;
      
      _username = content['username'] ?? _username;
      _gameName = content['gameName'] ?? _gameName;
      _createdAt = content['createdAt'] ?? _createdAt;
      _updatedAt = content['updatedAt'] ?? _updatedAt;
      
      // 统计数据可能在响应中
      if (content['totalCollectedSamples'] != null) {
        _totalCollectedSamples = content['totalCollectedSamples'];
      }
      if (content['currentStorageUsedMB'] != null) {
        _currentStorageUsedMB = content['currentStorageUsedMB'];
      }
      if (content['lastUploadDate'] != null) {
        _lastUploadDate = content['lastUploadDate'];
      }
    }
    
    notifyListeners();
  }
  
  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'action': 'data_collection_modify',
      'content': {
        'username': _username,
        'gameName': _gameName,
        'isEnabled': _isEnabled,
        'collectMouseData': _collectMouseData,
        'collectKeyboardData': _collectKeyboardData,
        'collectGameplayData': _collectGameplayData,
        'sampleRate': _sampleRate,
        'maxStorageMB': _maxStorageMB,
        'uploadFrequency': _uploadFrequency,
        'totalCollectedSamples': _totalCollectedSamples,
        'currentStorageUsedMB': _currentStorageUsedMB,
        'lastUploadDate': _lastUploadDate,
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