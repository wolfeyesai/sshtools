// ignore_for_file: unused_import, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
// import '../component/card_select_component.dart';
// import '../models/game_icon_paths.dart';
import '../utils/logger.dart'; // 保留日志工具
// import 'header_controller.dart'; // 移除不再需要的导入
// import 'dart:convert';
// import '../services/server_service.dart'; // 保留或替换为 SSHService (移除)
// import '../models/auth_model.dart'; // AuthModel 可能不再直接需要在此控制器中使用 (移除)
// import '../models/game_model.dart'; // 移除不再需要的模型导入 (移除)
// import '../component/message_component.dart'; // 消息提示可能移至视图或其他地方处理 (移除)

// 导入新的依赖模型和服务
import '../models/device_model.dart'; // 用于获取设备列表
import '../services/ssh_service.dart'; // 导入 SSHService

// 导入终端页面以便跳转
import '../views/terminal_screen.dart';

/// 首页控制器 - 负责处理首页（最近连接）的业务逻辑
class HomeController extends ChangeNotifier {
  // 移除旧的字段
  // CardItem? _selectedGame;
  // final TextEditingController cardKeyController = TextEditingController();
  // HeaderController? _headerController;
  // bool _isDisposed = false;

  /// 依赖的服务和模型
  final DeviceModel _deviceModel; // 新增设备模型依赖
  final SshService _sshService; // SSH 连接服务 (使用 SshService)

  /// 日志
  final String _logTag = 'HomeController';
  final log = Logger();

  // 移除旧的 getter
  // CardItem? get selectedGame => _selectedGame;

  /// 构造函数 - 注入所需的服务和模型
  HomeController({
    required DeviceModel deviceModel,
    required SshService sshService, // SSH 连接服务依赖 (使用 SshService)
    // 移除旧的构造函数参数
    // required ServerService serverService,
    // required AuthModel authModel,
    // required GameModel gameModel,
  }) : _deviceModel = deviceModel,
       _sshService = sshService
       // 移除旧的初始化逻辑
       // _initFromGameModel();
       // cardKeyController.text = _gameModel.cardKey;
       // _serverService.addMessageListener(_handleServerMessage);
       {
    log.i(_logTag, '初始化HomeController (新结构)');
    // TODO: 在此处加载最近连接列表或其他初始化操作
  }

  // 移除旧的方法
  // void setHeaderController(HeaderController controller) { ... }
  // void _syncFromHeader() { ... }
  // void _initFromGameModel() { ... }
  // void selectGame(CardItem game) { ... }
  // void _notifyServerModelChanged(String changeType) { ... }
  // void onCardKeyChanged(String value) { ... }
  // List<CardItem> getGameCards() { ... }
  // String? getInitialSelectedId() => _selectedGame?.id;
  // void refreshHomeConfig() { ... }
  // void saveHomeConfig(BuildContext context) { ... }
  // void _handleServerMessage(String message) { ... }
  // @override void dispose() { ... }

  /// 连接到指定的设备并跳转到终端页面
  void connectToDevice(BuildContext context, SshDevice device) async {
    log.i(_logTag, '尝试连接到设备: ${device.name} (${device.host}:${device.port})');

    // TODO: 实现实际的 SSH 连接逻辑
    // 使用 _sshService 进行连接
    // 示例: await _sshService.connect(device.host, device.port);

    // 连接成功后，导航到终端页面
    // 为了演示，这里直接导航
    Navigator.push(context, MaterialPageRoute(builder: (context) => TerminalScreen()));

    // TODO: 如果连接失败，显示错误提示
    log.i(_logTag, '导航到终端页面');
  }
} 