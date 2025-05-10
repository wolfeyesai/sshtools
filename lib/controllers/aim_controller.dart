// ignore_for_file: use_build_context_synchronously, unused_import, unnecessary_null_comparison, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import '../models/aim_model.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../component/message_component.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // 导入JSON转换库，用于格式化输出
import '../utils/blwebsocket.dart'; // 导入WebSocket工具类
import '../services/server_service.dart'; // 导入ServerService
import '../utils/logger.dart'; // 导入日志工具

/// 瞄准控制器，负责管理瞄准参数和相关的业务逻辑
class AimController extends ChangeNotifier {
  // 日志标签
  final String _logTag = 'AimController';
  
  // 依赖的服务和模型
  final ServerService _serverService;
  final AuthModel _authModel;
  final AimModel _aimModel;
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
  AimController({
    required ServerService serverService, 
    required AuthModel authModel,
    required AimModel aimModel,
    required GameModel gameModel,
  }) : _serverService = serverService,
       _authModel = authModel,
       _aimModel = aimModel,
       _gameModel = gameModel {
    // 注册WebSocket消息回调
    _registerWebSocketCallback();
    
    // 添加GameModel变更监听
    _gameModel.addListener(_handleGameModelChanged);
    
    // 初始化 - 请求最新的瞄准设置
    _init();
  }
  
