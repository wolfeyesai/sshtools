// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入页面视图
import './device_screen.dart';
import './terminal_screen.dart';
import './settings_screen.dart';

// 导入页头组件 (如果仍然使用独立的页头)
import './header_screen.dart';

// 导入侧边栏模型和控制器 (如果完全移除侧边栏，这些导入可以移除)
// import 'package:blui/models/sidebar_model.dart';  // 导入侧边栏模型
// import 'package:blui/controllers/side_controller.dart';  // 导入侧边栏控制器

import 'package:blui/utils/logger.dart';  // 导入日志工具
import 'package:blui/models/login_model.dart';  // 导入登录模型
import 'package:blui/models/auth_model.dart';  // 导入认证模型
import 'package:blui/models/ui_config_model.dart';  // 导入UI配置模型
import 'package:blui/services/ssh_service.dart';  // 导入SSH服务
import 'package:blui/controllers/header_controller.dart';  // 导入头部控制器

/// 主布局组件 - 负责基础布局、页头、页中内容和底部导航栏
class MainLayout extends StatefulWidget {
  /// 退出登录回调
  final VoidCallback onLogout;
  
  /// 刷新系统回调
  final VoidCallback onRefreshSystem;
  
  /// 刷新数据回调
  final VoidCallback onRefreshData; // 可能不再需要，取决于刷新逻辑
  
  /// 创建主布局组件
  const MainLayout({
    Key? key,
    required this.onLogout,
    required this.onRefreshSystem,
    required this.onRefreshData, // 可能不再需要
  }) : super(key: key);
  
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

/// 主布局组件状态
class _MainLayoutState extends State<MainLayout> {
  /// 应用版本
  final String appVersion = "1.0.0";
  
  /// 当前页面索引 (对应底部导航栏)
  int _currentPageIndex = 0;
  
  /// 日志工具
  final log = Logger();
  
  /// 日志标签
  final String _logTag = 'MainLayout';
  
  /// 底部导航栏对应的页面列表
  final List<Widget> _pages = [
    const DeviceScreen(),
    const TerminalScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    log.i(_logTag, 'MainLayout已初始化');
    
    // 移除旧的刷新逻辑，如果不需要登录后自动刷新所有页面
    // Future.microtask(() {
    //   if (!mounted) return;
    //   ...
    // });
  }
  
  @override
  void dispose() {
    log.i(_logTag, 'MainLayout已释放');
    super.dispose();
  }
  
  // 底部导航栏项选中时调用
  void _onItemTapped(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // TODO: 可以根据需要在这里触发页面数据的加载或更新
    log.i(_logTag, '底部导航栏选中索引: $index');
  }
  
  @override
  Widget build(BuildContext context) {
    // 确保能够访问所需的Provider模型
    final authModel = Provider.of<AuthModel>(context);
    final uiConfigModel = Provider.of<UIConfigModel>(context);
    final sshService = Provider.of<SshService>(context);
    
    return Scaffold(
      // 主体内容
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: HeaderScreen(
          onLogout: widget.onLogout,
          onRefreshSystem: widget.onRefreshSystem,
        ),
      ),
      body: _pages[_currentPageIndex],
      
      // 底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.devices), // 设备图标
            label: '设备', // 设备标签
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal), // 终端图标
            label: '终端', // 终端标签
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // 设置图标
            label: '设置', // 设置标签
          ),
        ],
        currentIndex: _currentPageIndex,
        selectedItemColor: Colors.blue, // 选中项颜色
        onTap: _onItemTapped, // 处理点击事件
      ),
    );
  }
}

// 移除旧的 _handleMenuSelected 方法，因为侧边栏被移除了
// void _handleMenuSelected(String menuId) { ... }
