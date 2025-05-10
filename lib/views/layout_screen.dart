// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blui/views/side_screen.dart';
import 'package:blui/views/header_screen.dart';
import 'package:blui/models/sidebar_model.dart';  // 导入侧边栏模型
import 'package:blui/controllers/side_controller.dart';  // 导入侧边栏控制器
import 'package:blui/utils/logger.dart';  // 导入日志工具
import 'package:blui/models/login_model.dart';  // 导入登录模型

/// 主布局组件 - 仅负责基础布局
class MainLayout extends StatefulWidget {
  /// 子组件
  final Widget child;
  
  /// 当前页面ID
  final String currentPageId;
  
  /// 退出登录回调
  final VoidCallback onLogout;
  
  /// 刷新系统回调
  final VoidCallback onRefreshSystem;
  
  /// 刷新数据回调
  final VoidCallback onRefreshData;
  
  /// 创建主布局组件
  const MainLayout({
    Key? key,
    required this.child,
    required this.currentPageId,
    required this.onLogout,
    required this.onRefreshSystem,
    required this.onRefreshData,
  }) : super(key: key);
  
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

/// 主布局组件状态
class _MainLayoutState extends State<MainLayout> {
  /// 应用版本
  final String appVersion = "1.0.0";
  
  /// 当前页面索引
  int _currentPageIndex = 0;
  
  /// 日志工具
  final log = Logger();
  
  /// 日志标签
  final String _logTag = 'MainLayout';
  
  /// 页面ID到索引的映射
  final Map<String, int> _pageIndices = {
    'login': 0,
    'register': 1,
    'button': 2,
    'message': 3,
    'data': 4,
    'component': 5,
    'side': 6,
  };
  
  @override
  void initState() {
    super.initState();
    // 初始化当前页面索引
    _currentPageIndex = _pageIndices[widget.currentPageId] ?? 0;
    
    log.i(_logTag, 'MainLayout已初始化，当前页面ID: ${widget.currentPageId}');
    
    // 使用微任务延迟初始化，确保所有Provider都已准备好且UI已完全构建
    Future.microtask(() {
      if (!mounted) return;
      
      // 安全地检查是否需要在登录后刷新数据
      try {
        final loginModel = Provider.of<LoginModel>(context, listen: false);
        if (loginModel.refreshAfterLogin) {
          log.i(_logTag, '检测到登录/注册后刷新标记，正在重置标记');
          // 立即重置刷新标记，避免重复刷新
          loginModel.updateRefreshAfterLogin(false);
          
          // 使用microtask而不是延迟，确保UI线程不被阻塞
          Future.microtask(() {
            // 再次检查组件是否仍然挂载
            if (!mounted) return;
            
            try {
              log.i(_logTag, '正在执行登录后的数据刷新');
              // 获取SideController并刷新所有页面数据
              final sideController = Provider.of<SideController>(context, listen: false);
              sideController.refreshData(context);
              log.i(_logTag, '登录/注册后自动刷新所有页面数据完成');
            } catch (e) {
              log.e(_logTag, '自动刷新页面数据失败', e.toString());
            }
          });
        }
      } catch (e) {
        log.e(_logTag, '检查刷新标记时出错', e.toString());
      }
    });
  }
  
  @override
  void dispose() {
    log.i(_logTag, 'MainLayout已释放');
    super.dispose();
  }
  
  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPageId != oldWidget.currentPageId) {
      final pageIndex = _pageIndices[widget.currentPageId] ?? 0;
      if (_currentPageIndex != pageIndex) {
        setState(() {
          _currentPageIndex = pageIndex;
        });
      }
    }
  }
  
  /// 处理菜单选择
  void _handleMenuSelected(String menuId) {
    // 获取SideController并调用请求数据方法
    final sideController = Provider.of<SideController>(context, listen: false);
    
    // 为调试目的，可以打印选中菜单项ID
    log.i(_logTag, '菜单被选中: $menuId');
    
    // 调用侧边栏控制器的requestPageData方法
    sideController.requestPageData(menuId, context);
  }
  
  @override
  Widget build(BuildContext context) {
    // 从Provider获取侧边栏模型
    final sidebarModel = Provider.of<SidebarModel>(context);
    
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 768;
    
    // 获取侧边栏颜色配置
    final Color activeColor = sidebarModel.sidebarConfig['colors']['active'];
    final Color inactiveColor = sidebarModel.sidebarConfig['colors']['inactive'];
    
    return Scaffold(
      // 主体内容
      body: SafeArea(
        child: Column(
          children: [
            // 头部组件 - 使用固定高度避免溢出
            SizedBox(
              height: 64,
              child: HeaderScreen(
                onLogout: widget.onLogout,
                onRefreshSystem: widget.onRefreshSystem,
              ),
            ),
            
            // 头部与主内容区域之间的分隔线
            Container(
              height: 2,
              color: activeColor.withOpacity(0.7),
              width: double.infinity,
            ),
            
            // 主内容区域（水平排列侧边栏和内容）
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 确保侧边栏在小屏幕上自动收缩
                  final bool shouldCollapse = constraints.maxWidth < 768;
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 侧边栏
                      SidebarScreen(
                        selectedMenuId: widget.currentPageId,
                        onMenuSelected: _handleMenuSelected,
                        onRefresh: () {
                          // 使用Provider获取SideController
                          final sideController = Provider.of<SideController>(context, listen: false);
                          sideController.refreshData(context);
                          
                          // 调用刷新数据回调
                          widget.onRefreshData();
                        },
                        version: appVersion,
                        initialCollapsed: shouldCollapse || isSmallScreen,
                      ),
                      
                      // 侧边栏与内容区域之间的垂直分隔线（仅在空间足够时显示）
                      if (constraints.maxWidth > 100) // 确保有足够空间显示分隔线
                        Container(
                          width: 1,
                          color: inactiveColor.withOpacity(0.3),
                        ),
                      
                      // 内容区域 - 添加滚动视图避免溢出
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: 50, // 内容区域最小宽度
                              minHeight: 50, // 内容区域最小高度
                              // 确保高度不超过可用空间
                              maxHeight: MediaQuery.of(context).size.height - 66, // 减去头部和分隔线高度
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
