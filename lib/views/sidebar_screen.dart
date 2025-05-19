// ignore_for_file: use_super_parameters, duplicate_ignore, unused_local_variable, deprecated_member_use, prefer_conditional_assignment

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sidebar_provider.dart';
import '../controllers/ssh_controller.dart';
import '../models/ssh_header_model.dart';
import '../controllers/ssh_header_controller.dart';
import '../views/ssh_command_manager_screen.dart';

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
    
    // 确保命令管理页面已初始化
    if (provider.commandPage == null) {
      provider.commandPage = const SSHCommandManagerPage();
    }
    
    // 构建页面列表（IP页面、动态终端页面和命令管理页面）
    final pages = [
      ipPage,                // 第一个页面是固定的IP页面
      provider.terminalPage, // 第二个页面是动态终端页面
      provider.commandPage!, // 第三个页面是命令管理页面
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
    return NavigationBar(
      selectedIndex: provider.selectedIndex,
      onDestinationSelected: (index) {
        // 检查SSH控制器是否正在传输文件
        if (provider.selectedIndex == 1 && index != 1) {
          // 当前在终端页面，准备切换到其他页面
          // 获取SSH控制器实例
          final sshController = Provider.of<SSHController>(context, listen: false);
          
          // 创建临时SSH头部控制器来检查文件传输状态
          final headerModel = SSHHeaderModel(
            title: '终端',
            isConnected: sshController.isConnected,
          );
          
          final headerController = SSHHeaderController(
            model: headerModel,
            sshController: sshController,
          );
          
          // 如果正在传输文件，显示确认对话框
          if (headerController.isTransferringFile) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('文件传输进行中'),
                  ],
                ),
                content: const Text(
                  '有文件传输正在进行，切换页面后传输将在后台继续。\n您确定要切换页面吗？',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 切换到请求的页面
                      provider.setIndex(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('继续切换'),
                  ),
                ],
              ),
            );
            // 释放临时控制器资源
            headerController.dispose();
            return;
          }
          
          // 释放临时控制器资源
          headerController.dispose();
        }
        
        // 没有文件传输或不是从终端页面切换，直接设置索引
        provider.setIndex(index);
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
      destinations: [
        NavigationDestination(
          icon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(Icons.home_rounded),
          ),
          label: '首页',
        ),
        NavigationDestination(
          icon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(Icons.terminal),
          ),
          label: '终端',
        ),
        NavigationDestination(
          icon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Icon(Icons.code),
          ),
          label: '命令',
        ),
      ],
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
          _buildDrawerItem(
            context: context,
            provider: provider,
            index: 2,
            icon: Icons.code,
            title: '命令管理',
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