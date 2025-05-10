// ignore_for_file: use_build_context_synchronously, unused_import, unnecessary_null_comparison, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import '../models/fov_model.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../component/message_component.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // 导入JSON转换库，用于格式化输出
import '../utils/blwebsocket.dart'; // 导入WebSocket工具类
import '../services/server_service.dart'; // 导入ServerService
import '../utils/logger.dart'; // 导入日志工具
import 'dart:async'; // 导入Timer

/// FOV控制器，负责管理视野参数和相关的业务逻辑
class FovController extends ChangeNotifier {
  // 日志标签
  final String _logTag = 'FovController';
  
  // 依赖的服务和模型
  final ServerService _serverService;
  final AuthModel _authModel;
  final FovModel _fovModel;
  final GameModel _gameModel;
  
  // 参数是否已修改标记
  bool _isDirty = false;
  
  // 控制器是否已销毁
  bool _isDisposed = false;
  
  // 日志工具
  final log = Logger();
  
  // Getter
  bool get isDirty => _isDirty;
  
  // 构造函数 - 使用依赖注入
  FovController({
    required ServerService serverService, 
    required AuthModel authModel,
    required FovModel fovModel,
    required GameModel gameModel,
  }) : _serverService = serverService,
       _authModel = authModel,
       _fovModel = fovModel,
       _gameModel = gameModel {
    // 注册WebSocket消息回调
    _registerWebSocketCallback();
    
    // 添加GameModel变更监听
    _gameModel.addListener(_handleGameModelChanged);
    
    // 添加直接游戏变更监听
    _gameModel.addGameChangeListener(_handleGameDirectChange);
    
    // 初始化 - 请求最新的FOV设置
    _init();
  }
  
  /// 初始化控制器
  void _init() {
    log.i(_logTag, '正在初始化FOV控制器');
    
    // 请求最新的FOV配置
    _requestFovConfig();
  }
  
