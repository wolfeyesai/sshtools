// ignore_for_file: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// 状态栏模型，存储服务器状态信息
class StatusBarModel extends ChangeNotifier {
  bool _dbStatus = false;
  bool _inferenceStatus = false;
  bool _cardKeyStatus = false;
  bool _keyMouseStatus = false;
  String _updatedAt = '';
  String _createdAt = '';
  
  // 日志标签
  static const String _logTag = 'StatusBarModel';

  // 构造函数
  StatusBarModel() {
    debugPrint('$_logTag: 初始化状态栏模型');
  }

  // Getters
  bool get dbStatus => _dbStatus;
  bool get inferenceStatus => _inferenceStatus;
  bool get cardKeyStatus => _cardKeyStatus;
  bool get keyMouseStatus => _keyMouseStatus;
  String get updatedAt => _updatedAt;
  String get createdAt => _createdAt;

  // 更新状态信息
  void updateStatus({
    required bool dbStatus,
    required bool inferenceStatus,
    required bool cardKeyStatus,
    required bool keyMouseStatus,
    required String updatedAt,
    required String createdAt,
  }) {
    debugPrint('$_logTag: 更新状态信息');
    
    // 记录状态变化
    if (_dbStatus != dbStatus) {
      debugPrint('$_logTag: 数据库状态从 $_dbStatus 变为 $dbStatus');
      _dbStatus = dbStatus;
    }
    
    if (_inferenceStatus != inferenceStatus) {
      debugPrint('$_logTag: 推理状态从 $_inferenceStatus 变为 $inferenceStatus');
      _inferenceStatus = inferenceStatus;
    }
    
    if (_cardKeyStatus != cardKeyStatus) {
      debugPrint('$_logTag: 卡密状态从 $_cardKeyStatus 变为 $cardKeyStatus');
      _cardKeyStatus = cardKeyStatus;
    }
    
    if (_keyMouseStatus != keyMouseStatus) {
      debugPrint('$_logTag: 键鼠状态从 $_keyMouseStatus 变为 $keyMouseStatus');
      _keyMouseStatus = keyMouseStatus;
    }
    
    _updatedAt = updatedAt;
    _createdAt = createdAt;
    
    // 通知监听器
    notifyListeners();
    
    debugPrint('$_logTag: 状态更新完成');
  }

  // 从JSON解析
  void updateFromJson(Map<String, dynamic> json) {
    debugPrint('$_logTag: 从JSON更新状态: ${jsonEncode(json)}');
    
    bool hasChanges = false;
    
    if (json.containsKey('dbStatus')) {
      final bool newValue = json['dbStatus'] as bool;
      if (_dbStatus != newValue) {
        debugPrint('$_logTag: 数据库状态从 $_dbStatus 变为 $newValue');
        _dbStatus = newValue;
        hasChanges = true;
      }
    }
    
    if (json.containsKey('inferenceStatus')) {
      final bool newValue = json['inferenceStatus'] as bool;
      if (_inferenceStatus != newValue) {
        debugPrint('$_logTag: 推理状态从 $_inferenceStatus 变为 $newValue');
        _inferenceStatus = newValue;
        hasChanges = true;
      }
    }
    
    if (json.containsKey('cardKeyStatus')) {
      final bool newValue = json['cardKeyStatus'] as bool;
      if (_cardKeyStatus != newValue) {
        debugPrint('$_logTag: 卡密状态从 $_cardKeyStatus 变为 $newValue');
        _cardKeyStatus = newValue;
        hasChanges = true;
      }
    }
    
    if (json.containsKey('keyMouseStatus')) {
      final bool newValue = json['keyMouseStatus'] as bool;
      if (_keyMouseStatus != newValue) {
        debugPrint('$_logTag: 键鼠状态从 $_keyMouseStatus 变为 $newValue');
        _keyMouseStatus = newValue;
        hasChanges = true;
      }
    }
    
    if (json.containsKey('updatedAt')) {
      final String newValue = json['updatedAt'] as String;
      if (_updatedAt != newValue) {
        _updatedAt = newValue;
        hasChanges = true;
      }
    }
    
    if (json.containsKey('createdAt')) {
      final String newValue = json['createdAt'] as String;
      if (_createdAt != newValue) {
        _createdAt = newValue;
        hasChanges = true;
      }
    }
    
    // 总是通知监听器，因为状态栏需要定期更新，即使没有值变化
    debugPrint('$_logTag: ${hasChanges ? "状态已改变" : "状态无变化但仍"}通知监听器');
    notifyListeners();
  }

  // 重置状态
  void reset() {
    debugPrint('$_logTag: 重置状态');
    
    _dbStatus = false;
    _inferenceStatus = false;
    _cardKeyStatus = false;
    _keyMouseStatus = false;
    _updatedAt = '';
    _createdAt = '';
    
    // 通知监听器
    notifyListeners();
    
    debugPrint('$_logTag: 状态重置完成');
  }
  
  // 返回状态摘要
  String getStatusSummary() {
    return '数据库:${_dbStatus ? '正常' : '异常'}, '
           '推理:${_inferenceStatus ? '正常' : '异常'}, '
           '卡密:${_cardKeyStatus ? '正常' : '异常'}, '
           '键鼠:${_keyMouseStatus ? '正常' : '异常'}';
  }
} 