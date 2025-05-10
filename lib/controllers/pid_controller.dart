// ignore_for_file: unused_import, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/pid_model.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../services/server_service.dart';
import 'package:provider/provider.dart';
import '../utils/logger.dart';
import 'dart:convert';

/// PID控制器 - 负责近端瞄准辅助的参数管理和业务逻辑
class PidController extends ChangeNotifier {
  // 依赖引用
  final ServerService serverService;
  final AuthModel authModel;
  final GameModel gameModel;
  final PidModel _pidModel;
  
  // 日志记录器
  final _logger = Logger();
  static const String _tag = 'PidController';
  
  // 构造函数
  PidController({
    required this.serverService,
    required this.authModel,
    required this.gameModel,
    required PidModel pidModel,
  }) : _pidModel = pidModel {
    // 初始化时尝试加载最新数据
    _init();
    // 添加WebSocket消息监听器
    _setupWebSocketListener();
  }
  
  /// 初始化
  Future<void> _init() async {
    // 如果已登录且有游戏选择，则尝试获取数据
    if (authModel.isAuthenticated && gameModel.currentGame.isNotEmpty) {
      await requestPidParams();
    }
  }

  /// 设置WebSocket消息监听
  void _setupWebSocketListener() {
    serverService.addMessageListener(_handleWebSocketMessage);
  }
  
  /// 处理接收到的WebSocket消息
  void _handleWebSocketMessage(dynamic message) {
    if (message is! String) return;
    
    try {
      final Map<String, dynamic> data = json.decode(message);
      
      // 检查是否是PID响应
      if (data['action'] == 'pid_read_response' && data['status'] == 'success') {
        _logger.i(_tag, '接收到PID参数响应');
        if (data['data'] != null) {
          _pidModel.fromJson({'content': data['data']});
          notifyListeners();
        }
      } else if (data['action'] == 'pid_modify_response' && data['status'] == 'success') {
        _logger.i(_tag, 'PID参数修改成功');
        if (data['data'] != null) {
          _pidModel.fromJson({'content': data['data']});
          notifyListeners();
        }
      }
    } catch (e) {
      _logger.e(_tag, '处理WebSocket消息失败', e);
    }
  }

  // PID参数 getters
  double get nearMoveFactor => _pidModel.nearMoveFactor;
  double get nearStabilizer => _pidModel.nearStabilizer; 
  double get nearResponseRate => _pidModel.nearResponseRate;
  double get nearAssistZone => _pidModel.nearAssistZone;
  double get nearResponseDelay => _pidModel.nearResponseDelay;
  double get nearMaxAdjustment => _pidModel.nearMaxAdjustment;
  double get farFactor => _pidModel.farFactor;
  
  // PID参数 setters
  set nearMoveFactor(double value) {
    _pidModel.nearMoveFactor = value;
    notifyListeners();
  }
  
  set nearStabilizer(double value) {
    _pidModel.nearStabilizer = value;
    notifyListeners();
  }
  
  set nearResponseRate(double value) {
    _pidModel.nearResponseRate = value;
    notifyListeners();
  }
  
  set nearAssistZone(double value) {
    _pidModel.nearAssistZone = value;
    notifyListeners();
  }
  
  set nearResponseDelay(double value) {
    _pidModel.nearResponseDelay = value;
    notifyListeners();
  }
  
  set nearMaxAdjustment(double value) {
    _pidModel.nearMaxAdjustment = value;
    notifyListeners();
  }
  
  set farFactor(double value) {
    _pidModel.farFactor = value;
    notifyListeners();
  }
  
