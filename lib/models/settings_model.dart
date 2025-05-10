import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SSH和终端设置模型
class SettingsModel extends ChangeNotifier {
  // SSH连接默认设置
  int _sshPort = 22;
  int _connectionTimeout = 10;
  bool _useKeyAuthentication = false;
  String _privateKeyPath = '';

  // 终端设置
  double _terminalFontSize = 14.0;
  String _terminalFontFamily = 'monospace';
  bool _enableTerminalTheme = true;
  String _terminalTheme = 'dark';

  // 安全设置
  bool _saveCredentials = false;
  bool _enableAutoConnect = false;

  // Getters
  int get sshPort => _sshPort;
  int get connectionTimeout => _connectionTimeout;
  bool get useKeyAuthentication => _useKeyAuthentication;
  String get privateKeyPath => _privateKeyPath;

  double get terminalFontSize => _terminalFontSize;
  String get terminalFontFamily => _terminalFontFamily;
  bool get enableTerminalTheme => _enableTerminalTheme;
  String get terminalTheme => _terminalTheme;

  bool get saveCredentials => _saveCredentials;
  bool get enableAutoConnect => _enableAutoConnect;

  // Setters
  void setSshPort(int port) {
    _sshPort = port;
    _saveSettings();
    notifyListeners();
  }

  void setConnectionTimeout(int timeout) {
    _connectionTimeout = timeout;
    _saveSettings();
    notifyListeners();
  }

  void setUseKeyAuthentication(bool useKey) {
    _useKeyAuthentication = useKey;
    _saveSettings();
    notifyListeners();
  }

  void setPrivateKeyPath(String path) {
    _privateKeyPath = path;
    _saveSettings();
    notifyListeners();
  }

  void setTerminalFontSize(double size) {
    _terminalFontSize = size;
    _saveSettings();
    notifyListeners();
  }

  void setTerminalFontFamily(String fontFamily) {
    _terminalFontFamily = fontFamily;
    _saveSettings();
    notifyListeners();
  }

  void setEnableTerminalTheme(bool enable) {
    _enableTerminalTheme = enable;
    _saveSettings();
    notifyListeners();
  }

  void setTerminalTheme(String theme) {
    _terminalTheme = theme;
    _saveSettings();
    notifyListeners();
  }

  void setSaveCredentials(bool save) {
    _saveCredentials = save;
    _saveSettings();
    notifyListeners();
  }

  void setEnableAutoConnect(bool autoConnect) {
    _enableAutoConnect = autoConnect;
    _saveSettings();
    notifyListeners();
  }

  // 加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _sshPort = prefs.getInt('sshPort') ?? 22;
    _connectionTimeout = prefs.getInt('connectionTimeout') ?? 10;
    _useKeyAuthentication = prefs.getBool('useKeyAuthentication') ?? false;
    _privateKeyPath = prefs.getString('privateKeyPath') ?? '';

    _terminalFontSize = prefs.getDouble('terminalFontSize') ?? 14.0;
    _terminalFontFamily = prefs.getString('terminalFontFamily') ?? 'monospace';
    _enableTerminalTheme = prefs.getBool('enableTerminalTheme') ?? true;
    _terminalTheme = prefs.getString('terminalTheme') ?? 'dark';

    _saveCredentials = prefs.getBool('saveCredentials') ?? false;
    _enableAutoConnect = prefs.getBool('enableAutoConnect') ?? false;

    notifyListeners();
  }

  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('sshPort', _sshPort);
    await prefs.setInt('connectionTimeout', _connectionTimeout);
    await prefs.setBool('useKeyAuthentication', _useKeyAuthentication);
    await prefs.setString('privateKeyPath', _privateKeyPath);

    await prefs.setDouble('terminalFontSize', _terminalFontSize);
    await prefs.setString('terminalFontFamily', _terminalFontFamily);
    await prefs.setBool('enableTerminalTheme', _enableTerminalTheme);
    await prefs.setString('terminalTheme', _terminalTheme);

    await prefs.setBool('saveCredentials', _saveCredentials);
    await prefs.setBool('enableAutoConnect', _enableAutoConnect);
  }

  // 重置为默认设置
  Future<void> resetToDefaults() async {
    _sshPort = 22;
    _connectionTimeout = 10;
    _useKeyAuthentication = false;
    _privateKeyPath = '';

    _terminalFontSize = 14.0;
    _terminalFontFamily = 'monospace';
    _enableTerminalTheme = true;
    _terminalTheme = 'dark';

    _saveCredentials = false;
    _enableAutoConnect = false;

    await _saveSettings();
    notifyListeners();
  }
} 