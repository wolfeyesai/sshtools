// ignore_for_file: unused_import, unnecessary_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resource_model.dart';
import '../models/status_bar_model.dart';
import '../component/message_component.dart';

/// 消息监听器类型定义 - 接收WebSocket消息的回调函数
typedef MessageListener = void Function(dynamic message);

/// 服务器连接状态枚举
enum ConnectionState {
  disconnected,  // 断开连接
  connecting,    // 连接中
  connected,     // 已连接
  error,         // 连接错误
}

/// 服务器服务 - 处理与服务器的通信
class ServerService extends ChangeNotifier {
  // WebSocket连接
  WebSocketChannel? _channel;
  
  // 连接状态
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  // 错误信息
  String _errorMessage = '';
  
  // 服务器信息
  String _serverAddress = '';
  String _serverPort = '';
  
  // 认证token
  String _token = '';
  
  // 上次心跳时间
  DateTime? _lastHeartbeat;
  
  // 心跳检测定时器
  Timer? _heartbeatTimer;
  
  // 自动重连定时器
  Timer? _reconnectTimer;
  
  // 消息监听器列表 - 使用Set而不是List，避免重复添加
  final Set<MessageListener> _messageListeners = {};
  
  // 日志标签
  static const String _logTag = 'ServerService';
  
  // 状态栏信息
  final StatusBarModel _statusBarModel = StatusBarModel();
  
  // Getters
  ConnectionState get connectionState => _connectionState;
  String get errorMessage => _errorMessage;
  String get serverAddress => _serverAddress;
  String get serverPort => _serverPort;
  String get token => _token;
  DateTime? get lastHeartbeat => _lastHeartbeat;
  StatusBarModel get statusBarModel => _statusBarModel;
  
  // UI相关 Getters（方便从之前的 ServerController 迁移）
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isConnecting => _connectionState == ConnectionState.connecting;
  bool get hasError => _errorMessage.isNotEmpty;
  String get errorText => _errorMessage;
  
  // 构造函数
  ServerService() {
    debugPrint('$_logTag: 初始化服务器服务');
  }
  
