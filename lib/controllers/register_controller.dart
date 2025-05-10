// ignore_for_file: use_build_context_synchronously, unnecessary_string_interpolations, unused_local_variable, unused_field, prefer_final_fields, unused_import

import 'package:flutter/material.dart';
import '../component/message_component.dart';
import '../models/login_model.dart';
import '../models/game_model.dart';
import '../models/auth_model.dart';
import '../utils/logger.dart';
// 不再需要直接导入WebSocket工具，使用ServerService
import '../services/server_service.dart'; // 导入ServerService
import '../controllers/side_controller.dart'; // 导入SideController
import 'dart:convert'; // 导入JSON转换库
import 'dart:async'; // 导入异步库
import 'package:provider/provider.dart';

/// 注册控制器，处理注册页面的所有逻辑
class RegisterController {
  // 表单控制器
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // 状态
  bool agreeToTerms = false;
  bool isLoading = false;
  
  // 控制器列表
  List<TextEditingController> get controllers => [
    usernameController,
    passwordController,
    confirmPasswordController
  ];
  
  // 密码可见性列表
  List<bool> passwordVisibleList = [false, false];
  
  // 日志工具
  final log = Logger();
  
  // 日志标签
  static const String _logTag = 'RegisterController';
  
  // 注册超时计时器
  Timer? _registerRequestTimer;
  
  // 服务消息监听器
  MessageListener? _serverMessageListener;
  
  // 模型引用 - 用于回调中的状态更新
  LoginModel? _loginModelRef;
  GameModel? _gameModelRef;
  AuthModel? _authModelRef;
  BuildContext? _registerContext;
  
  // 加载状态变更回调
  VoidCallback? onLoadingStateChanged;
  
  // 构造函数，初始化控制器
  RegisterController() {
    // 不再需要注册WebSocket回调，将在handleRegister方法中处理
  }
  
  // 处理服务器消息
  void _handleServerMessage(dynamic message) {
    try {
      // 解析JSON消息
      final Map<String, dynamic> responseData = jsonDecode(message);
      final String action = responseData['action'] ?? '';
      
      // 只处理注册相关消息
      if (action != 'register_modify_response' && action != 'register_modify' && responseData['status'] != 'error') {
        return;
      }
      
      log.i(_logTag, '收到注册相关消息', action);
      
      if (action == 'register_modify_response' || action == 'register_modify') {
        if (_registerContext != null && _registerContext!.mounted) {
          _handleRegisterResponse(responseData, _registerContext!);
        } else {
          _handleRegisterResponseWithoutContext(responseData);
        }
      } else if (responseData['status'] == 'error') {
        _showErrorToast(responseData['message'] ?? '请求失败，请重试');
      }
    } catch (e) {
      log.e(_logTag, '解析服务器消息失败', e.toString());
      _showErrorToast('接收到无效消息，请重试');
    }
  }
  
