// ignore_for_file: unused_import, avoid_print, duplicate_ignore, unnecessary_nullable_for_final_variable_declarations, unused_local_variable

import 'package:flutter/material.dart';
import '../utils/logger.dart'; // 保留日志工具
// import '../services/server_service.dart'; // 保留服务器服务（或将来的 SSH 服务）(移除)
import '../services/ssh_service.dart'; // 导入 SSH 服务
import '../models/auth_model.dart'; // 保留认证模型

/// 头部控制器 - 负责处理头部页面的业务逻辑
class HeaderController extends ChangeNotifier {
  /// 服务器服务
  final SshService _sshService; // SSH 服务
  
  /// 认证模型
  final AuthModel _authModel;
  
  /// 日志工具
  final log = Logger();
  
  /// 日志标签
  final String _logTag = 'HeaderController';
  
  /// 构造函数
  HeaderController({
    required SshService sshService, // SSH 服务依赖
    required AuthModel authModel,
  }) : _sshService = sshService, // 初始化 SSH 服务
       _authModel = authModel {
    log.i(_logTag, '初始化 HeaderController');
  }
  
  // TODO: 添加与头部 UI 交互的逻辑，例如：
  // - 处理退出登录按钮点击 (调用 AuthService)
  // - 处理刷新按钮点击 (可能需要与 SshService 或其他控制器交互)
  // - 根据认证状态和连接状态更新 UI (通过 _authModel 和 _sshService)
  
  /// 示例：处理退出登录
  void handleLogout(BuildContext context) async {
    // TODO: 实现退出登录逻辑
    // 可能需要调用 AuthService.logout
    log.i(_logTag, '处理退出登录');
    // 退出成功后导航到登录页面
    // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  
  /// 示例：处理刷新系统
  void handleRefreshSystem() {
    // TODO: 实现刷新系统逻辑
    log.i(_logTag, '处理刷新系统');
  }
  
  /// 示例：处理刷新数据
  void handleRefreshData() {
    // TODO: 实现刷新数据逻辑
    log.i(_logTag, '处理刷新数据');
  }
} 