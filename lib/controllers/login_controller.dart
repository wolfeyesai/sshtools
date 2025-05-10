// ignore_for_file: use_build_context_synchronously, unnecessary_string_interpolations, prefer_function_declarations_over_variables, unused_field, unused_import, unnecessary_null_comparison

import 'package:flutter/material.dart';
import '../component/message_component.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../models/auth_model.dart';
import '../models/login_model.dart';
import 'dart:async';
import 'package:provider/provider.dart';

/// 登录控制器，处理登录页面的所有业务逻辑
class LoginController extends ChangeNotifier {
  // 使用LogMixin特性
  final log = Logger();
  
  // 错误消息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // 控制器状态标记
  bool _isDisposed = false;
  
  // 表单控制器
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController serverAddressController;
  final TextEditingController portController;
  
  // 登录加载状态
  bool isLoading = false;
  
  // 服务
  final AuthService authService;
  final AuthModel authModel;
  final LoginModel loginModel;
  
  // 控制器列表
  List<TextEditingController> get controllers => [
    serverAddressController,
    portController,
    usernameController,
    passwordController
  ];
  
  // 密码可见性列表
  List<bool> passwordVisibleList = [false, false, false, false];
  
  // 日志标签
  final _logTag = 'LoginController';
  
  // 登录超时计时器
  Timer? _loginRequestTimer;

  // 清除错误消息
  void clearMessage() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // 构造函数，初始化控制器
  LoginController({
    required this.authService,
    required this.authModel,
    required this.loginModel,
  })  : usernameController = TextEditingController(
          text: authModel.username.isNotEmpty 
              ? authModel.username 
              : loginModel.username
        ),
        passwordController = TextEditingController(
          text: (authModel.rememberPassword || loginModel.password.isNotEmpty) 
              ? loginModel.password 
              : ''
        ),
        serverAddressController = TextEditingController(text: loginModel.serverAddress),
        portController = TextEditingController(text: loginModel.serverPort) {
    
    log.i(_logTag, '登录控制器初始化');
    
    if (authModel.username.isNotEmpty && loginModel.username != authModel.username) {
      loginModel.updateUsername(authModel.username);
    }
    
    log.i(_logTag, '登录控制器已初始化');
  }
  
  // 更新全局变量并记录日志
  void updateServerAddress(String value) {
    loginModel.updateServerAddress(value);
    log.i(_logTag, '服务器地址已更新', value);
  }
  
  void updatePort(String value) {
    loginModel.updateServerPort(value);
    log.i(_logTag, '端口已更新', value);
  }
  
  void updateUsername(String value) {
    loginModel.updateUsername(value);
    log.i(_logTag, '用户名已更新', value);
  }
  
  void updatePassword(String value) {
    loginModel.updatePassword(value);
    log.i(_logTag, '密码已更新', '******');
  }
  
  // 更新密码可见性
  void updatePasswordVisibility(int index, bool isVisible) {
    passwordVisibleList[index] = isVisible;
    notifyListeners();
  }

  // 显示Toast消息
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

  // 处理登录按钮点击
  Future<bool> handleLogin(BuildContext context) async {
    final loginContext = context;
    
    log.i(_logTag, '用户点击了登录按钮');
    clearMessage();
    
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      log.w(_logTag, '登录验证失败：用户名或密码为空');
      _showToast(loginContext, '用户名和密码不能为空', MessageType.warning);
      return false;
    }
    
    log.i(_logTag, '开始登录流程，用户名: ${usernameController.text.trim()}');
    isLoading = true;
    notifyListeners();
    
    _loginRequestTimer?.cancel();
    _loginRequestTimer = Timer(const Duration(seconds: 10), () {
      if (isLoading && loginContext.mounted) {
        log.w(_logTag, '登录请求超时');
        isLoading = false;
        notifyListeners();
        _showToast(loginContext, '登录请求超时，请重试', MessageType.warning, 
            duration: const Duration(seconds: 3));
      }
    });
    
    try {
      log.i(_logTag, '更新登录模型数据');
      await loginModel.updateUsername(usernameController.text.trim());
      await loginModel.updatePassword(passwordController.text);
      
      log.i(_logTag, '调用认证服务进行登录，服务器: ${loginModel.serverAddress}:${loginModel.serverPort}');
      final loginResult = await authService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
        serverAddress: loginModel.serverAddress,
        serverPort: loginModel.serverPort,
      );

      _loginRequestTimer?.cancel();

      isLoading = false;
      notifyListeners();

      if (loginResult['success'] == true) {
        log.i(_logTag, '登录成功，获取到token');
        _showToast(loginContext, '登录成功！', MessageType.success);
        // 更新认证状态
        await authModel.setAuthInfo(
          username: usernameController.text.trim(),
          token: loginResult['token'] ?? '',
          rememberPassword: true, // 可以添加记住密码选项
        );
        log.i(_logTag, '认证状态已更新，准备跳转到主页面');
        return true;
      } else {
        log.w(_logTag, '登录失败: ${authService.errorMessage ?? "未知错误"}');
        _showToast(loginContext, authService.errorMessage ?? '登录失败，请检查用户名或密码', MessageType.error, 
                   duration: const Duration(seconds: 3));
        return false;
      }

    } catch (e) {
      _loginRequestTimer?.cancel();
      isLoading = false;
      notifyListeners();
      log.e(_logTag, '登录过程中发生异常', e.toString());
      _showToast(loginContext, '登录过程中发生错误：${e.toString()}', MessageType.error, 
                 duration: const Duration(seconds: 3));
      return false;
    }
  }
  
  // 处理注册按钮点击
  void handleRegister(BuildContext context) {
    log.i(_logTag, '跳转到注册页面');
    Navigator.pushNamed(context, '/register');
  }
  
  // 处理断开服务按钮点击
  Future<void> handleDisconnectService(BuildContext context) async {
    // TODO: 实现 handleDisconnectService 方法
  }
  
  // 获取输入字段配置数据
  List<Map<String, dynamic>> getInputFieldsData() {
    return [
      {
        'label': '服务器地址',
        'hint': '请输入服务器IP地址',
        'icon': Icons.cloud_outlined,
        'onChanged': updateServerAddress,
      },
      {
        'label': '端口',
        'hint': '请输入端口号',
        'icon': Icons.compare_arrows,
        'keyboardType': TextInputType.number,
        'onChanged': updatePort,
      },
      {
        'label': '用户名',
        'hint': '请输入用户名',
        'icon': Icons.person,
        'onChanged': updateUsername,
      },
      {
        'label': '密码',
        'hint': '请输入密码',
        'icon': Icons.lock,
        'isPassword': true,
        'onChanged': updatePassword,
      },
    ];
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      log.i(_logTag, '登录控制器清理资源...');
      
      _loginRequestTimer?.cancel();
      
      usernameController.dispose();
      passwordController.dispose();
      serverAddressController.dispose();
      portController.dispose();
      
      _isDisposed = true;
      log.i(_logTag, '登录控制器资源已清理');
    }
    super.dispose();
  }
} 