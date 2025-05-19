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

  /// 命令管理页面（静态页面）
  Widget? _commandPage;
  
  /// 是否已销毁
  bool _isDisposed = false;
  
  /// 最后一次状态更新时间
  DateTime _lastUpdateTime = DateTime.now();
  
  /// 获取当前索引
  int get selectedIndex => _selectedIndex;
  
  /// 获取终端页面
  Widget get terminalPage => _terminalPage;

  /// 获取命令管理页面
  Widget? get commandPage => _commandPage;

  /// 设置命令管理页面
  set commandPage(Widget? page) {
    if (_commandPage != page) {
      _commandPage = page;
      _safeNotifyListeners();
    }
  }
  
  /// 安全地通知监听器
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        // 限制高频率更新，避免冲突
        final now = DateTime.now();
        if (now.difference(_lastUpdateTime).inMilliseconds < 50) {
          debugPrint('SidebarProvider: 更新频率过高，延迟通知');
          // 如果更新太频繁，延迟一下再通知
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!_isDisposed) {
              _lastUpdateTime = DateTime.now();
              notifyListeners();
            }
          });
          return;
        }
        
        _lastUpdateTime = now;
        notifyListeners();
      } catch (e) {
        debugPrint('SidebarProvider通知监听器时出错: $e');
      }
    }
  }
  
  /// 设置当前索引
  void setIndex(int index) {
    try {
      debugPrint('SidebarProvider: 设置索引从 $_selectedIndex 到 $index');
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
      debugPrint('SidebarProvider: 更新终端页面内容');
      _terminalPage = page;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('更新终端页面出错: $e');
    }
  }
  
  /// 强制刷新UI
  void refresh() {
    debugPrint('SidebarProvider: 强制刷新UI');
    _safeNotifyListeners();
  }
  
  @override
  void dispose() {
    debugPrint('SidebarProvider: dispose()');
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