  /// 请求PID参数 - 从服务器获取最新配置
  Future<void> requestPidParams() async {
    try {
      // 更新用户和游戏信息
      _pidModel.username = authModel.username;
      _pidModel.gameName = gameModel.currentGame;
      
      // 先尝试从本地加载设置
      await _pidModel.loadSettings();
      
      // 如果服务器已连接，则通过WebSocket请求服务器数据
      if (serverService.isConnected) {
        // 构造符合API文档的pid_read请求
        final Map<String, dynamic> requestData = {
          'action': 'pid_read',
          'content': {
            'username': authModel.username,
            'token': authModel.token,
            'gameName': gameModel.currentGame
          }
        };
        
        // 发送WebSocket请求
        serverService.sendMessage(json.encode(requestData));
        _logger.i(_tag, '已发送PID参数获取请求');
      } else {
        _logger.w(_tag, 'WebSocket未连接，使用本地PID参数');
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e(_tag, '获取PID参数失败', e);
    }
  }
  
  /// 重置为默认值
  void resetToDefaults(BuildContext context) {
    try {
      _pidModel.resetToDefaults();
      notifyListeners();
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已重置为默认设置'),
          backgroundColor: Colors.green,
        ),
      );
      
      _logger.i(_tag, '已重置PID参数为默认值');
    } catch (e) {
      _logger.e(_tag, '重置PID参数失败', e);
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('重置设置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 保存PID配置
  Future<void> savePidConfig(BuildContext context) async {
    try {
      // 更新用户和游戏信息
      _pidModel.username = authModel.username;
      _pidModel.gameName = gameModel.currentGame;
      
      // 保存到本地存储
      await _pidModel.saveSettings();
      
      // 如果服务器已连接，发送pid_modify请求
      if (serverService.isConnected) {
        // 构造符合API文档的pid_modify请求
        final Map<String, dynamic> requestContent = {
          'action': 'pid_modify',
          'content': {
            'username': authModel.username,
            'gameName': gameModel.currentGame,
            'nearMoveFactor': nearMoveFactor,
            'nearStabilizer': nearStabilizer,
            'nearResponseRate': nearResponseRate,
            'nearAssistZone': nearAssistZone,
            'nearResponseDelay': nearResponseDelay,
            'nearMaxAdjustment': nearMaxAdjustment,
            'farFactor': farFactor,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        };
        
        // 发送请求
        serverService.sendMessage(json.encode(requestContent));
        _logger.i(_tag, '已发送PID配置修改请求');
      } else {
        _logger.w(_tag, 'WebSocket未连接，仅保存到本地存储');
      }
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );
      
      _logger.i(_tag, '已保存PID配置');
    } catch (e) {
      _logger.e(_tag, '保存PID配置失败', e);
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存配置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 处理参数变更
  void handleParameterChanged(String paramName, double value, BuildContext context) {
    try {
      // 记录参数变更
      _logger.d(_tag, 'PID参数已变更: $paramName = $value');
      
      // 在滑块调整结束时发送WebSocket请求更新参数
      if (serverService.isConnected) {
        // 构造符合API文档的pid_modify请求
        final Map<String, dynamic> requestContent = {
          'action': 'pid_modify',
          'content': {
            'username': authModel.username,
            'gameName': gameModel.currentGame,
            'nearMoveFactor': nearMoveFactor,
            'nearStabilizer': nearStabilizer,
            'nearResponseRate': nearResponseRate,
            'nearAssistZone': nearAssistZone,
            'nearResponseDelay': nearResponseDelay,
            'nearMaxAdjustment': nearMaxAdjustment,
            'farFactor': farFactor,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        };
        
        // 发送请求
        serverService.sendMessage(json.encode(requestContent));
        _logger.d(_tag, '参数变更后发送PID配置修改请求');
      } else {
        _logger.w(_tag, 'WebSocket未连接，参数变更未发送到服务器');
      }
    } catch (e) {
      _logger.e(_tag, '处理参数变更失败', e);
    }
  }
  
  @override
  void dispose() {
    // 清理WebSocket监听器，防止内存泄漏
    serverService.removeMessageListener(_handleWebSocketMessage);
    super.dispose();
  }
} 