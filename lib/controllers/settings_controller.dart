// ignore_for_file: unused_import, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入模型和服务
import '../models/settings_model.dart';
import '../utils/logger.dart';
// TODO: 添加保存设置的服务或逻辑

/// 设置页面控制器
/// 负责管理设置项的状态和业务逻辑
class SettingsController extends ChangeNotifier {
  final SettingsModel _settingsModel;
  // TODO: 添加保存设置的服务或逻辑的引用
  final log = Logger();
  final String _logTag = 'SettingsController';

  /// 可用的终端字体列表 (示例)
  final List<String> _availableFontFamilies = [
    'monospace',
    'Courier New',
    'Consolas',
    'Cascadia Mono',
    'Arial',
    'Times New Roman',
  ];

  /// 构造函数
  SettingsController(this._settingsModel) {
    log.i(_logTag, '初始化 SettingsController');
    // TODO: 在此处加载设置
    // loadSettings(); // 加载设置，但目前 loadSettings 是占位符
  }

  // --- SSH 连接设置相关 Getter 和 Setter ---
  int get sshPort => _settingsModel.sshPort;
  int get connectionTimeout => _settingsModel.connectionTimeout;

  void setSshPort(int port) {
    _settingsModel.setSshPort(port);
    // TODO: 调用保存设置的方法
    // saveSettings();
    log.i(_logTag, 'SSH 端口已更新: $port');
  }

  void setConnectionTimeout(int timeout) {
    _settingsModel.setConnectionTimeout(timeout);
    // TODO: 调用保存设置的方法
    // saveSettings();
    log.i(_logTag, '连接超时已更新: $timeout');
  }

  // --- 终端设置相关 Getter 和 Setter ---
  double get terminalFontSize => _settingsModel.terminalFontSize;
  String get terminalFontFamily => _settingsModel.terminalFontFamily;

  void setTerminalFontSize(double size) {
    _settingsModel.setTerminalFontSize(size);
    // TODO: 调用保存设置的方法
    // saveSettings();
    log.i(_logTag, '终端字体大小已更新: $size');
  }

  void setTerminalFontFamily(String fontFamily) {
    _settingsModel.setTerminalFontFamily(fontFamily);
    // TODO: 调用保存设置的方法
    // saveSettings();
    log.i(_logTag, '终端字体已更新: $fontFamily');
  }

  /// 获取可用的终端字体列表
  List<String> get availableFontFamilies => _availableFontFamilies;

  // --- 关于和版本号相关 Getter (静态信息，直接提供) ---
  String get appVersion => '1.0.0'; // 示例版本号，TODO: 获取实际版本号
  String get aboutText => 'SSH 工具应用程序。提供 SSH 设备管理和终端交互功能。\n\n版本: $appVersion\n\n感谢您的使用！'; // 示例关于信息

  // --- 设置加载和保存方法 (TODO 实现) ---
  void loadSettings() {
    // TODO: 从持久化存储或服务加载设置
    log.i(_logTag, '加载设置 (TODO)');
    // 模拟加载
    // _settingsModel.setSshPort(22);
    // _settingsModel.setConnectionTimeout(15);
    // _settingsModel.setTerminalFontSize(14.0);
    // _settingsModel.setTerminalFontFamily('monospace');
  }

  void saveSettings() {
    // TODO: 保存设置到持久化存储或服务
    log.i(_logTag, '保存设置 (TODO)');
    log.i(_logTag, '保存设置: SSH 端口 ${_settingsModel.sshPort}, 连接超时 ${_settingsModel.connectionTimeout}, 字体大小 ${_settingsModel.terminalFontSize}, 字体 ${_settingsModel.terminalFontFamily}');
  }

  // TODO: 添加其他与设置 UI 交互的方法
} 