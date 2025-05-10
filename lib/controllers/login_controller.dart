// ignore_for_file: use_build_context_synchronously, unnecessary_string_interpolations, prefer_function_declarations_over_variables, unused_field, unused_import, unnecessary_null_comparison

import 'package:flutter/material.dart';
import '../component/message_component.dart';
import '../utils/logger.dart';
import '../services/server_service.dart'; // 导入服务器服务
import '../services/auth_service.dart'; // 导入认证服务
import '../models/auth_model.dart'; // 导入认证模型
import '../models/login_model.dart'; // 导入登录模型
import '../models/game_model.dart'; // 导入游戏模型
import 'dart:async';
import 'dart:convert'; // 导入JSON转换库
import 'package:provider/provider.dart';
import '../controllers/side_controller.dart';

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
  final ServerService serverService;
  final AuthService authService;
  final AuthModel authModel;
  final LoginModel loginModel;
  final GameModel gameModel; // 添加GameModel依赖
  
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
  
  // 服务状态变更监听器
  VoidCallback? _serverStatusListener;
  
  // 清除错误消息
  void clearMessage() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // 构造函数，初始化控制器
  LoginController({
    required this.serverService,
    required this.authService,
    required this.authModel,
    required this.loginModel,
    required this.gameModel, // 添加GameModel参数
  })  : usernameController = TextEditingController(
          // 优先从AuthModel获取用户名，如果为空再从LoginModel获取
          text: authModel.username.isNotEmpty 
              ? authModel.username 
              : loginModel.username
        ),
        passwordController = TextEditingController(
          // 如果记住密码开启或有保存的密码，则显示密码
          text: (authModel.rememberPassword || loginModel.password.isNotEmpty) 
              ? loginModel.password 
              : ''
        ),
        serverAddressController = TextEditingController(text: loginModel.serverAddress),
        portController = TextEditingController(text: loginModel.serverPort) {
    
    // 在日志中记录初始化信息
    log.i(_logTag, '登录控制器初始化');
    
    // 确保LoginModel中的用户名与AuthModel一致
    if (authModel.username.isNotEmpty && loginModel.username != authModel.username) {
      loginModel.updateUsername(authModel.username);
    }
    
    // 创建并保存监听器函数引用
    _serverStatusListener = () {
      notifyListeners();
    };
    
    // 添加监听器，转发服务器服务的状态变更通知
    serverService.addListener(_serverStatusListener!);
    
    // 添加WebSocket消息监听
    serverService.addMessageListener(_handleServerMessage);
    
    // 记录初始化日志
    log.i(_logTag, '登录控制器已初始化', {
      'serverService': serverService != null ? 'injected' : 'null',
      'authService': authService != null ? 'injected' : 'null',
      'authModel': authModel != null ? 'injected' : 'null',
      'loginModel': loginModel != null ? 'injected' : 'null',
      'gameModel': gameModel != null ? 'injected' : 'null',
    });
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

  // 处理服务器消息
  void _handleServerMessage(dynamic message) {
    // 检查控制器是否已被销毁
    if (_isDisposed) return;
    
    try {
      Map<String, dynamic> responseData = jsonDecode(message.toString());
      final String action = responseData['action'] ?? '';
      
      // 只处理登录相关消息
      if (action != 'login_read' && action != 'home_read') return;
      
      log.i(_logTag, '收到服务器消息', '$action');
      
      switch (action) {
        case 'login_read':
          _handleLoginResponse(responseData);
          break;
        case 'home_read':
          _handleHomeConfigResponse(responseData);
          break;
      }
    } catch (e) {
      log.e(_logTag, '解析服务器消息失败', e.toString());
    }
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
  Future<void> handleLogin(BuildContext context) async {
    // 保存上下文用于回调
    final loginContext = context;
    
    // 清除之前的错误
    clearMessage();
    
    // 检查输入
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showToast(loginContext, '用户名和密码不能为空', MessageType.warning);
      return;
    }
    
    // 检查WebSocket连接状态
    if (!serverService.isConnected) {
      _showToast(loginContext, '正在连接到服务器...', MessageType.info);
      
      await serverService.handleConnectService(
        loginContext,
        serverAddressController.text,
        portController.text,
        loginModel.token,
      );
      
      if (!serverService.isConnected) {
        _showToast(loginContext, '无法连接到服务器，请检查服务器设置', MessageType.warning, 
            duration: const Duration(seconds: 3));
        return;
      }
    }
    
    // 更新UI状态
    isLoading = true;
    notifyListeners();
    
    // 设置登录超时处理
    _loginRequestTimer?.cancel();
    _loginRequestTimer = Timer(const Duration(seconds: 10), () {
      if (isLoading && loginContext.mounted) {
        isLoading = false;
        notifyListeners();
        _showToast(loginContext, '登录请求超时，请重试', MessageType.warning, 
            duration: const Duration(seconds: 3));
      }
    });
    
    try {
      // 更新登录信息
      await loginModel.updateUsername(usernameController.text.trim());
      await loginModel.updatePassword(passwordController.text);
      
      // 构建登录请求
      Map<String, dynamic> loginRequest = {
        'action': 'login_read',
        'content': {
          'username': loginModel.username,
          'password': loginModel.password,
          'token': loginModel.token,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String()
        }
      };
      
      // 发送请求
      log.i(_logTag, '发送登录请求');
      
      if (!serverService.isConnected) {
        throw Exception('WebSocket连接已断开');
      }
      
      serverService.sendMessage(jsonEncode(loginRequest));
      _showToast(loginContext, '登录请求已发送，等待响应...', MessageType.info);
      
    } catch (e) {
      _loginRequestTimer?.cancel();
      log.e(_logTag, '发送登录请求失败', e.toString());
      
      isLoading = false;
      notifyListeners();
      
      _showToast(loginContext, '发送登录请求失败: ${e.toString()}', MessageType.error, 
          duration: const Duration(seconds: 3));
    }
  }

  // 处理登录响应
  void _handleLoginResponse(Map<String, dynamic> response) {
    // 取消计时器并重置状态
    _loginRequestTimer?.cancel();
    
    if (isLoading) {
      isLoading = false;
      notifyListeners();
    }
    
    clearMessage();
    
    final bool success = response['status'] == 'success';
    final String message = response['message'] ?? '';
    final BuildContext? context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    
    log.i(_logTag, '登录响应处理: ${success ? '成功' : '失败'}');
    
    if (success) {
      // 获取用户令牌
      String token = '';
      if (response['data']?['userInfo']?['token'] != null) {
        token = response['data']['userInfo']['token'];
      }
      
      // 保存认证信息
      authModel.setAuthInfo(
        username: loginModel.username,
        token: token,
        rememberPassword: true,
      );
      
      // 更新登录状态
      loginModel.saveLoginInfo(
        username: loginModel.username,
        password: loginModel.password,
        token: token,
        rememberPassword: true,
        loginStatus: 'true',
        lastLoginTime: DateTime.now().toIso8601String()
      );
      
      notifyListeners();
      
      if (context != null) {
        // 显示成功消息
        _showToast(context, message.isNotEmpty ? message : '登录成功', MessageType.success);
        
        // 导航到主页
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // 保存登录标记，用于主页加载后自动刷新
            loginModel.updateRefreshAfterLogin(true);
            
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        });
      }
    } else {
      // 登录失败
      loginModel.updateLoginStatus('false');
      notifyListeners();
      
      if (context != null) {
        _showToast(
          context, 
          message.isNotEmpty ? message : '登录失败，请检查用户名和密码', 
          MessageType.error, 
          duration: const Duration(seconds: 3)
        );
      }
    }
  }
  
  // 处理注册按钮点击
  void handleRegister(BuildContext context) {
    log.i(_logTag, '跳转到注册页面');
    Navigator.pushNamed(context, '/register');
  }
  
  // 处理连接服务按钮点击
  Future<void> handleConnectService(BuildContext context) async {
    await serverService.handleConnectService(
      context, 
      serverAddressController.text.trim(), 
      portController.text.trim(),
      loginModel.token,
    );
  }
  
  // 处理断开服务按钮点击
  Future<void> handleDisconnectService(BuildContext context) async {
    await serverService.handleDisconnectService(context);
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
  
  // 处理首页配置响应
  void _handleHomeConfigResponse(Map<String, dynamic> response) {
    if (_isDisposed) return;
    
    log.i(_logTag, '收到首页配置响应');
    
    if (response['status'] == 'ok') {
      try {
        final data = response['data'];
        if (data != null) {
          // 更新游戏信息和卡密
          if (data['gameName'] != null && data['gameName'].toString().isNotEmpty) {
            gameModel.updateCurrentGame(data['gameName'].toString());
          }
          
          if (data['cardKey'] != null && data['cardKey'].toString().isNotEmpty) {
            gameModel.updateCardKey(data['cardKey'].toString());
          }
        }
      } catch (e) {
        log.e(_logTag, '处理首页配置失败', e.toString());
      }
    }
  }
  
  // 释放资源
  @override
  void dispose() {
    _isDisposed = true;
    
    // 移除监听器
    if (_serverStatusListener != null) {
      serverService.removeListener(_serverStatusListener!);
      _serverStatusListener = null;
    }
    
    // 取消计时器
    _loginRequestTimer?.cancel();
    
    // 移除WebSocket消息监听
    serverService.removeMessageListener(_handleServerMessage);
    
    // 释放控制器
    for (var controller in controllers) {
      controller.dispose();
    }
    
    log.i(_logTag, '登录控制器资源已释放');
    super.dispose();
  }
} 