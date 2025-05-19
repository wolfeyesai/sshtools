// ignore_for_file: unused_import, unnecessary_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'views/sidebar_screen.dart';
import 'views/ip_screen.dart';
import 'providers/sidebar_provider.dart';
import 'controllers/ssh_controller.dart';
import 'controllers/ssh_command_controller.dart';
import 'controllers/ssh_session_controller.dart';
import 'controllers/ip_controller.dart';
import 'models/ssh_header_model.dart';
import 'component/ssh_command_edit_dialog.dart';
import 'component/message_component.dart';

/// 自定义导航观察器，处理潜在的导航问题
class CustomNavigatorObserver extends NavigatorObserver {
  /// 最后一次路由变化时间
  DateTime? _lastRouteTime;
  
  /// 是否正在执行路由操作
  bool _isNavigating = false;
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setNavigating();
    super.didPush(route, previousRoute);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setNavigating();
    super.didPop(route, previousRoute);
  }
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setNavigating();
    super.didRemove(route, previousRoute);
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _setNavigating();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
  
  /// 设置正在导航状态
  void _setNavigating() {
    _isNavigating = true;
    _lastRouteTime = DateTime.now();
    
    // 300毫秒后重置导航状态
    Future.delayed(const Duration(milliseconds: 300), () {
      _isNavigating = false;
    });
  }
  
  /// 检查是否可以安全地执行另一个导航操作
  bool canNavigate() {
    if (_isNavigating) return false;
    
    final now = DateTime.now();
    if (_lastRouteTime != null) {
      final diff = now.difference(_lastRouteTime!).inMilliseconds;
      if (diff < 300) return false;
    }
    
    return true;
  }
}

void main() async {
  // 确保Flutter已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 禁用Provider类型检查错误
  Provider.debugCheckInvalidValueType = null;
  
  // 处理键盘错误
  FlutterError.onError = (FlutterErrorDetails details) {
    // 捕获并忽略键盘事件相关的错误
    if (details.exception.toString().contains('hardware_keyboard') &&
        details.exception.toString().contains('key is already pressed')) {
      // 忽略这个错误
      return;
    }
    
    // 捕获Caps Lock键盘事件错误
    if (details.exception.toString().contains('Attempted to send a key down event when no keys are in keysPressed') ||
        details.exception.toString().contains('Caps Lock') ||
        details.exception.toString().contains('event is! RawKeyDownEvent || _keysPressed.isNotEmpty')) {
      // 忽略Caps Lock键盘事件错误
      debugPrint('捕获到Caps Lock键盘事件错误: ${details.exception}');
      return;
    }
    
    // 捕获JSON解析错误
    if (details.exception.toString().contains('Unable to parse JSON message') ||
        details.exception.toString().contains('The document is empty')) {
      // 忽略JSON解析错误
      debugPrint('捕获到JSON解析错误: ${details.exception}');
      return;
    }
    
    // 捕获平台消息调度错误
    if (details.exception.toString().contains('PlatformDispatcher._dispatchPlatformMessage') ||
        details.exception.toString().contains('channel_buffers.dart') ||
        details.exception.toString().contains('_dispatchPlatformMessage')) {
      // 忽略平台消息调度错误
      debugPrint('捕获到平台消息调度错误: ${details.exception}');
      return;
    }
    
    // 捕获UI构建和状态错误
    if (details.exception.toString().contains('setState') ||
        details.exception.toString().contains('build') ||
        details.exception.toString().contains('performRebuild') ||
        details.exception.toString().contains('notifyListeners') ||
        details.exception.toString().contains('sending notification') ||
        details.exception.toString().contains('was:') ||
        details.exception.toString().contains('setState() called')) {
      // 忽略UI构建和状态错误
      debugPrint('捕获到UI构建或状态错误: ${details.exception}');
      return;
    }
    
    // 捕获文本渲染相关的错误
    if (details.exception.toString().contains('TextSpan') ||
        details.exception.toString().contains('text span') ||
        details.exception.toString().contains('renderObject')) {
      // 记录错误但继续运行应用
      debugPrint('捕获到文本渲染错误: ${details.exception}');
      return;
    }
    
    // 处理其他错误
    FlutterError.presentError(details);
  };
  
  // 设置全局未捕获异常处理器
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('捕获到全局未处理异常: $error');
    debugPrint('堆栈跟踪: $stack');
    // 返回true表示异常已处理
    return true;
  };
  
  // 创建和预初始化控制器
  final commandController = SSHCommandController();
  final sessionController = SSHSessionController();
  
  // 初始化控制器
  debugPrint('应用启动: 开始初始化SSH命令和会话控制器...');
  await commandController.init();
  await sessionController.init();
  debugPrint('应用启动: 命令控制器加载了 ${commandController.commandCount} 个命令');
  debugPrint('应用启动: 会话控制器加载了 ${sessionController.sessionCount} 个会话');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => SSHController()),
        ChangeNotifierProvider.value(value: commandController),
        ChangeNotifierProvider.value(value: sessionController),
        ChangeNotifierProvider(create: (_) => IPController()),
      ],
      child: const MyApp(),
    ),
  );
}

// 创建全局导航观察器实例
final navigatorObserver = CustomNavigatorObserver();

class MyApp extends StatelessWidget {
  // ignore: use_super_parameters
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SSHTools',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Colors.blue.shade100,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.grey.shade900,
            indicatorColor: Colors.blue.shade900,
          ),
        ),
        navigatorObservers: [navigatorObserver],
        themeMode: ThemeMode.system,
        home: const HomeWrapper(),
    );
  }
}

/// 主页包装器
class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用已存在的SidebarProvider实例
    // ignore: unused_local_variable
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    
    // 只需要传递IP页面，终端页面将由SidebarProvider动态管理
    return SidebarScreen(
      pageList: [
        IPPage(), // IP搜索页面作为首页
      ],
      isBottom: true,
    );
  }
}

/// 空终端页面 - 显示在用户选择连接之前
class EmptyTerminalPage extends StatelessWidget {
  const EmptyTerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH终端'),
        elevation: 2,
      ),
      body: Center(
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
      ),
    );
  }
}
