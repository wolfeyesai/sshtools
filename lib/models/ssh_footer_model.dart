import 'package:flutter/foundation.dart';
import '../models/ssh_command_model.dart';

/// SSH页尾模型，管理SSH终端页面的页尾状态
class SSHFooterModel extends ChangeNotifier {
  /// 命令输入文本
  String _commandText = '';
  
  /// 按钮启用状态
  bool _isCommandEnabled = true;
  bool _isMenuEnabled = true;
  bool _isHistoryEnabled = true;
  
  /// 是否显示快捷命令区域
  bool _showQuickCommands = true;
  
  /// 连接状态
  bool _isConnected = false;
  
  /// 命令历史
  final List<String> _commandHistory = [];
  
  /// 最大历史记录数
  int _maxHistoryCount = 50;
  
  /// 快捷命令
  List<SSHCommandModel> _quickCommands = [];
  
  /// 构造函数
  SSHFooterModel({
    bool isConnected = false,
    bool showQuickCommands = true,
    int maxHistoryCount = 50,
  }) {
    _isConnected = isConnected;
    _showQuickCommands = showQuickCommands;
    _maxHistoryCount = maxHistoryCount;
  }

  /// 获取命令文本
  String get commandText => _commandText;
  
  /// 设置命令文本
  set commandText(String value) {
    if (_commandText != value) {
      _commandText = value;
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
  
  /// 命令按钮是否启用
  bool get isCommandEnabled => _isCommandEnabled && _isConnected;
  
  /// 菜单按钮是否启用
  bool get isMenuEnabled => _isMenuEnabled && _isConnected;
  
  /// 历史按钮是否启用
  bool get isHistoryEnabled => _isHistoryEnabled && _isConnected;
  
  /// 是否显示快捷命令
  bool get showQuickCommands => _showQuickCommands;
  
  /// 设置是否显示快捷命令
  set showQuickCommands(bool value) {
    if (_showQuickCommands != value) {
      _showQuickCommands = value;
      notifyListeners();
    }
  }
  
  /// 获取快捷命令
  List<SSHCommandModel> get quickCommands => _quickCommands;
  
  /// 设置快捷命令
  set quickCommands(List<SSHCommandModel> value) {
    _quickCommands = List.from(value);
    notifyListeners();
  }
  
  /// 获取命令历史
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  
  /// 添加命令到历史
  void addCommandToHistory(String command) {
    // 如果命令已存在于历史记录中，先移除它
    _commandHistory.remove(command);
    
    // 添加到历史记录开头
    _commandHistory.insert(0, command);
    
    // 如果历史记录超出最大数量，删除最旧的记录
    if (_commandHistory.length > _maxHistoryCount) {
      _commandHistory.removeLast();
    }
    
    notifyListeners();
  }
  
  /// 清空命令历史
  void clearCommandHistory() {
    if (_commandHistory.isNotEmpty) {
      _commandHistory.clear();
      notifyListeners();
    }
  }
  
  /// 设置发送命令按钮启用状态
  void setCommandEnabled(bool enabled) {
    if (_isCommandEnabled != enabled) {
      _isCommandEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// 设置命令菜单按钮启用状态
  void setMenuEnabled(bool enabled) {
    if (_isMenuEnabled != enabled) {
      _isMenuEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// 设置历史按钮启用状态
  void setHistoryEnabled(bool enabled) {
    if (_isHistoryEnabled != enabled) {
      _isHistoryEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// 检查命令是否为空
  bool isCommandEmpty() {
    return _commandText.trim().isEmpty;
  }
  
  /// 清空命令文本
  void clearCommandText() {
    if (_commandText.isNotEmpty) {
      _commandText = '';
      notifyListeners();
    }
  }
  
  /// 重置所有状态
  void reset() {
    _commandText = '';
    _isConnected = false;
    _isCommandEnabled = true;
    _isMenuEnabled = true;
    _isHistoryEnabled = true;
    _showQuickCommands = true;
    notifyListeners();
  }
} 