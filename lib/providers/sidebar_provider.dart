// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../views/ssh_terminal_screen.dart';

/// 侧边栏状态管理
class SidebarProvider extends ChangeNotifier {
  /// 当前选中的索引
  int _selectedIndex = 0;
  
  /// 终端页面内容
  Widget _terminalPage = const EmptyTerminalWidget();
  
  /// 是否已销毁
  bool _isDisposed = false;
  
  /// 获取当前索引
  int get selectedIndex => _selectedIndex;
  
  /// 获取终端页面
  Widget get terminalPage => _terminalPage;
  
  /// 安全地通知监听器
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('SidebarProvider通知监听器时出错: $e');
      }
    }
  }
  
  /// 设置当前索引
  void setIndex(int index) {
    try {
      if (_selectedIndex != index) {
        _selectedIndex = index;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('设置侧边栏索引出错: $e');
    }
  }
  
  /// 更新终端页面
  void updateTerminalPage(Widget page) {
    try {
      _terminalPage = page;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('更新终端页面出错: $e');
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// 空终端页面组件
class EmptyTerminalWidget extends StatelessWidget {
  const EmptyTerminalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.terminal,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '无活动终端连接',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请在IP管理页面选择设备以创建SSH连接',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 切换到IP页面
              Provider.of<SidebarProvider>(context, listen: false).setIndex(0);
            },
            icon: const Icon(Icons.search),
            label: const Text('查找设备'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
} 