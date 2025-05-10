// ignore_for_file: use_build_context_synchronously, unused_import

import 'package:flutter/material.dart';
import '../models/fire_model.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../component/message_component.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:convert'; // 导入JSON转换库，用于格式化输出
import '../utils/blwebsocket.dart'; // 导入WebSocket工具类
import '../services/server_service.dart'; // 导入ServerService

/// 射击控制器，负责管理射击参数和相关的业务逻辑
class FireController extends ChangeNotifier {
  // 日志标签
  final String _logTag = 'FireController';
  
  // 依赖的服务和模型
  final ServerService _serverService;
  final AuthModel _authModel;
  final FireModel _fireModel;
  final GameModel _gameModel;
  
  // 参数是否已修改标记
  bool _isDirty = false;
  
  // Getter
  bool get isDirty => _isDirty;
  
  // 构造函数 - 使用依赖注入
  FireController({
    required ServerService serverService, 
    required AuthModel authModel,
    required FireModel fireModel,
    required GameModel gameModel,
  }) : _serverService = serverService,
       _authModel = authModel,
       _fireModel = fireModel,
       _gameModel = gameModel {
    // 注册WebSocket消息回调
    _registerWebSocketCallback();
  }
  
  /// 注册WebSocket消息回调
  void _registerWebSocketCallback() {
    // 订阅相关的WebSocket事件
    _serverService.addMessageListener(_handleWebSocketMessage);
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      // 只处理字符串消息
      if (message is! String) return;
      
      // 解析JSON消息
      final Map<String, dynamic> data = jsonDecode(message);
      
      // 检查是否是射击参数响应
      if (data['action'] == 'fire_modify_response') {
        developer.log('$_logTag - 收到射击参数响应: ${data.toString()}');
        
        // 处理服务器的响应
        if (data['status'] == 'success') {
          developer.log('$_logTag - 射击参数更新成功');
          
          // 如果服务器返回了新参数，可以更新本地模型
          if (data['content'] != null) {
            _updateFromServerResponse(data['content']);
          }
        } else {
          developer.log('$_logTag - 射击参数更新失败: ${data['message']}');
        }
      }
    } catch (e) {
      developer.log('$_logTag - 处理WebSocket消息出错: $e');
    }
  }
  
  /// 根据服务器响应更新本地参数
  void _updateFromServerResponse(Map<String, dynamic> content) {
    try {
      // 临时禁用脏标记，避免触发额外的通知
      final bool wasDirty = _isDirty;
      _isDirty = false;
      
      // 更新FireModel，它将自动通知监听者
      _fireModel.fromJson({'content': content});
      
      // 恢复之前的脏标记状态
      _isDirty = wasDirty;
      
      developer.log('$_logTag - 从服务器响应更新射击参数');
      
      // 通知UI更新
      notifyListeners();
    } catch (e) {
      developer.log('$_logTag - 从服务器响应更新参数出错: $e');
    }
  }
  
  // Getters - 转发到FireModel
  double get fireSpeed => _fireModel.fireSpeed;
  int get fireDelay => _fireModel.fireDelay;
  double get recoilControl => _fireModel.recoilControl;
  bool get autoFire => _fireModel.autoFire;
  int get burstCount => _fireModel.burstCount;
  
  // Setters - 转发到FireModel并标记为已修改
  set fireSpeed(double value) {
    if (_fireModel.fireSpeed != value) {
      _fireModel.fireSpeed = value;
      _isDirty = true;
      developer.log('$_logTag - 射击速度被修改为: $value');
      notifyListeners();
    }
  }
  
  set fireDelay(int value) {
    if (_fireModel.fireDelay != value) {
      _fireModel.fireDelay = value;
      _isDirty = true;
      developer.log('$_logTag - 射击延迟被修改为: $value');
      notifyListeners();
    }
  }
  
  set recoilControl(double value) {
    if (_fireModel.recoilControl != value) {
      _fireModel.recoilControl = value;
      _isDirty = true;
      developer.log('$_logTag - 后坐力控制被修改为: $value');
      notifyListeners();
    }
  }
  
  set autoFire(bool value) {
    if (_fireModel.autoFire != value) {
      _fireModel.autoFire = value;
      _isDirty = true;
      developer.log('$_logTag - 自动射击被修改为: $value');
      notifyListeners();
    }
  }
  
  set burstCount(int value) {
    if (_fireModel.burstCount != value) {
      _fireModel.burstCount = value;
      _isDirty = true;
      developer.log('$_logTag - 连发数量被修改为: $value');
      notifyListeners();
    }
  }
  
  /// 当参数发生变化时，处理参数变更
  void handleParameterChanged(String paramName, dynamic value, BuildContext context) {
    // 已经在setter中标记了脏标记，这里只需记录日志即可
    developer.log('$_logTag - 参数变更: $paramName = $value');
  }
  
  /// 保存射击配置
  Future<void> saveFireConfig(BuildContext context) async {
    try {
      // 如果没有变更，不进行保存
      if (!_isDirty) {
        developer.log('$_logTag - 没有修改，无需保存');
        MessageComponent.showIconToast(
          context: context,
          message: '无变更，无需保存',
          type: MessageType.info,
        );
        return;
      }
      
      // 更新用户和游戏信息
      _fireModel.updateUserGameInfo(
        _authModel.username,
        _gameModel.currentGame
      );
      
      // 获取完整的配置JSON
      final String jsonData = _fireModel.toJsonString();
      
      developer.log('$_logTag - 发送射击配置: $jsonData');
      
      // 发送到服务器
      if (_serverService.isConnected) {
        _serverService.sendMessage(jsonData);
        
        _isDirty = false;
        await _fireModel.saveSettings();
        
        MessageComponent.showIconToast(
          context: context,
          message: '射击参数已保存',
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
      developer.log('$_logTag - 保存射击配置出错: $e');
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
      // 使用FireModel的重置方法
      _fireModel.resetToDefaults();
      
      _isDirty = true;
      
      developer.log('$_logTag - 重置为默认值');
      
      MessageComponent.showIconToast(
        context: context,
        message: '已重置为默认值',
        type: MessageType.info,
      );
      
      notifyListeners();
    } catch (e) {
      developer.log('$_logTag - 重置为默认值出错: $e');
      MessageComponent.showIconToast(
        context: context,
        message: '重置出错: $e',
        type: MessageType.error,
      );
    }
  }
  
  @override
  void dispose() {
    // 移除WebSocket回调
    _serverService.removeMessageListener(_handleWebSocketMessage);
    
    developer.log('$_logTag - 释放资源');
    super.dispose();
  }
} 