  // 显示错误消息
  void _showErrorToast(String message) {
    if (_registerContext != null && _registerContext!.mounted) {
      MessageComponent.showIconToast(
        context: _registerContext!,
        message: message,
        type: MessageType.error,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  // 在没有BuildContext的情况下处理注册响应
  void _handleRegisterResponseWithoutContext(Map<String, dynamic> response) {
    _registerRequestTimer?.cancel();
    
    final bool success = response['status'] == 'success' || response['status'] == 'ok';
    
    log.i(_logTag, '处理注册响应(无上下文): ${success ? '成功' : '失败'}');
    
    isLoading = false;
    onLoadingStateChanged?.call();
  }
  
  // 处理注册响应
  void _handleRegisterResponse(Map<String, dynamic> response, BuildContext context) {
    _registerRequestTimer?.cancel();
    
    final bool success = response['status'] == 'success' || response['status'] == 'ok';
    final String message = response['message'] ?? '注册处理完成';
    
    log.i(_logTag, '处理注册响应: ${success ? '成功' : '失败'}');
    
    if (success && context.mounted) {
      // 显示成功消息
      MessageComponent.showIconToast(
        context: context,
        message: '注册成功！正在准备数据...',
        type: MessageType.success,
        duration: const Duration(seconds: 2),
      );
      
      // 获取模型
      final loginModel = Provider.of<LoginModel>(context, listen: false);
      final gameModel = Provider.of<GameModel>(context, listen: false);
      final authModel = Provider.of<AuthModel>(context, listen: false);
      
      // 获取注册用户名
      final String registeredUsername = usernameController.text.trim();
      
      // 更新登录状态
      authModel.setAuthInfo(
        username: registeredUsername,
        token: loginModel.token,
        rememberPassword: true
      );
      
      loginModel.updateRememberPassword(true);
      
      // 处理服务器返回数据
      if (response['data'] != null) {
        try {
          // 处理用户信息
          final userInfo = response['data']['userInfo'];
          if (userInfo != null) {
            // 更新令牌
            if (userInfo['token'] != null) {
              loginModel.updateToken(userInfo['token']);
              authModel.setAuthInfo(
                username: authModel.username,
                token: userInfo['token'],
                rememberPassword: true
              );
            }
            
            // 更新用户名
            if (userInfo['username'] != null) {
              loginModel.updateUsername(userInfo['username']);
              authModel.setAuthInfo(
                username: userInfo['username'],
                token: authModel.token,
                rememberPassword: true
              );
            }
          }
          
          // 更新游戏配置
          if (response['data']['homeConfig'] != null) {
            final homeConfig = response['data']['homeConfig'];
            gameModel.updateCurrentGame(homeConfig['gameName'] ?? 'csgo2');
            gameModel.updateCardKey(homeConfig['cardKey'] ?? '');
          }
        } catch (e) {
          log.e(_logTag, '更新配置出错', e.toString());
        }
      }
      
      // 更新登录状态
      loginModel.updateLoginStatus('true');
      loginModel.updateLastLoginTime(DateTime.now().toIso8601String());
      
      // 设置登录后刷新标记
      loginModel.updateRefreshAfterLogin(true);
      
      // 显示自动登录消息
      MessageComponent.showIconToast(
        context: context,
        message: '注册成功，正在自动登录...',
        type: MessageType.success,
        duration: const Duration(seconds: 2),
      );
      
      // 清空输入框并重置加载状态
      _resetFields();
      
      // 导航到主页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      });
    } else if (!success && context.mounted) {
      // 显示错误消息
      MessageComponent.showIconToast(
        context: context,
        message: message.isNotEmpty ? message : '注册失败，请重试',
        type: MessageType.error,
        duration: const Duration(seconds: 3),
      );
      
      // 重置加载状态
      isLoading = false;
      onLoadingStateChanged?.call();
    }
  }
  
  // 重置字段
  void _resetFields() {
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    isLoading = false;
    onLoadingStateChanged?.call();
  }

  // 处理注册按钮点击
  Future<void> handleRegister(BuildContext context) async {
    // 基本表单验证
    if (passwordController.text != confirmPasswordController.text) {
      _showToast(context, '两次输入的密码不一致', MessageType.error);
      return;
    }
    
    if (!agreeToTerms) {
      _showToast(context, '请先同意用户协议与隐私政策', MessageType.warning);
      return;
    }
    
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();
    
    if (username.isEmpty) {
      _showToast(context, '用户名不能为空', MessageType.warning);
      return;
    }
    
    if (password.isEmpty) {
      _showToast(context, '密码不能为空', MessageType.warning);
      return;
    }
    
    // 更新状态
    isLoading = true;
    onLoadingStateChanged?.call();
    _registerContext = context;
    
    // 获取服务
    final serverService = Provider.of<ServerService>(context, listen: false);
    
    _showToast(context, '正在开始注册过程...', MessageType.info);
    
    // 检查连接状态
    if (!serverService.isConnected) {
      // 尝试连接
      if (!await _connectToServer(context, serverService)) {
        // 连接失败，重置状态并返回
        isLoading = false;
        onLoadingStateChanged?.call();
        return;
      }
    }

    // 显示注册中消息
    _showToast(context, '正在提交注册信息...', MessageType.info);
    
    // 设置超时处理
    _registerRequestTimer?.cancel();
    _registerRequestTimer = Timer(const Duration(seconds: 10), () {
      if (isLoading) {
        _showToast(context, '注册请求超时，请重试', MessageType.warning);
        isLoading = false;
        onLoadingStateChanged?.call();
      }
    });
    
    try {
      // 获取模型实例
      final loginModel = Provider.of<LoginModel>(context, listen: false);
      final authModel = Provider.of<AuthModel>(context, listen: false);
      final gameModel = Provider.of<GameModel>(context, listen: false);
      
      // 保存引用
      _loginModelRef = loginModel;
      _authModelRef = authModel;
      _gameModelRef = gameModel;
      
      // 更新登录信息
      loginModel.updateUsername(username);
      loginModel.updatePassword(password);
      await authModel.setAuthInfo(
        username: username,
        token: loginModel.token,
        rememberPassword: true
      );
      await loginModel.updateRememberPassword(true);
      
      // 构建注册数据
      final registerData = {
        'action': 'register_modify',
        'content': {
          'gameList': ['apex', 'cf', 'cfhd', 'csgo2', 'sj2', 'ssjj2', 'wwqy'],
          'defaultGame': 'csgo2',
          'username': username,
          'password': password,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String()
        }
      };
      
      // 记录注册请求
      log.i(_logTag, '发送注册请求');
      
      // 添加消息监听器
      _serverMessageListener = serverService.addMessageListener(_handleServerMessage);
      
      // 发送请求
      serverService.sendMessage(jsonEncode(registerData));
      
      // 显示发送成功
      _showToast(context, '注册请求已发送，等待服务器响应...', MessageType.info);
    } catch (e) {
      _registerRequestTimer?.cancel();
      log.e(_logTag, '发送注册请求失败', e.toString());
      
      isLoading = false;
      onLoadingStateChanged?.call();
      
      _showToast(context, '发送注册请求失败: ${e.toString()}', MessageType.error);
    }
  }
  
  // 连接到服务器
  Future<bool> _connectToServer(BuildContext context, ServerService serverService) async {
    final loginModel = Provider.of<LoginModel>(context, listen: false);
    
    if (loginModel.serverAddress.isEmpty || loginModel.serverPort.isEmpty) {
      _showToast(context, '未连接到服务器，请在登录页面连接服务器后再试', MessageType.warning);
      return false;
    }
    
    _showToast(context, '正在连接到服务器...', MessageType.info);
    
    try {
      await serverService.handleConnectService(
        context,
        loginModel.serverAddress,
        loginModel.serverPort,
        loginModel.token
      );
      
      // 等待连接完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!serverService.isConnected) {
        _showToast(context, '无法连接到服务器，请在登录页面连接服务器后再试', MessageType.warning);
        return false;
      }
      
      return true;
    } catch (e) {
      _showToast(context, '连接服务器失败: ${e.toString()}', MessageType.error);
      return false;
    }
  }
  
  // 显示提示消息
  void _showToast(BuildContext context, String message, MessageType type, {Duration duration = const Duration(seconds: 2)}) {
    if (context.mounted) {
      MessageComponent.showIconToast(
        context: context,
        message: message,
        type: type,
        duration: duration,
      );
    }
  }

  // 返回登录页
  void navigateToLogin(BuildContext context) {
    Navigator.pop(context);
  }
  
  // 定义输入字段列表
  List<Map<String, dynamic>> getInputFields() {
    return [
      {
        'label': '用户名',
        'hint': '请输入用户名',
        'icon': Icons.person,
        'onChanged': (String value) {},
        'validator': (String? value) {
          if (value == null || value.isEmpty) {
            return '请输入用户名';
          }
          if (value.length < 3) {
            return '用户名长度不能少于3位';
          }
          return null;
        }
      },
      {
        'label': '密码',
        'hint': '请输入密码',
        'icon': Icons.lock,
        'isPassword': true,
        'onChanged': (String value) {},
        'validator': (String? value) {
          if (value == null || value.isEmpty) {
            return '请输入密码';
          }
          if (value.length < 6) {
            return '密码长度不能少于6位';
          }
          return null;
        }
      },
      {
        'label': '确认密码',
        'hint': '请再次输入密码',
        'icon': Icons.lock_outline,
        'isPassword': true,
        'onChanged': (String value) {},
        'validator': (String? value) {
          if (value == null || value.isEmpty) {
            return '请确认密码';
          }
          if (value != passwordController.text) {
            return '两次输入的密码不一致';
          }
          return null;
        }
      },
    ];
  }
  
  // 释放资源
  void dispose() {
    _registerRequestTimer?.cancel();
    
    // 移除消息监听器
    if (_serverMessageListener != null && _registerContext != null && _registerContext!.mounted) {
      try {
        final serverService = Provider.of<ServerService>(_registerContext!, listen: false);
        serverService.removeMessageListener(_serverMessageListener!);
      } catch (e) {
        log.w(_logTag, '移除服务器消息监听器失败', e.toString());
      }
    }
    
    // 清除引用
    _registerContext = null;
    _loginModelRef = null;
    _authModelRef = null;
    _gameModelRef = null;
    _serverMessageListener = null;
    
    // 释放控制器
    for (var controller in controllers) {
      controller.dispose();
    }
  }

  // 更新密码可见性
  void updatePasswordVisibility(int index, bool isVisible) {
    passwordVisibleList[index] = isVisible;
  }
  
  // 更新同意条款状态
  void updateAgreeToTerms(bool value) {
    agreeToTerms = value;
  }
} 