  // 添加消息监听器
  MessageListener addMessageListener(MessageListener listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
      debugPrint('ServerService: 添加消息监听器，当前监听器数量: ${_messageListeners.length}');
    }
    return listener; // 返回监听器引用，便于后续移除
  }
  
  // 移除消息监听器
  void removeMessageListener(MessageListener listener) {
    if (_messageListeners.contains(listener)) {
      _messageListeners.remove(listener);
      debugPrint('ServerService: 移除消息监听器，当前监听器数量: ${_messageListeners.length}');
    }
  }
  
  // 清除所有消息监听器
  void clearMessageListeners() {
    _messageListeners.clear();
    debugPrint('ServerService: 已清除所有消息监听器');
  }
  
  // 通知所有消息监听器
  void _notifyMessageListeners(dynamic message) {
    // 创建副本防止在迭代过程中修改集合
    final listenersCopy = Set<MessageListener>.from(_messageListeners);
    
    for (var listener in listenersCopy) {
      try {
        // 捕获所有异常，防止一个监听器的错误影响其他监听器
        listener(message);
      } catch (e) {
        debugPrint('ServerService: 消息监听器处理失败: $e');
        // 不再自动移除出错的监听器，由控制器自行管理生命周期
      }
    }
  }
  
  // 连接到服务器
  Future<bool> connect({
    required String serverAddress,
    required String serverPort,
    required String token,
  }) async {
    // 如果已连接，先断开
    if (_connectionState == ConnectionState.connected) {
      disconnect();
    }
    
    _serverAddress = serverAddress;
    _serverPort = serverPort;
    _token = token;
    
    _setConnectionState(ConnectionState.connecting);
    
    try {
      // 创建WebSocket连接
      final wsUri = Uri.parse('ws://$serverAddress:$serverPort/ws?token=$token');
      _channel = WebSocketChannel.connect(wsUri);
      
      // 监听消息
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      // 发送初始消息
      _channel!.sink.add(jsonEncode({
        'type': 'connect',
        'token': token,
      }));
      
      // 启动心跳检测
      _startHeartbeat();
      
      _setConnectionState(ConnectionState.connected);
      return true;
    } catch (e) {
      _setError('连接服务器失败: $e');
      _setConnectionState(ConnectionState.error);
      
      // 启动自动重连
      _startReconnectTimer();
      return false;
    }
  }
  
  // 面向UI的连接方法
  Future<void> handleConnectService(BuildContext context, String serverAddress, String port, String token) async {
    // 清除错误状态
    _clearError();
    
    // 保存连接信息，即使连接失败也保存，下次可以重试
    _serverAddress = serverAddress;
    _serverPort = port;
    if (token.isNotEmpty) {
      _token = token;
    }
    
    // 设置连接中状态
    _setConnectionState(ConnectionState.connecting);
    
    try {
      // 验证输入参数
      if (serverAddress.isEmpty || port.isEmpty) {
        _setError('地址和端口不能为空');
        debugPrint('$_logTag: 服务器地址和端口不能为空');
        
        if (context.mounted) {
          MessageComponent.showIconToast(
            context: context,
            message: '服务器地址和端口不能为空',
            type: MessageType.warning,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      
      // 验证端口是否为有效的数字
      int? portInt = int.tryParse(port);
      if (portInt == null || portInt <= 0 || portInt > 65535) {
        _setError('无效的端口号');
        debugPrint('$_logTag: 无效的端口号');
        
        if (context.mounted) {
          MessageComponent.showIconToast(
            context: context,
            message: '无效的端口号，必须是1-65535之间的数字',
            type: MessageType.warning,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // 添加连接超时
      bool connectionEstablished = false;
      
      // 创建超时计时器
      Timer connectionTimer = Timer(const Duration(seconds: 5), () {
        if (!connectionEstablished && context.mounted) {
          debugPrint('$_logTag: WebSocket连接超时');
          _setError('连接超时');
          _setConnectionState(ConnectionState.error);
          
          MessageComponent.showIconToast(
            context: context,
            message: '连接服务器超时，请检查网络和服务器状态',
            type: MessageType.warning,
            duration: const Duration(seconds: 3),
          );
        }
      });
      
      // 尝试连接
      final success = await connect(
        serverAddress: serverAddress,
        serverPort: port,
        token: token,
      );
      
      // 连接结果处理
      connectionTimer.cancel();
      connectionEstablished = true;
      
      if (success && context.mounted) {
        MessageComponent.showIconToast(
          context: context,
          message: '已成功连接到服务器',
          type: MessageType.success,
          duration: const Duration(seconds: 2),
        );
      } else if (context.mounted) {
        MessageComponent.showIconToast(
          context: context,
          message: '连接服务器失败: $_errorMessage',
          type: MessageType.error,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      _setError('连接失败: $e');
      debugPrint('$_logTag: 服务器连接失败: $e');
      
      if (context.mounted) {
        MessageComponent.showIconToast(
          context: context,
          message: '连接失败: $e',
          type: MessageType.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // 面向UI的断开连接方法
  Future<void> handleDisconnectService(BuildContext context) async {
    // 清除错误状态
    _clearError();
    
    try {
      debugPrint('$_logTag: 正在断开WebSocket连接');
      
      // 断开连接
      disconnect();
      
      debugPrint('$_logTag: 服务器已断开连接');
      
      if (context.mounted) {
        MessageComponent.showIconToast(
          context: context,
          message: '已断开服务器连接',
          type: MessageType.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _setError('断开连接失败: $e');
      debugPrint('$_logTag: 断开服务器连接失败: $e');
      
      if (context.mounted) {
        MessageComponent.showIconToast(
          context: context,
          message: '断开连接失败: $e',
          type: MessageType.error,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
  
  // 获取服务器状态描述
  String getServerStatusDescription() {
    if (isConnecting) {
      return isConnected ? '正在断开连接...' : '正在连接...';
    } else if (isConnected) {
      return '已连接到 $_serverAddress:$_serverPort';
    } else if (hasError) {
      return '连接错误: $_errorMessage';
    } else {
      return '未连接';
    }
  }
  
  // 断开连接
  void disconnect() {
    _stopHeartbeat();
    _stopReconnectTimer();
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    
    // 清空消息监听器，避免已销毁的控制器仍收到消息
    clearMessageListeners();
    
    _setConnectionState(ConnectionState.disconnected);
    
    debugPrint('$_logTag: 已断开连接并清除所有消息监听器');
  }
  
  // 发送消息 (支持字符串和Map)
  void sendMessage(dynamic message) {
    if (_connectionState == ConnectionState.connected && _channel != null) {
      try {
        if (message is Map<String, dynamic>) {
          final String jsonStr = jsonEncode(message);
          debugPrint('$_logTag: 发送JSON消息: ${jsonStr.length > 500 ? '${jsonStr.substring(0, 500)}...(已截断)' : jsonStr}');
          _channel!.sink.add(jsonStr);
        } else if (message is String) {
          debugPrint('$_logTag: 发送字符串消息: ${message.length > 500 ? '${message.substring(0, 500)}...(已截断)' : message}');
          _channel!.sink.add(message);
        } else {
          _setError('发送消息失败: 不支持的消息类型');
          debugPrint('$_logTag: 发送消息失败: 不支持的消息类型 ${message.runtimeType}');
        }
      } catch (e) {
        _setError('发送消息失败: $e');
        debugPrint('$_logTag: 发送消息异常: $e');
      }
    } else {
      _setError('发送消息失败: 未连接到服务器');
      debugPrint('$_logTag: 无法发送消息，WebSocket未连接，连接状态: $_connectionState');
    }
  }
  
  // 获取系统资源信息
  void requestSystemResources() {
    sendMessage({
      'action': 'get_system_resources',
      'token': _token,
    });
  }
  
  // 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      // 更新最后心跳时间
      _lastHeartbeat = DateTime.now();
      
      // 将消息转发给所有注册的监听器
      _notifyMessageListeners(message);
      
      // 尝试解析JSON
      if (message is String) {
        debugPrint('$_logTag: 收到消息: ${message.length > 500 ? '${message.substring(0, 500)}...(已截断)' : message}');
        
        try {
          final Map<String, dynamic> data = jsonDecode(message);
          final String action = data['action'] ?? '';
          final String type = data['type'] ?? '';
          
          // 处理常见的错误响应格式
          if (data.containsKey('status') && data['status'] == 'error') {
            final String errorMessage = data['message'] ?? '未知错误';
            debugPrint('$_logTag: 收到错误消息: $errorMessage');
            // 不设置错误，避免影响UI状态
            return;
          }
          
          // 基于action处理消息 (新的API格式)
          if (action.isNotEmpty) {
            debugPrint('$_logTag: 接收到action类型消息: $action');
            
            // 处理状态栏响应
            if (action == 'status_bar_response') {
              debugPrint('$_logTag: 处理状态栏响应消息');
              _handleStatusBarQuery(data);
              return;
            }
            
            // 处理状态栏查询请求
            if (action == 'status_bar_query') {
              debugPrint('$_logTag: 处理状态栏查询消息');
                _handleStatusBarQuery(data);
              return;
            }
            
            // 处理心跳响应
            if (action == 'heartbeat_response') {
              _handleHeartbeat(data);
              return;
            }
            
            // 其他action类型消息由监听器处理
            debugPrint('$_logTag: 转发action消息到监听器: $action');
          } 
          // 基于type处理消息 (旧的API格式)
          else if (type.isNotEmpty) {
            debugPrint('$_logTag: 接收到type类型消息: $type');
            
            switch (type) {
              case 'heartbeat':
                _handleHeartbeat(data);
                break;
              case 'system_resources':
                _handleSystemResources(data);
                break;
              case 'error':
                debugPrint('$_logTag: 处理错误消息: ${data['message']}');
                _setError(data['message'] ?? '服务器错误');
                break;
              default:
                debugPrint('$_logTag: 转发type消息到监听器: $type');
                break;
            }
          } else {
            debugPrint('$_logTag: 接收到未知类型消息，缺少action或type字段');
          }
          
        } catch (e) {
          debugPrint('$_logTag: JSON解析错误: $e');
        }
      } else {
        debugPrint('$_logTag: 收到非字符串消息: $message');
      }
      
      // 通知监听器状态已更新
      notifyListeners();
    } catch (e) {
      debugPrint('$_logTag: 处理消息错误: $e');
    }
  }
  
  // 处理状态栏查询响应
  void _handleStatusBarQuery(Map<String, dynamic> data) {
    try {
      debugPrint('$_logTag: 处理状态栏信息: ${jsonEncode(data)}');
      
      Map<String, dynamic>? responseData;
      
      // 检查是否是标准的status_bar_response响应格式
      if (data['action'] == 'status_bar_response' && data.containsKey('data') && 
          data['data'] is Map<String, dynamic>) {
        responseData = data['data'] as Map<String, dynamic>;
        debugPrint('$_logTag: 使用标准响应格式处理状态栏信息');
      } 
      // 检查旧格式
      else if (data.containsKey('content') && data['content'] is Map<String, dynamic>) {
        responseData = data['content'] as Map<String, dynamic>;
        debugPrint('$_logTag: 使用旧版响应格式处理状态栏信息');
      }
      
      if (responseData != null) {
        // 打印详细的状态栏信息
        debugPrint('$_logTag: 状态栏信息详情:');
        debugPrint('  - 数据库状态: ${responseData['dbStatus']}');
        debugPrint('  - 推理状态: ${responseData['inferenceStatus']}');
        debugPrint('  - 卡密状态: ${responseData['cardKeyStatus']}');
        debugPrint('  - 键鼠状态: ${responseData['keyMouseStatus']}');
        
        // 为服务器可能不返回某些字段的情况处理默认值
        final Map<String, dynamic> normalizedContent = {
          'dbStatus': _normalizeStatusValue(responseData['dbStatus']),
          'inferenceStatus': _normalizeStatusValue(responseData['inferenceStatus']),
          'cardKeyStatus': _normalizeStatusValue(responseData['cardKeyStatus']),
          'keyMouseStatus': _normalizeStatusValue(responseData['keyMouseStatus']),
          'updatedAt': responseData['updatedAt'] ?? DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // 更新状态栏模型
        _statusBarModel.updateFromJson(normalizedContent);
        
        // 更新最后心跳时间
        _lastHeartbeat = DateTime.now();
        
        debugPrint('$_logTag: 更新状态栏信息成功');
      } else {
        debugPrint('$_logTag: 状态栏信息格式无效: ${jsonEncode(data)}');
        
        // 提供默认状态
        final Map<String, dynamic> defaultContent = {
          'dbStatus': false,
          'inferenceStatus': false,
          'cardKeyStatus': false,
          'keyMouseStatus': false,
          'updatedAt': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // 即使没有收到有效数据，也更新状态
        _statusBarModel.updateFromJson(defaultContent);
      }
      
      // 触发UI更新
      notifyListeners();
    } catch (e) {
      debugPrint('$_logTag: 处理状态栏信息错误: $e');
    }
  }
  
  // 将服务器返回的各种状态值格式统一转换为布尔值
  bool _normalizeStatusValue(dynamic value) {
    // 处理null或undefined
    if (value == null) return false;
    
    // 直接处理布尔值
    if (value is bool) return value;
    
    // 处理字符串值
    if (value is String) {
      final String lowerValue = value.toLowerCase().trim();
      
      // 积极状态的字符串集合
      const positiveValues = {
        'connected', 'running', 'valid', 'ready', 
        'online', 'true', 'active', 'success', 'ok'
      };
      
      return positiveValues.contains(lowerValue);
    }
    
    // 处理数字值 (0为false，其他为true)
    if (value is num) return value != 0;
    
    // 对于Map、List或其他类型，一般认为非空即为true
    // 但为了安全起见，这里默认返回false
    return false;
  }
  
  // 处理心跳消息
  void _handleHeartbeat(Map<String, dynamic> data) {
    // 可以在这里处理心跳数据
    _lastHeartbeat = DateTime.now();
  }
  
  // 处理系统资源信息
  void _handleSystemResources(Map<String, dynamic> data) {
    // 这个方法会通过消息总线或其他方式通知资源模型
    // 在实际应用中，可以实现一个消息总线来分发消息
  }
  
  // 处理连接错误
  void _handleError(error) {
    _setError('连接错误: $error');
    _setConnectionState(ConnectionState.error);
    
    // 启动自动重连
    _startReconnectTimer();
  }
  
  // 处理连接断开
  void _handleDisconnect() {
    // 如果当前状态不是主动断开，则视为错误
    if (_connectionState != ConnectionState.disconnected) {
      _setConnectionState(ConnectionState.disconnected);
      _setError('连接已断开');
      
      // 启动自动重连
      _startReconnectTimer();
    }
  }
  
  // 启动心跳检测 - 修改为状态栏查询
  void _startHeartbeat() {
    _stopHeartbeat();
    
    debugPrint('$_logTag: 启动状态栏查询定时器，间隔8秒');
    
    // 每30秒发送一次状态栏查询（替代原来的心跳）
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionState == ConnectionState.connected && _channel != null) {
        debugPrint('$_logTag: 发送状态栏查询请求');
        sendMessage({
          'action': 'status_bar_query',
          'token': _token,
        });
      } else {
        debugPrint('$_logTag: 状态栏查询请求未发送 - 连接状态: $_connectionState');
      }
    });
  }
  
  // 停止心跳检测
  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      debugPrint('$_logTag: 停止状态栏查询定时器');
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }
  
  // 启动自动重连
  void _startReconnectTimer() {
    _stopReconnectTimer();
    
    // 5秒后尝试重连
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_connectionState != ConnectionState.connected) {
        debugPrint('$_logTag: 尝试重新连接...');
        connect(
          serverAddress: _serverAddress,
          serverPort: _serverPort,
          token: _token,
        );
      }
    });
  }
  
  // 停止自动重连
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  // 设置连接状态
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }
  
  // 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // 清除错误信息
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    _messageListeners.clear();
    super.dispose();
  }
} 