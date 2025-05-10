// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, unreachable_switch_default, unused_import, unused_local_variable, unused_element, unnecessary_import, dead_code, invalid_use_of_visible_for_testing_member, unused_field, use_build_context_synchronously, deprecated_member_use, deprecated_member_use, duplicate_ignore, use_super_parameters

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../component/dropdown_component.dart';
import '../component/status_indicator_component.dart'; // 导入状态指示器组件
import '../controllers/header_controller.dart';
import '../models/auth_model.dart'; // 导入AuthModel
import '../models/ui_config_model.dart'; // 导入UI配置模型
import '../services/server_service.dart'; // 导入ServerService
import 'dart:developer' as developer;
import 'dart:async';
import '../models/status_bar_model.dart';
import '../models/login_model.dart';
import '../models/game_model.dart';

/// 头部页面组件
class HeaderScreen extends StatefulWidget {
  /// 退出登录回调
  final VoidCallback onLogout;

  /// 刷新系统回调
  final VoidCallback onRefreshSystem;

  /// 构造函数
  const HeaderScreen({
    Key? key,
    required this.onLogout,
    required this.onRefreshSystem,
  }) : super(key: key);

  @override
  _HeaderScreenState createState() => _HeaderScreenState();
}

/// 头部页面组件状态
class _HeaderScreenState extends State<HeaderScreen> {
  // 添加控制器
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  
  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
  
