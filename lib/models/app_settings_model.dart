// ignore_for_file: unnecessary_import, prefer_final_fields, sort_child_properties_last

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 视图导入
import '../views/login_screen.dart';
import '../views/register_screen.dart';
import '../views/layout_screen.dart';
import '../views/home_screen.dart';
import '../views/function/function_screen.dart';
import '../views/pid_screen.dart';
import '../views/fov_screen.dart';
import '../views/aim_screen.dart';
import '../views/fire_screen.dart';
import '../views/data_collection_screen.dart';

/// 应用设置模型 - 管理应用全局设置
class AppSettingsModel extends ChangeNotifier {
  // 主题设置
  bool _isDarkMode = false;
  
  // 语言设置
  String _language = 'zh_CN';
  
  // 是否首次启动
  bool _isFirstLaunch = true;
  
  // 是否开发模式
  bool _isDevelopMode = false;
  
  // 路由定义
  final Map<String, String> _routePaths = {
    'home': '/',
    'login': '/login',
    'register': '/register',
    'function': '/function',
    'pid': '/pid',
    'fov': '/fov',
    'aim': '/aim',
    'fire': '/fire',
    'data_collection': '/data_collection',
  };
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isDevelopMode => _isDevelopMode;
  Map<String, String> get routePaths => _routePaths;
  
  // 获取路由表
  Map<String, WidgetBuilder> getRoutes(BuildContext context) {
    // 定义通用回调函数
    void onLogout() {
      // 调用全局导航回到登录页面
      Navigator.of(context).pushReplacementNamed('/login');
    }
    
    void onRefreshSystem() {
      // 这里可以添加刷新系统的逻辑
    }
    
    void onRefreshData() {
      // 这里可以添加刷新数据的逻辑
    }
    
    return {
      '/': (context) => MainLayout(
        child: const HomeScreen(),
        currentPageId: 'home',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/home': (context) => MainLayout(
        child: const HomeScreen(),
        currentPageId: 'home',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/function': (context) => MainLayout(
        child: const FunctionScreen(),
        currentPageId: 'function',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/pid': (context) => MainLayout(
        child: const PidScreen(),
        currentPageId: 'pid',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/fov': (context) => MainLayout(
        child: const FovScreen(),
        currentPageId: 'fov',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/aim': (context) => MainLayout(
        child: const AimScreen(),
        currentPageId: 'aim',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/fire': (context) => MainLayout(
        child: const FireScreen(),
        currentPageId: 'fire',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/data_collection': (context) => MainLayout(
        child: const DataCollectionScreen(),
        currentPageId: 'data_collection',
        onLogout: onLogout,
        onRefreshSystem: onRefreshSystem,
        onRefreshData: onRefreshData,
      ),
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const RegisterScreen(),
    };
  }
  
  // 切换主题模式
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }
  
  // 设置语言
  void setLanguage(String lang) {
    _language = lang;
    _saveSettings();
    notifyListeners();
  }
  
  // 设置首次启动状态
  void setFirstLaunch(bool isFirst) {
    _isFirstLaunch = isFirst;
    _saveSettings();
    notifyListeners();
  }
  
  // 切换开发模式
  void toggleDevelopMode() {
    _isDevelopMode = !_isDevelopMode;
    _saveSettings();
    notifyListeners();
  }
  
  // 从持久化存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'zh_CN';
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    _isDevelopMode = prefs.getBool('isDevelopMode') ?? false;
    
    notifyListeners();
  }
  
  // 保存设置到持久化存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('language', _language);
    await prefs.setBool('isFirstLaunch', _isFirstLaunch);
    await prefs.setBool('isDevelopMode', _isDevelopMode);
  }
} 