  /// 注册WebSocket消息回调
  void _registerWebSocketCallback() {
    // 订阅相关的WebSocket事件
    _serverService.addMessageListener(_handleWebSocketMessage);
    log.i(_logTag, '已注册WebSocket消息监听器');
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(dynamic message) {
    // 检查控制器是否已被销毁
    if (_isDisposed) {
      return; // 如果控制器已销毁，直接返回不处理
    }
    
    try {
      // 只处理字符串消息
      if (message is! String) return;
      
      // 打印原始消息以便调试
      log.d(_logTag, '收到WebSocket消息', {'raw': message});
      
      // 解析JSON消息
      final Map<String, dynamic> data = jsonDecode(message);
      
      // 获取消息类型
      final String action = data['action'] ?? '';
      
      // 增强调试 - 记录所有接收到的消息类型
      log.d(_logTag, '收到消息类型: $action');
      
      // 只处理与FOV相关的消息，忽略其他类型
      if (!(action.startsWith('fov_') || action == 'function_read')) {
        return; // 忽略非FOV相关的消息
      }
      
      // 处理FOV配置响应
      if (action == 'fov_read_response' || action == 'fov_modify_response' || action == 'fov_read' || action == 'fov_measurement_start') {
        log.i(_logTag, '收到FOV参数响应', {'action': action});
        
        try {
          // 检查响应状态
          final status = data['status'] ?? '';
          if (status == 'success' || status == 'ok') {
            // 提取数据，优先从data字段获取
            Map<String, dynamic>? content;
            
            // 尝试先从data字段获取完整配置
            if (data['data'] != null && data['data'] is Map) {
              content = Map<String, dynamic>.from(data['data'] as Map);
              log.d(_logTag, '从data字段获取数据', content);
            } 
            // 如果data字段不存在，尝试从content字段获取
            else if (data['content'] != null) {
              content = Map<String, dynamic>.from(data['content'] as Map);
              log.d(_logTag, '从content字段获取数据', content);
            }
            
            if (content != null) {
              // 检查游戏名称
              if (content['gameName'] != null && _gameModel != null) {
                final serverGameName = content['gameName'].toString();
                final currentGameName = _gameModel.currentGame;
                
                if (serverGameName != currentGameName) {
                  log.i(_logTag, '游戏名称不一致，服务器返回: $serverGameName，当前设置: $currentGameName');
                }
              }
              
              // 详细记录所有收到的数据
              log.i(_logTag, '收到FOV数据', {
                'fov': content['fov'],
                'fovTime': content['fovTime'],
                'gameName': content['gameName'],
                'username': content['username']
              });
              
              // 立即强制更新
              _updateFromServerResponse(content);
              
              // 确认UI更新
              if (!_isDisposed) {
                Future.microtask(() {
                  log.d(_logTag, 'FOV值更新后的状态', {
                    'fov': _fovModel.fov,
                    'fovTime': _fovModel.fovTime
                  });
                  notifyListeners();
                });
              }
            } else {
              log.w(_logTag, 'FOV响应未包含有效内容');
            }
          } else {
            // 处理错误状态
            log.w(_logTag, 'FOV参数响应状态错误', {'status': status, 'message': data['message'] ?? '未知错误'});
          }
        } catch (e) {
          log.e(_logTag, '处理FOV参数响应数据失败', e.toString());
        }
      }
    } catch (e) {
      log.e(_logTag, '处理WebSocket消息出错', e.toString());
    }
  }
  
  /// 根据服务器响应更新本地参数
  void _updateFromServerResponse(Map<String, dynamic> content) {
    try {
      // 记录接收到的原始内容
      log.d(_logTag, '更新FOV参数 - 原始数据', content);
      
      // 临时对象保存所有更新值，避免多次通知
      Map<String, dynamic> updatedValues = {};
      
      // 提取所有需要更新的字段
      if (content.containsKey('fov')) {
        final fovValue = _parseDouble(content['fov']);
        if (fovValue != null) {
          updatedValues['fov'] = fovValue;
          log.d(_logTag, '提取FOV值', {'value': fovValue});
        }
      }
      
      if (content.containsKey('fovTime')) {
        final fovTimeValue = _parseInt(content['fovTime']);
        if (fovTimeValue != null) {
          updatedValues['fovTime'] = fovTimeValue;
          log.d(_logTag, '提取FOV时间值', {'value': fovTimeValue});
        }
      }
      
      // 记录更新前的值，用于调试
      final beforeValues = {
        'fov': _fovModel.fov,
        'fovTime': _fovModel.fovTime,
      };
      
      // 提取用户和游戏信息
      String username = content.containsKey('username') ? content['username'].toString() : _fovModel.username;
      String gameName = content.containsKey('gameName') ? content['gameName'].toString() : _fovModel.gameName;
      
      // 构建JSON数据用于批量更新
      Map<String, dynamic> jsonData = {
        'content': {
          ...updatedValues,
          'username': username,
          'gameName': gameName,
          'createdAt': content['createdAt'] ?? _fovModel.createdAt,
          'updatedAt': content['updatedAt'] ?? DateTime.now().toIso8601String(),
        }
      };
      
      log.d(_logTag, '准备更新模型 - JSON数据', jsonData);
      
      // 直接设置FOV模型值，确保更新
      if (updatedValues.containsKey('fov')) {
        _fovModel.fov = updatedValues['fov'];
      }
      
      if (updatedValues.containsKey('fovTime')) {
        _fovModel.fovTime = updatedValues['fovTime'];
      }
      
      // 使用FovModel的fromJson方法一次性更新所有参数
      // _fovModel.fromJson(jsonData);
      
      // 记录更新后的值
      final afterValues = {
        'fov': _fovModel.fov,
        'fovTime': _fovModel.fovTime,
      };
      
      // 记录哪些值发生了变化
      final changedValues = <String, dynamic>{};
      beforeValues.forEach((key, value) {
        if (value != afterValues[key]) {
          changedValues[key] = '${value} -> ${afterValues[key]}';
        }
      });
      
      // 重置脏标记，表示这些更改来自服务器
      _isDirty = false;
      
      log.i(_logTag, 'FOV参数更新后状态', {
        'fov': _fovModel.fov,
        'fovTime': _fovModel.fovTime,
        'changedValues': changedValues,
      });
      
      // 确保UI更新，不管是否有变化都通知
      notifyListeners();
      
    } catch (e) {
      log.e(_logTag, '从服务器响应更新参数出错', e.toString());
    }
  }

  /// 安全解析Double值
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 安全解析Int值
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// 处理游戏模型变更
  void _handleGameModelChanged() {
    if (_isDisposed) return;
    
    // 记录游戏变更
    log.i(_logTag, '游戏模型已变更', {'currentGame': _gameModel.currentGame, 'previousGame': _fovModel.gameName});
    
    // 如果游戏名称发生变化，立即更新UI
    if (_fovModel.gameName != _gameModel.currentGame) {
      log.i(_logTag, '游戏已切换，强制刷新FOV设置');
      
      // 暂时清空现有数据，触发UI重置
      _fovModel.gameName = _gameModel.currentGame;
      
      // 通知UI立即更新
      notifyListeners();
      
      // 请求最新的FOV配置
      _requestFovConfig();
    }
  }
  
  /// 直接处理游戏变更事件
  void _handleGameDirectChange(String newGame) {
    if (_isDisposed) return;
    
    log.i(_logTag, '接收到游戏直接变更通知', {'newGame': newGame, 'currentGame': _fovModel.gameName});
    
    // 立即更新FOV模型中的游戏名称
    if (_fovModel.gameName != newGame) {
      _fovModel.gameName = newGame;
      
      // 强制通知UI更新
      notifyListeners();
      
      // 请求新游戏的FOV配置
      _requestFovConfig();
    }
  }
  
  /// 请求最新的FOV配置
  void _requestFovConfig() {
    if (_serverService.isConnected && _authModel.isAuthenticated && _gameModel.currentGame.isNotEmpty) {
      try {
        // 构建请求
        final request = {
          'action': 'fov_read',
          'content': {
            'username': _authModel.username,
            'gameName': _gameModel.currentGame,
            'cardKey': _gameModel.cardKey,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        };
        
        // 发送请求
        final jsonStr = jsonEncode(request);
        _serverService.sendMessage(jsonStr);
        
        log.i(_logTag, '已请求FOV配置', {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey.isNotEmpty ? '已设置' : '未设置',
        });
      } catch (e) {
        log.e(_logTag, '请求FOV配置失败', e.toString());
      }
    } else {
      log.w(_logTag, '无法请求FOV配置，服务未连接或模型未初始化', {
        'isConnected': _serverService.isConnected,
        'isAuthenticated': _authModel.isAuthenticated,
        'currentGame': _gameModel.currentGame,
      });
    }
  }
  
  // Getters - 转发到FovModel
  double get fov => _fovModel.fov;
  int get fovTime => _fovModel.fovTime;
  String get gameName => _fovModel.gameName;
  
  // Setters - 转发到FovModel并标记为已修改
  set fov(double value) {
    if (_fovModel.fov != value) {
      _fovModel.fov = value;
      _isDirty = true;
      log.i(_logTag, '视野范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set fovTime(int value) {
    if (_fovModel.fovTime != value) {
      _fovModel.fovTime = value;
      _isDirty = true;
      log.i(_logTag, '视野时间被修改为: $value');
      notifyListeners();
    }
  }
  
  /// 当参数发生变化时，处理参数变更
  void handleParameterChanged(String paramName, double value, BuildContext context) {
    // 已经在setter中标记了脏标记，这里只需记录日志即可
    log.i(_logTag, '参数变更: $paramName = $value');
    
    // 自动保存修改
    saveFovConfig(context);
  }
  
  /// 开始测量FOV
  void startFovMeasurement(BuildContext context) {
    try {
      // 检查用户名和游戏名是否有效
      final String username = _authModel.username;
      final String gameName = _gameModel.currentGame;
      
      if (username.isEmpty) {
        log.e(_logTag, 'FOV测量失败：用户名为空');
        MessageComponent.showIconToast(
          context: context,
          message: '无法测量：用户名为空',
          type: MessageType.error,
        );
        return;
      }
      
      if (gameName.isEmpty) {
        log.e(_logTag, 'FOV测量失败：游戏名称为空');
        MessageComponent.showIconToast(
          context: context,
          message: '无法测量：游戏名称为空',
          type: MessageType.error,
        );
        return;
      }
      
      // 构建开始测量的JSON消息 - 修改为符合后端期望的格式
      final Map<String, dynamic> measurementRequest = {
        'action': 'fov_measurement_start',
        'content': {
          'username': username,
          'gameName': gameName,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      final String jsonData = jsonEncode(measurementRequest);
      
      log.i(_logTag, '发送开始FOV测量请求', {
        'username': username,
        'gameName': gameName,
        'cardKey': _gameModel.cardKey.isNotEmpty ? '已设置' : '未设置',
      });
      
      // 发送到服务器
      if (_serverService.isConnected) {
        _serverService.sendMessage(jsonData);
        
        MessageComponent.showIconToast(
          context: context,
          message: '开始测量FOV',
          type: MessageType.info,
        );
        
        // 测量完成后延迟刷新数据
        // 服务器处理测量并返回结果可能需要一些时间，所以我们延迟2秒再刷新数据
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            log.i(_logTag, '测量后主动刷新FOV配置');
            _requestFovConfig();
          }
        });
      } else {
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法开始测量',
          type: MessageType.error,
        );
      }
    } catch (e) {
      log.e(_logTag, '开始FOV测量出错', e.toString());
      MessageComponent.showIconToast(
        context: context,
        message: '开始测量出错: $e',
        type: MessageType.error,
      );
    }
  }
  
  /// 保存FOV配置
  Future<void> saveFovConfig(BuildContext context) async {
    try {
      // 如果没有变更，不进行保存
      if (!_isDirty) {
        log.i(_logTag, '没有修改，无需保存');
        MessageComponent.showIconToast(
          context: context,
          message: '无变更，无需保存',
          type: MessageType.info,
        );
        return;
      }
      
      // 更新用户和游戏信息
      _fovModel.updateUserGameInfo(
        _authModel.username,
        _gameModel.currentGame
      );
      
      // 获取完整的配置JSON
      final String jsonData = _fovModel.toJsonString();
      
      log.i(_logTag, '发送FOV配置', {'data': jsonData});
      
      // 发送到服务器
      if (_serverService.isConnected) {
        _serverService.sendMessage(jsonData);
        
        _isDirty = false;
        await _fovModel.saveSettings();
        
        MessageComponent.showIconToast(
          context: context,
          message: 'FOV参数已保存',
          type: MessageType.success,
        );
      } else {
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法保存',
          type: MessageType.error,
        );
      }
    } catch (e) {
      log.e(_logTag, '保存FOV配置出错', e.toString());
      MessageComponent.showIconToast(
        context: context,
        message: '保存出错: $e',
        type: MessageType.error,
      );
    }
  }
  
  /// 重置为默认值
  void resetToDefaults(BuildContext context) {
    try {
      // 使用FovModel的重置方法
      _fovModel.resetToDefaults();
      
      _isDirty = true;
      
      log.i(_logTag, '重置为默认值');
      
      MessageComponent.showIconToast(
        context: context,
        message: '已重置为默认值',
        type: MessageType.info,
      );
      
      notifyListeners();
    } catch (e) {
      log.e(_logTag, '重置为默认值出错', e.toString());
      MessageComponent.showIconToast(
        context: context,
        message: '重置出错: $e',
        type: MessageType.error,
      );
    }
  }
  
  /// 手动处理游戏变更，供视图调用
  void handleGameChanged(String newGameName) {
    if (_fovModel.gameName != newGameName) {
      log.i(_logTag, '手动触发游戏变更', {'oldGame': _fovModel.gameName, 'newGame': newGameName});
      
      // 更新游戏名称
      _fovModel.gameName = newGameName;
      
      // 通知UI更新
      notifyListeners();
      
      // 请求新游戏的FOV配置
      _requestFovConfig();
    }
  }
  
  /// 供视图调用的公共方法，请求刷新当前游戏的FOV配置
  void refreshFovConfig() {
    _requestFovConfig();
  }
  
  @override
  void dispose() {
    // 标记控制器已销毁
    _isDisposed = true;
    
    // 移除WebSocket回调
    _serverService.removeMessageListener(_handleWebSocketMessage);
    
    // 移除GameModel监听
    _gameModel.removeListener(_handleGameModelChanged);
    
    // 移除直接游戏变更监听
    _gameModel.removeGameChangeListener(_handleGameDirectChange);
    
    log.i(_logTag, '释放资源');
    super.dispose();
  }
}
