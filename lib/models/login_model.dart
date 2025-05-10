// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 登录模型 - 存储登录相关信息
class LoginModel extends ChangeNotifier {
  // 默认值配置
  static const _defaults = {
    'serverAddress': '192.168.5.65',
    'serverPort': '8080',
    'username': 'admin',
    'password': 'admin',
  };
  
  // 服务器信息
  String _serverAddress = _defaults['serverAddress']!;
  String _serverPort = _defaults['serverPort']!;
  
  // 登录信息
  String _username = _defaults['username']!;
  String _password = _defaults['password']!;
  String _token = '';
  bool _rememberPassword = true;
  
  // 登录状态
  String _loginStatus = 'false';
  String _lastLoginTime = '';
  
  // 登录后是否需要刷新
  bool _refreshAfterLogin = false;
  
  // Getters
  String get serverAddress => _serverAddress;
  String get serverPort => _serverPort;
  String get username => _username;
  String get password => _password;
  String get token => _token;
  bool get rememberPassword => _rememberPassword;
  String get loginStatus => _loginStatus;
  String get lastLoginTime => _lastLoginTime;
  bool get refreshAfterLogin => _refreshAfterLogin;
  
  // 加载登录设置
  Future<void> loadLoginSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 使用默认值作为备选
    _serverAddress = prefs.getString('serverAddress') ?? _defaults['serverAddress']!;
    _serverPort = prefs.getString('serverPort') ?? _defaults['serverPort']!;
    _username = prefs.getString('username') ?? _defaults['username']!;
    _password = prefs.getString('password') ?? _defaults['password']!;
    _token = prefs.getString('token') ?? '';
    _rememberPassword = prefs.getBool('rememberPassword') ?? true;
    _loginStatus = prefs.getString('loginStatus') ?? 'false';
    _lastLoginTime = prefs.getString('lastLoginTime') ?? '';
    
    // 如果不记住密码，则清除密码
    if (!_rememberPassword) {
      _password = '';
    }
    
    notifyListeners();
  }
  
  // 更新服务器地址
  Future<void> updateServerAddress(String value) async {
    _serverAddress = value;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新服务器端口
  Future<void> updateServerPort(String value) async {
    _serverPort = value;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新用户名
  Future<void> updateUsername(String value) async {
    _username = value;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新密码
  Future<void> updatePassword(String value) async {
    _password = value;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新令牌
  Future<void> updateToken(String value) async {
    _token = value;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新登录状态
  Future<void> updateLoginStatus(String status) async {
    _loginStatus = status;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新最后登录时间
  Future<void> updateLastLoginTime(String time) async {
    _lastLoginTime = time;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新记住密码设置
  Future<void> updateRememberPassword(bool remember) async {
    _rememberPassword = remember;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新登录后刷新标志
  void updateRefreshAfterLogin(bool refresh) {
    _refreshAfterLogin = refresh;
    notifyListeners();
  }
  
  // 保存所有登录相关设置
  Future<void> saveLoginInfo({
    required String username,
    required String password,
    required String token,
    bool rememberPassword = false,
    String loginStatus = 'true',
    String? lastLoginTime,
  }) async {
    _username = username;
    _password = password;
    _token = token;
    _rememberPassword = rememberPassword;
    _loginStatus = loginStatus;
    _lastLoginTime = lastLoginTime ?? DateTime.now().toIso8601String();
    
    await _saveSettings();
    notifyListeners();
  }
  
  // 清除登录信息
  Future<void> clearLoginInfo() async {
    _token = '';
    _loginStatus = 'false';
    
    if (!_rememberPassword) {
      _username = '';
      _password = '';
    }
    
    await _saveSettings();
    notifyListeners();
  }
  
  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('serverAddress', _serverAddress);
    await prefs.setString('serverPort', _serverPort);
    await prefs.setString('username', _username);
    await prefs.setString('loginStatus', _loginStatus);
    await prefs.setString('lastLoginTime', _lastLoginTime);
    await prefs.setString('token', _token);
    await prefs.setBool('rememberPassword', _rememberPassword);
    
    // 只有在启用记住密码功能时才保存密码
    if (_rememberPassword) {
      await prefs.setString('password', _password);
    } else {
      await prefs.setString('password', '');
    }
  }
} 