  /// 初始化控制器
  void _init() {
    log.i(_logTag, '正在初始化瞄准控制器');
    
    // 请求最新的瞄准配置
    _requestAimConfig();
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
      
      // 只处理与瞄准相关的消息，忽略其他类型
      if (!action.startsWith('aim_')) {
        return; // 忽略非瞄准相关的消息
      }
      
      // 处理瞄准配置响应
      if (action == 'aim_read_response' || action == 'aim_modify_response' || action == 'aim_read') {
        log.i(_logTag, '收到瞄准参数响应', {'action': action});
        
        try {
          // 检查响应状态
          final status = data['status'] ?? '';
          if (status == 'success' || status == 'ok') {
            // 提取数据，优先从data字段获取
            Map<String, dynamic>? content;
            
            // 尝试先从data字段获取完整配置
            if (data['data'] != null && data['data'] is Map) {
              content = Map<String, dynamic>.from(data['data'] as Map);
              log.d(_logTag, '从data字段获取数据');
            } 
            // 如果data字段不存在，尝试从content字段获取
            else if (data['content'] != null) {
              content = Map<String, dynamic>.from(data['content'] as Map);
              log.d(_logTag, '从content字段获取数据');
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
              
              // 直接调用更新方法，不进行额外的延迟判断
              _updateFromServerResponse(content);
            } else {
              log.w(_logTag, '瞄准响应未包含有效内容');
            }
          } else {
            // 处理错误状态
            log.w(_logTag, '瞄准参数响应状态错误', {'status': status, 'message': data['message'] ?? '未知错误'});
          }
        } catch (e) {
          log.e(_logTag, '处理瞄准参数响应数据失败', e.toString());
        }
      }
    } catch (e) {
      log.e(_logTag, '处理WebSocket消息出错', e.toString());
    }
  }
  
  /// 根据服务器响应更新本地参数
  void _updateFromServerResponse(Map<String, dynamic> content) {
    try {
      // 临时对象保存所有更新值，避免多次通知
      Map<String, dynamic> updatedValues = {};
      
      // 提取所有需要更新的字段
      if (content.containsKey('aimRange')) updatedValues['aimRange'] = _parseDouble(content['aimRange']);
      if (content.containsKey('trackRange')) updatedValues['trackRange'] = _parseDouble(content['trackRange']);
      if (content.containsKey('headHeight')) updatedValues['headHeight'] = _parseDouble(content['headHeight']);
      if (content.containsKey('neckHeight')) updatedValues['neckHeight'] = _parseDouble(content['neckHeight']);
      if (content.containsKey('chestHeight')) updatedValues['chestHeight'] = _parseDouble(content['chestHeight']);
      if (content.containsKey('headRangeX')) updatedValues['headRangeX'] = _parseDouble(content['headRangeX']);
      if (content.containsKey('headRangeY')) updatedValues['headRangeY'] = _parseDouble(content['headRangeY']);
      if (content.containsKey('neckRangeX')) updatedValues['neckRangeX'] = _parseDouble(content['neckRangeX']);
      if (content.containsKey('neckRangeY')) updatedValues['neckRangeY'] = _parseDouble(content['neckRangeY']);
      if (content.containsKey('chestRangeX')) updatedValues['chestRangeX'] = _parseDouble(content['chestRangeX']);
      if (content.containsKey('chestRangeY')) updatedValues['chestRangeY'] = _parseDouble(content['chestRangeY']);
      
      // 记录更新前的值，用于调试
      final beforeValues = {
        'aimRange': _aimModel.aimRange,
        'trackRange': _aimModel.trackRange,
        'headHeight': _aimModel.headHeight,
        'neckHeight': _aimModel.neckHeight,
        'chestHeight': _aimModel.chestHeight,
        'headRangeX': _aimModel.headRangeX,
        'headRangeY': _aimModel.headRangeY,
        'neckRangeX': _aimModel.neckRangeX,
        'neckRangeY': _aimModel.neckRangeY,
        'chestRangeX': _aimModel.chestRangeX,
        'chestRangeY': _aimModel.chestRangeY,
      };
      
      // 提取用户和游戏信息
      String username = content.containsKey('username') ? content['username'].toString() : _aimModel.username;
      String gameName = content.containsKey('gameName') ? content['gameName'].toString() : _aimModel.gameName;
      
      // 使用调用fromJson来批量更新，这是最直接的方法
      Map<String, dynamic> jsonData = {
        'content': {
          ...updatedValues,
          'username': username,
          'gameName': gameName,
          'createdAt': content['createdAt'] ?? _aimModel.createdAt,
          'updatedAt': content['updatedAt'] ?? DateTime.now().toIso8601String(),
        }
      };
      
      // 使用AimModel的fromJson方法一次性更新所有参数并触发通知
      _aimModel.fromJson(jsonData);
      
      // 记录更新后的值
      final afterValues = {
        'aimRange': _aimModel.aimRange,
        'trackRange': _aimModel.trackRange,
        'headHeight': _aimModel.headHeight,
        'neckHeight': _aimModel.neckHeight,
        'chestHeight': _aimModel.chestHeight,
        'headRangeX': _aimModel.headRangeX,
        'headRangeY': _aimModel.headRangeY,
        'neckRangeX': _aimModel.neckRangeX,
        'neckRangeY': _aimModel.neckRangeY,
        'chestRangeX': _aimModel.chestRangeX,
        'chestRangeY': _aimModel.chestRangeY,
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
      
      if (changedValues.isNotEmpty) {
        log.i(_logTag, '从服务器响应更新瞄准参数成功，以下参数已更新', changedValues);
      } else {
        log.i(_logTag, '从服务器响应更新瞄准参数完成，但无参数变化');
      }
      
      // 确保UI更新，在模型更新之后再通知控制器的监听器
      if (!_isDisposed) {
        // 直接调用notifyListeners() 不再包装在microtask中
        notifyListeners();
        log.d(_logTag, 'AimController通知已发送 - 确保UI更新');
        
        // 额外使用一个延迟通知，以确保UI能够更新
        Future.delayed(Duration(milliseconds: 100), () {
          if (!_isDisposed) {
            notifyListeners();
            log.d(_logTag, 'AimController延迟通知已发送 - 确保UI能完全刷新');
          }
        });
      }
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
  
  /// 处理游戏模型变更
  void _handleGameModelChanged() {
    if (_isDisposed) return;
    
    // 记录游戏变更
    log.i(_logTag, '游戏模型已变更', {'currentGame': _gameModel.currentGame});
    
    // 请求最新的瞄准配置
    _requestAimConfig();
  }
  
  /// 请求瞄准参数 - 供UI调用
  Future<void> requestAimParams() async {
    log.i(_logTag, '手动请求瞄准参数');
    _requestAimConfig();
  }
  
  /// 请求最新的瞄准配置
  void _requestAimConfig() {
    if (_serverService.isConnected && _authModel.isAuthenticated && _gameModel.currentGame.isNotEmpty) {
      try {
        // 构建请求
        final request = {
          'action': 'aim_read',
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
        
        log.i(_logTag, '已请求瞄准配置', {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey.isNotEmpty ? '已设置' : '未设置',
        });
      } catch (e) {
        log.e(_logTag, '请求瞄准配置失败', e.toString());
      }
    } else {
      log.w(_logTag, '无法请求瞄准配置，服务未连接或模型未初始化', {
        'isConnected': _serverService.isConnected,
        'isAuthenticated': _authModel.isAuthenticated,
        'currentGame': _gameModel.currentGame,
      });
    }
  }
  
  // Getters - 转发到AimModel
  double get aimRange => _aimModel.aimRange;
  double get trackRange => _aimModel.trackRange;
  double get headHeight => _aimModel.headHeight;
  double get neckHeight => _aimModel.neckHeight;
  double get chestHeight => _aimModel.chestHeight;
  double get headRangeX => _aimModel.headRangeX;
  double get headRangeY => _aimModel.headRangeY;
  double get neckRangeX => _aimModel.neckRangeX;
  double get neckRangeY => _aimModel.neckRangeY;
  double get chestRangeX => _aimModel.chestRangeX;
  double get chestRangeY => _aimModel.chestRangeY;
  
  // Setters - 转发到AimModel并标记为已修改
  set aimRange(double value) {
    if (_aimModel.aimRange != value) {
      _aimModel.aimRange = value;
      _isDirty = true;
      log.i(_logTag, '瞄准范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set trackRange(double value) {
    if (_aimModel.trackRange != value) {
      _aimModel.trackRange = value;
      _isDirty = true;
      log.i(_logTag, '跟踪范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set headHeight(double value) {
    if (_aimModel.headHeight != value) {
      _aimModel.headHeight = value;
      _isDirty = true;
      log.i(_logTag, '头部高度被修改为: $value');
      notifyListeners();
    }
  }
  
  set neckHeight(double value) {
    if (_aimModel.neckHeight != value) {
      _aimModel.neckHeight = value;
      _isDirty = true;
      log.i(_logTag, '颈部高度被修改为: $value');
      notifyListeners();
    }
  }
  
  set chestHeight(double value) {
    if (_aimModel.chestHeight != value) {
      _aimModel.chestHeight = value;
      _isDirty = true;
      log.i(_logTag, '胸部高度被修改为: $value');
      notifyListeners();
    }
  }
  
  set headRangeX(double value) {
    if (_aimModel.headRangeX != value) {
      _aimModel.headRangeX = value;
      _isDirty = true;
      log.i(_logTag, '头部X范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set headRangeY(double value) {
    if (_aimModel.headRangeY != value) {
      _aimModel.headRangeY = value;
      _isDirty = true;
      log.i(_logTag, '头部Y范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set neckRangeX(double value) {
    if (_aimModel.neckRangeX != value) {
      _aimModel.neckRangeX = value;
      _isDirty = true;
      log.i(_logTag, '颈部X范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set neckRangeY(double value) {
    if (_aimModel.neckRangeY != value) {
      _aimModel.neckRangeY = value;
      _isDirty = true;
      log.i(_logTag, '颈部Y范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set chestRangeX(double value) {
    if (_aimModel.chestRangeX != value) {
      _aimModel.chestRangeX = value;
      _isDirty = true;
      log.i(_logTag, '胸部X范围被修改为: $value');
      notifyListeners();
    }
  }
  
  set chestRangeY(double value) {
    if (_aimModel.chestRangeY != value) {
      _aimModel.chestRangeY = value;
      _isDirty = true;
      log.i(_logTag, '胸部Y范围被修改为: $value');
      notifyListeners();
    }
  }
  
  /// 当参数发生变化时，处理参数变更并自动保存
  void handleParameterChanged(String paramName, double value, BuildContext context) {
    try {
      // 记录日志
      log.i(_logTag, '参数变更: $paramName = $value');
      
      // 如果没有变更，不进行保存
      if (!_isDirty) {
        log.i(_logTag, '无参数变更，无需保存');
        return;
      }
      
      // 检查WebSocket连接
      if (!_serverService.isConnected) {
        log.w(_logTag, '服务器未连接，无法保存参数变更');
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法自动保存',
          type: MessageType.warning,
        );
        return;
      }
      
      // 更新用户和游戏信息
      _aimModel.updateUserGameInfo(
        _authModel.username,
        _gameModel.currentGame
      );
      
      // 获取完整的配置JSON
      final String jsonData = _aimModel.toJsonString();
      
      log.i(_logTag, '自动发送瞄准配置 - 参数: $paramName', {'gameName': _gameModel.currentGame});
      
      // 发送到服务器
      _serverService.sendMessage(jsonData);
      
      // 标记为已保存
      _isDirty = false;
      
      // 保存到本地
      _aimModel.saveSettings();
      
      // 轻量提示（可选）- 避免过多打扰用户
      // MessageComponent.showIconToast(
      //   context: context,
      //   message: '参数已自动保存',
      //   type: MessageType.success,
      //   duration: const Duration(milliseconds: 500),
      // );
    } catch (e) {
      log.e(_logTag, '自动保存参数变更出错', e.toString());
      MessageComponent.showIconToast(
        context: context,
        message: '自动保存出错: $e',
        type: MessageType.error,
      );
    }
  }
  
  /// 手动保存瞄准配置
  Future<void> saveAimConfig(BuildContext context) async {
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
      
      // 检查WebSocket连接
      if (!_serverService.isConnected) {
        log.w(_logTag, '服务器未连接，无法保存参数');
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法保存',
          type: MessageType.error,
        );
        return;
      }
      
      // 更新用户和游戏信息
      _aimModel.updateUserGameInfo(
        _authModel.username,
        _gameModel.currentGame
      );
      
      // 获取完整的配置JSON
      final String jsonData = _aimModel.toJsonString();
      
      log.i(_logTag, '手动发送瞄准配置', {'gameName': _gameModel.currentGame});
      
      // 发送到服务器
      _serverService.sendMessage(jsonData);
      
      _isDirty = false;
      await _aimModel.saveSettings();
      
      MessageComponent.showIconToast(
        context: context,
        message: '瞄准参数已保存',
        type: MessageType.success,
      );
    } catch (e) {
      log.e(_logTag, '保存瞄准配置出错', e.toString());
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
      // 使用AimModel的重置方法
      _aimModel.resetToDefaults();
      
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
  
  @override
  void dispose() {
    _isDisposed = true; // 设置已销毁标记
    
    // 移除WebSocket回调
    _serverService.removeMessageListener(_handleWebSocketMessage);
    
    // 移除GameModel变更监听
    _gameModel.removeListener(_handleGameModelChanged);
    
    log.i(_logTag, '控制器已释放');
    super.dispose();
  }
}
