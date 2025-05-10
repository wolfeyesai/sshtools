// ignore_for_file: use_build_context_synchronously, unnecessary_string_interpolations, unused_local_variable, unused_field, prefer_final_fields, unused_import

import 'package:flutter/material.dart';
import '../component/message_component.dart';
import '../models/login_model.dart';
import '../models/auth_model.dart';
import '../utils/logger.dart';
// 不再需要直接导入WebSocket工具，使用ServerService
import '../services/server_service.dart'; // 导入ServerService
import '../controllers/side_controller.dart'; // 导入SideController
import 'dart:convert'; // 导入JSON转换库
import 'dart:async'; // 导入异步库
import 'package:provider/provider.dart';

import '../services/auth_service.dart'; // 保留 AuthService 导入

/// 注册控制器，处理注册页面的所有逻辑
class RegisterController with ChangeNotifier {
  // 表单控制器
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // 状态
  bool _agreeToTerms = false;
  bool get agreeToTerms => _agreeToTerms;
  set agreeToTerms(bool value) {
    _agreeToTerms = value;
    notifyListeners();
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
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
  AuthModel? _authModelRef;
  BuildContext? _registerContext;
  
  // 加载状态变更回调
  VoidCallback? onLoadingStateChanged;
  
  // 服务
  final AuthService _authService; // 添加 AuthService 依赖
  final LoginModel _loginModel; // LoginModel 依赖
  
  // 构造函数，初始化控制器
  RegisterController({required AuthService authService, required LoginModel loginModel})
      : _authService = authService,
        _loginModel = loginModel; // 修改构造函数，接收 AuthService 和 LoginModel
  
  // 重置字段
  void _resetFields() {
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _agreeToTerms = false; // 重置同意状态
    passwordVisibleList = [false, false]; // 重置密码可见性
    // isLoading状态由handleRegister方法处理
    notifyListeners(); // 通知UI更新重置后的状态
  }

  // 处理注册按钮点击
  Future<bool> handleRegister(BuildContext context) async {
    // 检查是否同意用户协议
    if (!_agreeToTerms) {
      MessageComponent.showIconToast(
        context: context,
        message: '请先同意用户协议和隐私政策',
        type: MessageType.warning,
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    // 基本表单验证已由 Form 组件处理，这里检查密码一致性
    if (passwordController.text != confirmPasswordController.text) {
       MessageComponent.showIconToast(
        context: context,
        message: '两次输入的密码不一致',
        type: MessageType.warning,
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    // 更新UI状态
    _isLoading = true;
    notifyListeners();

    try {
      // 调用 AuthService 进行注册认证
      final success = await _authService.register(
        serverAddress: _loginModel.serverAddress, // 从 LoginModel 获取服务器地址
        serverPort: _loginModel.serverPort, // 从 LoginModel 获取端口
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      _isLoading = false;
      notifyListeners();

      if (success) {
        // 注册成功
        MessageComponent.showIconToast(
          context: context,
          message: _authService.errorMessage.isNotEmpty ? _authService.errorMessage : '注册成功！', // 使用AuthService中的消息
          type: MessageType.success,
          duration: const Duration(seconds: 2),
        );

        // 清空输入框并重置其他状态
        _resetFields();

        return true;
      } else {
        // 注册失败，显示 AuthService 中的错误消息
        MessageComponent.showIconToast(
          context: context,
          message: _authService.errorMessage.isNotEmpty ? _authService.errorMessage : '注册失败，请重试', // 使用AuthService中的错误消息
          type: MessageType.error,
          duration: const Duration(seconds: 3),
        );
        return false;
      }

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // 处理 AuthService 中可能抛出的异常
      log.e(_logTag, '注册过程中发生异常', e.toString());
      MessageComponent.showIconToast(
        context: context,
        message: '注册过程中发生错误：${e.toString()}',
        type: MessageType.error,
        duration: const Duration(seconds: 3),
      );
      return false;
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
    log.i(_logTag, '返回登录页面');
    Navigator.pop(context);
  }
  
  // 定义输入字段列表
  List<Map<String, dynamic>> getInputFields() {
    return [
      {
        'label': '用户名',
        'hint': '请输入用户名',
        'icon': Icons.person,
      },
      {
        'label': '密码',
        'hint': '请输入密码',
        'icon': Icons.lock,
        'isPassword': true,
      },
      {
        'label': '确认密码',
        'hint': '请再次输入密码',
        'icon': Icons.lock_outline,
        'isPassword': true,
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
    
    // 释放控制器
    for (var controller in controllers) {
      controller.dispose();
    }
  }

  // 更新密码可见性
  void updatePasswordVisibility(int index, bool isVisible) {
    if (index >= 0 && index < passwordVisibleList.length) {
      passwordVisibleList[index] = isVisible;
      notifyListeners();
    }
  }
  
  // 更新同意条款状态
  void updateAgreeToTerms(bool? value) {
    if (value != null) {
      _agreeToTerms = value;
      notifyListeners();
    }
  }
} 