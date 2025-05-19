import 'package:flutter/foundation.dart';

/// SSH页头模型，管理SSH终端页面的页头状态
class SSHHeaderModel extends ChangeNotifier {
  /// 页面标题
  String _title = '';
  
  /// 按钮启用状态
  bool _isFileUploadEnabled = true;
  bool _isFileDownloadEnabled = true;
  
  /// 连接状态
  bool _isConnected = false;
  
  /// 是否显示额外的调试信息
  bool _showDebugInfo = false;
  
  /// 构造函数
  SSHHeaderModel({
    String title = 'SSH终端',
    bool isConnected = false,
  }) {
    _title = title;
    _isConnected = isConnected;
  }

  /// 获取页面标题
  String get title => _title;
  
  /// 设置页面标题
  set title(String value) {
    if (_title != value) {
      _title = value;
      notifyListeners();
    }
  }
  
  /// 获取连接状态
  bool get isConnected => _isConnected;
  
  /// 设置连接状态
  set isConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      notifyListeners();
    }
  }
  
  /// 文件上传按钮是否启用
  bool get isFileUploadEnabled => _isFileUploadEnabled && _isConnected;
  
  /// 文件下载按钮是否启用
  bool get isFileDownloadEnabled => _isFileDownloadEnabled && _isConnected;
  
  /// 获取是否显示调试信息
  bool get showDebugInfo => _showDebugInfo;
  
  /// 设置是否显示调试信息
  set showDebugInfo(bool value) {
    if (_showDebugInfo != value) {
      _showDebugInfo = value;
      notifyListeners();
    }
  }
  
  /// 设置文件上传按钮启用状态
  void setFileUploadEnabled(bool enabled) {
    if (_isFileUploadEnabled != enabled) {
      _isFileUploadEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// 设置文件下载按钮启用状态
  void setFileDownloadEnabled(bool enabled) {
    if (_isFileDownloadEnabled != enabled) {
      _isFileDownloadEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// 重置所有状态
  void reset() {
    _title = 'SSH终端';
    _isConnected = false;
    _isFileUploadEnabled = true;
    _isFileDownloadEnabled = true;
    _showDebugInfo = false;
    notifyListeners();
  }
} 