  // 显示连接对话框
  void _showConnectionDialog(BuildContext context, ServerService serverService) {
    // 获取LoginModel
    final loginModel = Provider.of<LoginModel>(context, listen: false);
    
    // 预填充保存的连接信息
    _addressController.text = loginModel.serverAddress.isNotEmpty ? 
                             loginModel.serverAddress : '127.0.0.1';
    _portController.text = loginModel.serverPort.isNotEmpty ? 
                         loginModel.serverPort : '4415';
    _tokenController.text = loginModel.token;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接到服务器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: '输入服务器地址，如 127.0.0.1',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '服务器端口',
                  hintText: '输入服务器端口，如 4415',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token (可选)',
                  hintText: '如果服务器需要认证，请输入Token',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final address = _addressController.text.trim();
              final port = _portController.text.trim();
              final token = _tokenController.text.trim();
              
              if (address.isEmpty || port.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('地址和端口不能为空')),
                );
                return;
              }
              
              // 更新LoginModel
              loginModel.updateServerAddress(address);
              loginModel.updateServerPort(port);
              if (token.isNotEmpty) {
                loginModel.updateToken(token);
              }
              
              // 关闭对话框
              Navigator.of(context).pop();
              
              // 连接到服务器
              _connectToServer(context, serverService, address, port, token);
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }
  
  // 连接到服务器
  void _connectToServer(BuildContext context, ServerService serverService, 
                      String address, String port, String token) {
    // 显示正在连接的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在连接到服务器...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // 连接到服务器
    serverService.handleConnectService(context, address, port, token);
    
    // 延迟检查连接状态并更新UI
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {});
        
        // 获取HeaderController以更新游戏选择器
        final headerController = Provider.of<HeaderController>(context, listen: false);
        headerController.notifyListeners();
        
        // 发送状态栏查询请求和心跳请求
        if (serverService.isConnected) {
          developer.log('连接成功，发送状态栏查询请求');
          
          // 发送状态栏查询请求，根据API规范只需token参数
          serverService.sendMessage({
            'action': 'status_bar_query',
            'token': token,
          });
          
          // 发送心跳请求
          _sendHeartbeatRequest(serverService);
          
          // 连接成功，显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('连接服务器成功'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 连接失败，显示失败提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('连接服务器失败: ${serverService.errorText}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
  
  // 发送心跳请求
  void _sendHeartbeatRequest(ServerService serverService) {
    if (!serverService.isConnected) return;
    
    try {
      // 简化的心跳请求，只发送基本信息
      final heartbeatRequest = {
        'action': 'heartbeat',
        'content': {
          'clientStatus': 'active',
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送请求
      serverService.sendMessage(heartbeatRequest);
      developer.log('已发送心跳请求');
    } catch (e) {
      developer.log('发送心跳请求失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用Provider获取各种模型
    final headerController = Provider.of<HeaderController>(context);
    final authModel = Provider.of<AuthModel>(context);
    final uiConfigModel = Provider.of<UIConfigModel>(context);
    final serverService = Provider.of<ServerService>(context);
    
    // 获取用户名和屏幕信息
    final String username = authModel.username;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    // 获取游戏标签和UI配置
    final gameLabels = headerController.getAllGameLabels();
    final dropdownItems = headerController.convertToIconDropdownItems(gameLabels);
    final double dropdownWidth = uiConfigModel.dropdownWidth;
    final double dropdownHeight = uiConfigModel.dropdownHeight;
    final Color backgroundColor = uiConfigModel.backgroundColor;
    final Color textColor = uiConfigModel.textColor;
    final double fontSize = uiConfigModel.fontSize;
    final FontWeight fontWeight = uiConfigModel.fontWeight;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧标题
          if (!isSmallScreen)
            const Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text(
                '辅助系统',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 52, 100, 172),
                ),
              ),
            ),

          // 中间的游戏选择器
          Container(
            width: isSmallScreen ? dropdownWidth : dropdownWidth * 2,
            height: dropdownHeight,
            constraints: const BoxConstraints(
              minWidth: 100,
              maxHeight: 50,
            ),
            child: IconDropdown(
              value: headerController.selectedGame.id,
              items: dropdownItems,
              onChanged: headerController.handleGameSelected,
              height: dropdownHeight,
              width: null,
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: BorderRadius.circular(8),
              border: const BorderSide(color: Colors.black12, width: 1),
              dropdownButtonColor: backgroundColor,
              textStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
              ),
              dropdownIcon: Icons.arrow_drop_down,
              showTextOnSmallScreens: false,
              smallScreenWidth: 600,
            ),
          ),

          // 弹性间隔
          const Spacer(),
          
          // WebSocket连接状态指示器
          Container(
            width: 40,
            height: 64,
            alignment: Alignment.center,
            child: HoverStatusIndicator(
              serverService: serverService,
            ),
          ),

          // 右侧用户信息和操作按钮
          Row(
            children: [
              // 用户名显示
              if (!isSmallScreen) 
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    username,
                    style: TextStyle(
                      fontWeight: fontWeight,
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  ),
                ),

              // 用户头像
              GFAvatar(
                size: 20,
                backgroundColor: const Color.fromARGB(255, 52, 100, 172),
                child: Text(
                  username.isNotEmpty 
                      ? username[0].toUpperCase() 
                      : 'A',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),

              // 刷新按钮
              GFIconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color.fromARGB(255, 52, 100, 172),
                ),
                onPressed: () => _handleRefreshButtonPressed(context, serverService),
                tooltip: '刷新连接',
                type: GFButtonType.transparent,
                size: GFSize.SMALL,
                highlightColor: Colors.blue.withOpacity(0.2),
                hoverColor: Colors.blue.withOpacity(0.1),
                splashColor: Colors.blue.withOpacity(0.3),
              ),

              // 退出按钮
              GFIconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 52, 100, 172),
                ),
                onPressed: () {
                  // 调用控制器的登出方法
                  headerController.handleLogout(context);
                  // 调用传入的回调
                  widget.onLogout();
                },
                type: GFButtonType.transparent,
                size: GFSize.SMALL,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 处理刷新按钮点击
  void _handleRefreshButtonPressed(BuildContext context, ServerService serverService) {
    // 获取登录模型和头部控制器
    final loginModel = Provider.of<LoginModel>(context, listen: false);
    final headerController = Provider.of<HeaderController>(context, listen: false);
    
    // 检查连接状态
    if (!serverService.isConnected || 
        serverService.serverAddress.isEmpty || 
        serverService.serverPort.isEmpty) {
      // 尝试从LoginModel获取连接信息
      final address = loginModel.serverAddress;
      final port = loginModel.serverPort;
      final token = loginModel.token;
      
      if (address.isNotEmpty && port.isNotEmpty) {
        // 直接尝试连接
        _connectToServer(context, serverService, address, port, token);
        developer.log('使用保存的连接信息连接: $address:$port');
      } else {
        // 显示连接对话框
        _showConnectionDialog(context, serverService);
        developer.log('显示连接对话框');
      }
    } else {
      // 显示刷新提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在刷新连接...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
      
      // 发送状态栏查询请求
      serverService.sendMessage({
        'action': 'status_bar_query',
        'token': serverService.token,
      });
      developer.log('已发送状态栏查询请求');
      
      // 发送心跳请求
      _sendHeartbeatRequest(serverService);
      
      // 调用控制器和回调方法
      headerController.handleRefreshSystem();
      widget.onRefreshSystem();
      
      // 检查连接状态
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && serverService.isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('连接刷新成功'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }
}

/// 悬停状态指示器组件
class HoverStatusIndicator extends StatefulWidget {
  final ServerService serverService;

  const HoverStatusIndicator({
    required this.serverService,
    Key? key,
  }) : super(key: key);

  @override
  _HoverStatusIndicatorState createState() => _HoverStatusIndicatorState();
}

class _HoverStatusIndicatorState extends State<HoverStatusIndicator> {
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _startHeartbeatCheck();
  }

  @override
  void dispose() {
    _hideOverlay();
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeatCheck() {
    _heartbeatTimer?.cancel();
    // 每秒检查一次心跳状态
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 判断心跳是否健康
  bool get _isHeartbeatHealthy {
    final lastHeartbeat = widget.serverService.lastHeartbeat;
    if (lastHeartbeat == null) return false;
    
    // 如果最后心跳时间在20秒内，认为是健康的
    return DateTime.now().difference(lastHeartbeat).inSeconds <= 20;
  }

  void _showOverlay(BuildContext context) {
    _hideOverlay();
    
    // 获取状态和定位信息
    final statusBarModel = widget.serverService.statusBarModel;
    final serverService = widget.serverService;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 130,
        top: offset.dy + size.height + 5,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WebSocket连接状态
                StatusIndicatorComponent.create(
                  message: serverService.isConnected ? '服务器连接状态: 已连接' : 
                        serverService.isConnecting ? '服务器连接状态: 连接中...' : 
                        serverService.hasError ? '服务器连接状态: 连接错误' : '服务器连接状态: 未连接',
                  description: serverService.isConnected ? 
                            '${serverService.serverAddress}:${serverService.serverPort}' : 
                            serverService.hasError ? serverService.errorText : null,
                  type: serverService.isConnected ? StatusType.success : 
                        serverService.isConnecting ? StatusType.loading : 
                        serverService.hasError ? StatusType.error : StatusType.neutral,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  borderRadius: 6.0,
                ),
                
                const SizedBox(height: 8),
                
                // 心跳状态
                if (serverService.isConnected)
                  StatusIndicatorComponent.create(
                    message: '心跳状态: ${_isHeartbeatHealthy ? '正常' : '异常'}',
                    description: serverService.lastHeartbeat != null 
                        ? '最后心跳时间: ${_formatDateTime(serverService.lastHeartbeat!)}'
                        : '尚未收到心跳',
                    type: _isHeartbeatHealthy ? StatusType.success : StatusType.error,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    borderRadius: 6.0,
                  ),
                
                const SizedBox(height: 8),
                
                // 服务状态信息 - 显示status_bar_query返回的状态
                if (serverService.isConnected)
                  StatusIndicatorComponent.createServiceStatusCard(
                    dbStatus: statusBarModel.dbStatus,
                    inferenceStatus: statusBarModel.inferenceStatus,
                    cardKeyStatus: statusBarModel.cardKeyStatus,
                    keyMouseStatus: statusBarModel.keyMouseStatus,
                    updatedAt: statusBarModel.updatedAt,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final serverService = widget.serverService;
    
    return MouseRegion(
      onEnter: (_) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
          _showOverlay(context);
        }
      },
      onExit: (_) {
        if (_isHovering) {
          setState(() => _isHovering = false);
          // 延迟隐藏，避免闪烁
          _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 100), () {
            _hideOverlay();
          });
        }
      },
      cursor: SystemMouseCursors.click,
      child: Stack(
        children: [
          // 云图标
          Icon(
            serverService.isConnected ? Icons.cloud_done :
            serverService.isConnecting ? Icons.cloud_sync :
            serverService.hasError ? Icons.cloud_off : Icons.cloud_queue,
            color: serverService.isConnected ? Colors.green :
                  serverService.isConnecting ? Colors.purple :
                  serverService.hasError ? Colors.red : Colors.grey,
            size: 24,
          ),
          
          // 心跳状态指示
          if (serverService.isConnected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHeartbeatHealthy ? Colors.green : Colors.red,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
