// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sidebar_provider.dart';

/// 侧边栏组件
class SidebarScreen extends StatelessWidget {
  /// 页面列表（第一个页面为IP页面）
  final List<Widget> pageList;
  
  /// 是否显示在底部
  final bool isBottom;
  
  /// 构造函数
  const SidebarScreen({
    Key? key,
    required this.pageList,
    this.isBottom = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 确保pageList至少有第一个页面（IP页面）
    if (pageList.isEmpty) {
      throw ArgumentError('pageList must not be empty');
    }
    
    // 直接使用_SidebarContent，不创建新的SidebarProvider
    return _SidebarContent(
      ipPage: pageList[0],
      isBottom: isBottom,
    );
  }
}

/// 侧边栏内容
class _SidebarContent extends StatelessWidget {
  /// IP页面（第一个页面）
  final Widget ipPage;
  
  /// 是否显示在底部
  final bool isBottom;
  
  /// 构造函数
  const _SidebarContent({
    Key? key,
    required this.ipPage,
    required this.isBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SidebarProvider>(context);
    
    // 构建页面列表（IP页面和动态终端页面）
    final pages = [
      ipPage,                // 第一个页面是固定的IP页面
      provider.terminalPage  // 第二个页面是动态终端页面
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: provider.selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: isBottom 
        ? _buildBottomNavigationBar(context, provider)
        : null,
      drawer: !isBottom 
        ? _buildDrawer(context, provider)
        : null,
    );
  }
  
  /// 构建底部导航栏
  Widget _buildBottomNavigationBar(BuildContext context, SidebarProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).navigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          currentIndex: provider.selectedIndex,
          onTap: provider.setIndex,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            _buildNavItem(
              icon: Icons.home_rounded,
              activeIcon: Icons.home_rounded,
              label: '首页',
            ),
            _buildNavItem(
              icon: Icons.terminal,
              activeIcon: Icons.terminal,
              label: '终端',
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建导航项
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Icon(icon),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
  
  /// 构建抽屉菜单
  Widget _buildDrawer(BuildContext context, SidebarProvider provider) {
    return Drawer(
      elevation: 2,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.terminal_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'SSH工具',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '多平台终端管理工具',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            provider: provider,
            index: 0,
            icon: Icons.home_rounded,
            title: '首页',
          ),
          _buildDrawerItem(
            context: context,
            provider: provider,
            index: 1,
            icon: Icons.terminal,
            title: '终端',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              // 设置页面导航
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助'),
            onTap: () {
              // 帮助页面导航
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建抽屉菜单项
  Widget _buildDrawerItem({
    required BuildContext context,
    required SidebarProvider provider,
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = provider.selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          provider.setIndex(index);
          Navigator.pop(context);
        },
      ),
    );
  }
} 