// ignore_for_file: use_build_context_synchronously, unused_import, unused_field, depend_on_referenced_packages, unnecessary_import

import 'package:flutter/material.dart';
import '../models/data_collection_model.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../component/message_component.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // 导入JSON转换库，用于格式化输出
import '../utils/blwebsocket.dart'; // 导入WebSocket工具类
import '../services/server_service.dart'; // 导入ServerService
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

/// 数据收集控制器 - 连接UI与数据收集模型
class DataCollectionController extends ChangeNotifier {
  // 数据收集模型
  final DataCollectionModel _dataCollectionModel;
  
  // 服务相关的依赖
  final ServerService _serverService;
  final AuthModel _authModel;
  final GameModel _gameModel;
  
  // 日志工具
  final log = Logger('DataCollectionController');
  
  // WebSocket请求超时时间
  static const int _requestTimeoutSeconds = 5;
  
  // 属性映射，用于UI与模型之间的数据转换
  bool get isEnabled => _dataCollectionModel.isEnabled;
  int get sampleRate => _dataCollectionModel.sampleRate;
  bool get collectPerformance => _dataCollectionModel.collectMouseData;
  bool get collectUserInput => _dataCollectionModel.collectKeyboardData;
  bool get collectGameEvents => _dataCollectionModel.collectGameplayData;
  
  // 确保dataRetentionDays的值在1-90范围内
  int get dataRetentionDays {
    // 简化计算：每天5MB
    int days = _dataCollectionModel.maxStorageMB ~/ 5;
    // 确保返回值不超过90天
    return days > 90 ? 90 : (days < 1 ? 1 : days);
  }
  
  bool get autoUpload => _dataCollectionModel.uploadFrequency != 'manual';
  String get uploadFrequency => _convertUploadFrequency(_dataCollectionModel.uploadFrequency);
  
  // 设置属性
  set isEnabled(bool value) {
    _dataCollectionModel.isEnabled = value;
    // 这里不需要notifyListeners，因为_dataCollectionModel已经会通知
  }
  
  set sampleRate(int value) {
    if (value > 0 && value <= 60) {
      _dataCollectionModel.sampleRate = value;
    }
  }
  
  set collectPerformance(bool value) {
    _dataCollectionModel.collectMouseData = value;
  }
  
  set collectUserInput(bool value) {
    _dataCollectionModel.collectKeyboardData = value;
  }
  
  set collectGameEvents(bool value) {
    _dataCollectionModel.collectGameplayData = value;
  }
  
  set dataRetentionDays(int value) {
    // 确保值在1-90范围内
    int safeValue = value;
    if (value < 1) safeValue = 1;
    if (value > 90) safeValue = 90;
    
    // 简化转换：5MB每天
    _dataCollectionModel.maxStorageMB = safeValue * 5;
  }
  
  set autoUpload(bool value) {
    if (value) {
      // 如果启用自动上传，设置为每天
      if (_dataCollectionModel.uploadFrequency == 'manual') {
        _dataCollectionModel.uploadFrequency = 'daily';
      }
    } else {
      // 如果禁用自动上传，设置为手动
      _dataCollectionModel.uploadFrequency = 'manual';
    }
  }
  
  set uploadFrequency(String value) {
    // 将UI友好的字符串转换为存储格式
    String storedValue;
    switch (value) {
      case '实时':
        storedValue = 'realtime';
        break;
      case '每小时':
        storedValue = 'hourly';
        break;
      case '每天':
        storedValue = 'daily';
        break;
      case '每周':
        storedValue = 'weekly';
        break;
      default:
        storedValue = 'daily'; // 默认每天
    }
    _dataCollectionModel.uploadFrequency = storedValue;
  }
  
  /// 构造函数
  DataCollectionController({
    required DataCollectionModel dataCollectionModel,
    required ServerService serverService,
    required AuthModel authModel,
    required GameModel gameModel,
  }) : 
    _dataCollectionModel = dataCollectionModel,
    _serverService = serverService,
    _authModel = authModel,
    _gameModel = gameModel {
      // 初始化WebSocket监听
      _initWebSocketListeners();
      
      // 当数据收集模型发生变化时通知UI
      _dataCollectionModel.addListener(_onModelChanged);
      
      // 从服务器获取最新设置
      _fetchSettingsFromServer();
  }
  
  @override
  void dispose() {
    // 取消监听以防止内存泄漏
    _dataCollectionModel.removeListener(_onModelChanged);
    super.dispose();
  }
  
  /// 数据模型变化处理
  void _onModelChanged() {
    notifyListeners();
  }
  
  /// 从服务器获取设置
  Future<void> _fetchSettingsFromServer() async {
    if (!_serverService.isConnected) {
      log.warning('WebSocket未连接，无法获取数据收集设置');
      return;
    }
    
    try {
      final request = {
        'action': 'data_collection_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
        }
      };
      
      _serverService.sendMessage(jsonEncode(request));
      log.info('已发送数据收集设置获取请求');
    } catch (e) {
      log.severe('发送数据收集设置请求时出错: $e');
    }
  }
  
  /// 初始化WebSocket监听器
  void _initWebSocketListeners() {
    _serverService.addMessageListener((dynamic message) {
      if (message is String) {
        _handleWebSocketMessage(message);
      }
    });
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(String message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String action = data['action'] ?? '';
      
      if (action == 'data_collection_read_response' || 
          action == 'data_collection_modify_response') {
        // 更新数据收集模型
        _dataCollectionModel.fromJson(data);
        log.info('已从服务器更新数据收集设置');
      }
    } catch (e) {
      log.warning('处理WebSocket消息时出错: $e');
    }
  }
  
  /// 保存设置到服务器和本地存储
  Future<void> saveSettings(BuildContext context) async {
    try {
      // 先保存到本地
      await _dataCollectionModel.saveSettings();
      
      // 然后发送到服务器
      if (_serverService.isConnected) {
        final request = _dataCollectionModel.toJson();
        _serverService.sendMessage(jsonEncode(request));
        log.info('已发送数据收集设置更新请求');
        
        // 显示成功消息
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设置已保存')),
          );
        }
      } else {
        // 显示离线保存消息
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设置已保存到本地，但未能同步到服务器(离线模式)')),
          );
        }
      }
    } catch (e) {
      log.severe('保存数据收集设置时出错: $e');
      // 显示错误消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存设置失败: $e')),
        );
      }
    }
  }
  
  /// 重置所有设置为默认值
  void resetToDefaults() {
    _dataCollectionModel.resetToDefaults();
    log.info('数据收集设置已重置为默认值');
  }
  
  /// 清除所有收集的数据
  Future<void> clearAllData() async {
    try {
      if (_serverService.isConnected) {
        final request = {
          'action': 'data_collection_clear',
          'content': {
            'username': _authModel.username,
            'gameName': _gameModel.currentGame,
            'clearAll': true
          }
        };
        
        _serverService.sendMessage(jsonEncode(request));
        log.info('已发送清除所有数据请求');
        
        // 重置统计数据
        _dataCollectionModel.updateStatistics(
          samplesCount: 0,
          storageMB: 0,
          uploadDate: ''
        );
      } else {
        log.warning('WebSocket未连接，无法清除服务器数据');
      }
    } catch (e) {
      log.severe('清除数据时出错: $e');
    }
  }
  
  /// 将存储的频率值转换为UI友好的字符串
  String _convertUploadFrequency(String storedValue) {
    switch (storedValue) {
      case 'realtime':
        return '实时';
      case 'hourly':
        return '每小时';
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      default:
        return '每天'; // 默认返回每天
    }
  }
} 