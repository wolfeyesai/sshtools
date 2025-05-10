import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 认证模型类 - 管理用户认证状态
class AuthModel extends ChangeNotifier {
  String _username = '';
  String _token = '';
  DateTime? _lastLoginTime;
  bool _isAuthenticated = false;
  bool _rememberPassword = false;

  // Getters
  String get username => _username;
  String get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get rememberPassword => _rememberPassword;
  DateTime? get lastLoginTime => _lastLoginTime;

  // 从持久化存储加载认证状态
  Future<void> loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    
    _username = prefs.getString('username') ?? '';
    _token = prefs.getString('token') ?? '';
    _rememberPassword = prefs.getBool('rememberPassword') ?? false;
    
    final lastLoginTimeStr = prefs.getString('lastLoginTime') ?? '';
    if (lastLoginTimeStr.isNotEmpty) {
      try {
        _lastLoginTime = DateTime.parse(lastLoginTimeStr);
        // 检查登录是否在24小时内有效
        if (_lastLoginTime != null && 
            DateTime.now().difference(_lastLoginTime!).inHours < 24 &&
            _token.isNotEmpty) {
          _isAuthenticated = true;
        }
      } catch (e) {
        debugPrint('解析登录时间出错: $e');
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    
    notifyListeners();
  }

  // 设置认证信息
  Future<void> setAuthInfo({
    required String username, 
    required String token,
    bool rememberPassword = false,
  }) async {
    _username = username;
    _token = token;
    _rememberPassword = rememberPassword;
    _lastLoginTime = DateTime.now();
    _isAuthenticated = true;
    
    await _saveAuthState();
    notifyListeners();
  }

  // 退出登录
  Future<void> logout() async {
    // 保存用户名以供记住
    final String savedUsername = _username;
    final bool shouldRemember = _rememberPassword;
    
    // 清除认证信息
    _token = '';
    _isAuthenticated = false;
    _lastLoginTime = null;
    
    // 记住密码功能处理
    if (shouldRemember) {
      // 确保用户名被保留 - 不要修改_username
      debugPrint('记住密码已启用，保留用户名: $savedUsername');
    } else {
      // 仅在未选择记住密码时清除用户名
      _username = '';
    }
    
    // 保存认证状态
    await _saveAuthState();
    
    // 通知监听器
    notifyListeners();
  }

  // 保存认证状态到持久化存储
  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('username', _username);
    await prefs.setString('token', _token);
    await prefs.setBool('rememberPassword', _rememberPassword);
    
    if (_lastLoginTime != null) {
      await prefs.setString('lastLoginTime', _lastLoginTime!.toIso8601String());
    } else {
      await prefs.setString('lastLoginTime', '');
    }
  }
} 