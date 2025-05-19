// ignore_for_file: unused_import, duplicate_ignore, unused_field, use_super_parameters, deprecated_member_use, unnecessary_null_comparison, unused_element

import 'dart:async';
// ignore: unused_import
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../models/ip_model.dart';
import '../models/ssh_model.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../component/message_component.dart';
import '../component/remote_directory_browser.dart';
import '../component/ssh_file_uploader.dart';
import '../component/ssh_file_downloader.dart';
import '../component/ssh_multi_terminal.dart';
import '../controllers/ssh_command_controller.dart';
import '../models/ssh_header_model.dart';
import '../controllers/ssh_header_controller.dart';
import '../views/ssh_header_view.dart';
import '../models/ssh_footer_model.dart';
import '../controllers/ssh_footer_controller.dart';
import '../views/ssh_footer_view.dart';

/// SSH终端页面
class SSHTerminalPage extends StatefulWidget {
  /// 页面标题
  static const String pageTitle = 'SSH终端';
  
  /// 路由名称
  static const String routeName = '/ssh-terminal';
  
  /// 目标设备
  final IPDeviceModel device;
  
  /// SSH凭据
  final String username;
  final String password;
  final int port;
  
  /// 构造函数
  const SSHTerminalPage({
    Key? key,
    required this.device,
    required this.username,
    required this.password,
    this.port = 22,
  }) : super(key: key);

  @override
  State<SSHTerminalPage> createState() => _SSHTerminalPageState();
}

class _SSHTerminalPageState extends State<SSHTerminalPage> {
  /// SSH控制器
  late final SSHController _sshController;
  
  /// 连接状态
  String _connectionStatus = '准备连接...';
  
  /// 是否已连接
  bool _connected = false;
  
  /// 连接状态订阅
  StreamSubscription<SSHConnectionState>? _connectionStateSubscription;

  /// 页头模型
  late final SSHHeaderModel _headerModel;
  
  /// 页头控制器
  late final SSHHeaderController _headerController;
  
  /// 页尾模型
  late final SSHFooterModel _footerModel;
  
  /// 页尾控制器
  late final SSHFooterController _footerController;
  
  /// 显示错误消息
  void _showError(String message) {
    if (mounted) {
      MessageComponentFactory.showError(
        context,
        message: message,
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // 获取Provider中的SSH控制器
    _sshController = Provider.of<SSHController>(context, listen: false);
    
    // 获取命令控制器
    final commandController = Provider.of<SSHCommandController>(context, listen: false);
    
    // 初始化页头模型
    _headerModel = SSHHeaderModel(title: SSHTerminalPage.pageTitle);
    
    // 初始化页头控制器
    _headerController = SSHHeaderController(
      model: _headerModel,
      sshController: _sshController,
    );
    
    // 初始化页尾模型
    _footerModel = SSHFooterModel(isConnected: false);
    
    // 初始化页尾控制器
    _footerController = SSHFooterController(
      model: _footerModel,
      sshController: _sshController,
      onCommandSent: (command) {
        // 命令发送成功后的回调处理（如果需要）
      },
    );
    
    // 设置页尾控制器的命令控制器
    _footerController.setCommandController(commandController);
    
    // 订阅连接状态变化
    _connectionStateSubscription = _sshController.connectionStateStream.listen((state) {
      if (mounted && _connectionStateSubscription != null) {
        try {
          setState(() {
            _connected = state == SSHConnectionState.connected;
            _connectionStatus = _getStatusFromState(state);
          });
        } catch (e) {
          debugPrint('更新连接状态时出错: $e');
          _connectionStateSubscription?.cancel();
          _connectionStateSubscription = null;
        }
      }
    });
  }
  
  /// 获取状态描述
  String _getStatusFromState(SSHConnectionState state) {
    switch (state) {
      case SSHConnectionState.connecting:
        return '正在连接...';
      case SSHConnectionState.connected:
        return '已连接';
      case SSHConnectionState.disconnected:
        return '已断开连接';
      case SSHConnectionState.failed:
        return '连接失败';
    }
  }
  
  @override
  void dispose() {
    // 检查是否正在上传文件
    final isTransferring = _headerController.isTransferringFile;
    
    // 直接设置变量为null，防止后续更新
    _connected = false;
    
    // 保存引用，然后设置为null
    final connStateSub = _connectionStateSubscription;
    
    _connectionStateSubscription = null;
    
    // 释放页头控制器资源
    _headerController.dispose();
    
    // 释放页尾控制器资源
    _footerController.dispose();
    
    // 先调用父类的dispose确保组件正确销毁
    super.dispose();
    
    // 然后在下一帧开始异步释放资源
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // 取消连接状态订阅
        if (connStateSub != null) {
          connStateSub.cancel();
        }
      } catch (e) {
        debugPrint('取消连接状态订阅出错: $e');
      }
      
      // 只有在没有文件传输时才断开连接
      if (!isTransferring) {
        try {
          // 断开SSH连接
          _sshController.disconnect();
        } catch (e) {
          debugPrint('断开SSH连接出错: $e');
        }
      } else {
        debugPrint('文件传输进行中，保持SSH连接');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用try-catch包装整个build方法
    try {
      return MultiProvider(
        providers: [
          // 提供页头模型
          ChangeNotifierProvider.value(value: _headerModel),
          // 提供页头控制器
          ChangeNotifierProvider<SSHHeaderController>(
            create: (_) => _headerController,
          ),
          // 提供页尾模型
          ChangeNotifierProvider.value(value: _footerModel),
          // 提供页尾控制器
          ChangeNotifierProvider<SSHFooterController>(
            create: (_) => _footerController,
          ),
        ],
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: SSHHeaderView(
              device: widget.device,
              username: widget.username,
              password: widget.password,
              port: widget.port,
            ),
          ),
          body: Column(
            children: [
              // 多终端管理组件
              Expanded(
                child: SSHMultiTerminal(
                  initialDevice: widget.device,
                  initialUsername: widget.username,
                  initialPassword: widget.password,
                  initialPort: widget.port,
                ),
              ),
              
              // 使用页尾组件
              SSHFooterView(),
            ],
          ),
        ),
      );
    } catch (e) {
      // 如果构建过程中发生错误，显示错误视图
      return Scaffold(
        appBar: AppBar(
          title: const Text('出错了'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '终端页面加载错误',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
} 