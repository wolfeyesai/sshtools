// ignore_for_file: unreachable_switch_default, duplicate_ignore, deprecated_member_use

// ignore_for_file: unreachable_switch_default

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ssh_footer_model.dart';
import '../models/ssh_model.dart';
import '../models/ssh_command_model.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_command_controller.dart';
import '../component/message_component.dart';
import '../component/ssh_multi_terminal.dart';

/// SSH页尾控制器，用于管理SSH页尾的业务逻辑
class SSHFooterController extends ChangeNotifier {
  /// 模型引用
  final SSHFooterModel _model;
  
  /// SSH控制器引用
  final SSHController _sshController;
  
  /// 连接状态订阅
  StreamSubscription<SSHConnectionState>? _connectionStateSubscription;
  
  /// 命令控制器
  SSHCommandController? _commandController;
  
  /// 命令发送回调
  final void Function(String)? _onCommandSent;
  
  /// 是否已销毁
  bool _isDisposed = false;

  /// 构造函数
  SSHFooterController({
    required SSHFooterModel model,
    required SSHController sshController,
    void Function(String)? onCommandSent,
  }) : _model = model,
       _sshController = sshController,
       _onCommandSent = onCommandSent {
    _init();
  }
  
  /// 初始化控制器
  void _init() {
    // 订阅SSH连接状态变化
    _connectionStateSubscription = _sshController.connectionStateStream.listen(_handleConnectionStateChange);
    
    // 延迟初始化命令控制器
    Future.microtask(() {
      if (_isDisposed) return;
      
      try {
        // 尝试获取全局活动控制器
        final activeController = SSHMultiTerminal.getCurrentController();
        if (activeController != null && activeController.isConnected && activeController != _sshController) {
          debugPrint('SSHFooterController: 使用全局活动控制器替代传入的控制器');
          // 更新控制器引用
          _connectionStateSubscription?.cancel();
          _connectionStateSubscription = activeController.connectionStateStream.listen(_handleConnectionStateChange);
        }
        
        // 如果已经在构造时设置了命令控制器，直接更新快捷命令
        if (_commandController != null) {
          _updateQuickCommands();
          debugPrint('SSHFooterController._init: 命令控制器已存在，已更新快捷命令');
        }
      } catch (e) {
        debugPrint('SSHFooterController._init: 初始化快捷命令时出错: $e');
      }
    });
  }
  
  /// 设置命令控制器
  void setCommandController(SSHCommandController controller) {
    _commandController = controller;
    _updateQuickCommands();
  }
  
  /// 更新快捷命令列表
  void _updateQuickCommands() {
    if (_commandController != null && !_isDisposed) {
      try {
        // 获取自定义命令
        final customCommands = _commandController!.getCommandsByType(SSHCommandType.custom);
        
        // 获取收藏命令
        final favoriteCommands = _commandController!.favoriteCommands;
        
        // 合并命令列表，确保自定义命令优先显示
        final List<SSHCommandModel> quickCommands = [];
        
        // 先添加自定义命令
        quickCommands.addAll(customCommands);
        
        // 再添加不在自定义命令中的收藏命令
        for (final cmd in favoriteCommands) {
          if (!customCommands.any((c) => c.id == cmd.id)) {
            quickCommands.add(cmd);
          }
        }
        
        // 更新快捷命令列表
        _model.quickCommands = quickCommands;
        
        debugPrint('SSHFooterController: 更新快捷命令列表，共${quickCommands.length}个命令 (自定义: ${customCommands.length}, 收藏: ${favoriteCommands.length})');
      } catch (e) {
        debugPrint('获取快捷命令失败: $e');
      }
    }
  }
  
  /// 处理连接状态变化
  void _handleConnectionStateChange(SSHConnectionState state) {
    if (_isDisposed) return;
    
    // 记录连接状态变化
    final bool isConnected = state == SSHConnectionState.connected;
    debugPrint('SSH连接状态变化: $state (isConnected: $isConnected)');
    
    // 更新模型中的连接状态 - 但不影响按钮的启用状态
    _model.isConnected = isConnected;
    
    // 始终保持按钮启用，不受连接状态影响
    _model.setCommandEnabled(true);
    _model.setMenuEnabled(true);
    _model.setHistoryEnabled(true);
  }
  
  /// 发送命令
  Future<bool> sendCommand(BuildContext context) async {
    if (_isDisposed) return false;
    
    try {
      final command = _model.commandText.trim();
      if (command.isEmpty) return false;
      
      // 尝试获取全局活动控制器
      SSHController actualController = _sshController;
      final activeController = SSHMultiTerminal.getCurrentController();
      if (activeController != null && activeController.isConnected) {
        debugPrint('SSHFooterController.sendCommand: 使用全局活动控制器发送命令');
        actualController = activeController;
      }
      
      // 检查SSH控制器是否连接
      if (!actualController.isConnected) {
        if (context.mounted) {
          MessageComponentFactory.showError(
            context,
            message: 'SSH未连接，无法发送命令',
          );
        }
        return false;
      }
      
      // 禁用发送按钮，防止重复发送
      _model.setCommandEnabled(false);
      
      // 发送命令到SSH会话
      actualController.sendToShellClient('$command\n');
      
      // 添加到命令历史（如果有命令控制器）
      if (_currentSession != null) {
        _currentSession!.addCommandToHistory(command);
      }
      
      // 清空命令文本
      _model.clearCommandText();
      
      // 添加到命令历史
      _model.addCommandToHistory(command);
      
      // 调用回调
      if (_onCommandSent != null) {
        _onCommandSent(command);
      }
      
      // 重新启用发送按钮
      _model.setCommandEnabled(true);
      
      return true;
    } catch (e) {
      // 确保按钮状态恢复
      _model.setCommandEnabled(true);
      
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '发送命令失败: $e',
        );
      }
      return false;
    }
  }

  /// 获取当前会话
  SSHSessionModel? get _currentSession => _sshController.currentSession;

  /// 获取命令历史
  List<String> getCommandHistory() {
    if (_isDisposed) return [];
    return _currentSession?.commandHistory ?? [];
  }
  
  /// 清除命令历史
  void clearCommandHistory() {
    if (_isDisposed) return;
    
    if (_currentSession != null) {
      _currentSession!.clearCommandHistory();
      // 同时更新本地模型
      _model.clearCommandHistory();
      notifyListeners();
    }
  }

  /// 处理命令菜单
  Future<void> showCommandMenu(BuildContext context) async {
    if (_isDisposed || !_model.isMenuEnabled) return;
    
    try {
      // 确保命令控制器已初始化
      if (_commandController == null) {
        if (context.mounted) {
          _commandController = Provider.of<SSHCommandController>(context, listen: false);
        } else {
          return;
        }
      }
      
      // 如果命令列表为空，尝试初始化
      if (_commandController!.commands.isEmpty) {
        await _commandController!.init();
        
        // 如果仍然没有命令，显示提示
        if (_commandController!.commands.isEmpty) {
          if (context.mounted) {
            MessageComponentFactory.showInfo(
              context,
              message: '没有可用的命令',
            );
          }
          return;
        }
      }
      
      // 刷新命令列表（确保获取最新的命令）
      if (context.mounted) {
        await _commandController!.loadCommands();
        debugPrint('SSHFooterController.showCommandMenu: 已刷新命令列表，共${_commandController!.commands.length}个命令');
      }
      
      // 显示命令选择对话框
      if (!context.mounted) return;
      
      // 调用命令管理组件显示命令选择对话框
      final selectedCommand = await _showCommandSelectionDialog(context);
      
      // 处理选中的命令
      if (selectedCommand != null && context.mounted) {
        _model.commandText = selectedCommand.command;
        await sendCommand(context);
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '显示命令菜单失败: $e',
        );
      }
    }
  }
  
  /// 显示命令选择对话框
  Future<SSHCommandModel?> _showCommandSelectionDialog(BuildContext context) async {
    if (_commandController == null) return null;
    
    try {
      return await showDialog<SSHCommandModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.code, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('选择命令'),
              const Spacer(),
              // 关闭按钮
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '关闭',
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _buildCommandList(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('显示命令选择对话框失败: $e');
      return null;
    }
  }
  
  /// 构建命令列表
  Widget _buildCommandList(BuildContext context) {
    if (_commandController == null) {
      return const Center(child: Text('命令控制器未初始化'));
    }
    
    // 按类型对命令进行分组
    final Map<SSHCommandType, List<SSHCommandModel>> commandsByType = {};
    
    // 收藏的命令
    final favoriteCommands = _commandController!.favoriteCommands;
    
    // 自定义命令（优先显示）
    final customCommands = _commandController!.getCommandsByType(SSHCommandType.custom);
    
    // 获取每种类型的命令
    for (final type in SSHCommandType.values) {
      try {
        if (type != SSHCommandType.custom) { // 自定义命令已单独获取
          final commands = _commandController!.getCommandsByType(type);
          if (commands.isNotEmpty) {
            commandsByType[type] = commands;
          }
        }
      } catch (e) {
        debugPrint('获取${_getCommandTypeName(type)}命令出错: $e');
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自定义命令部分（最优先显示）
          if (customCommands.isNotEmpty) ...[
            _buildCommandSection(
              context, 
              '自定义命令', 
              customCommands, 
              Icons.build, 
              Colors.purple
            ),
            const Divider(),
          ],
          
          // 收藏命令部分
          if (favoriteCommands.isNotEmpty) ...[
            _buildCommandSection(context, '收藏命令', favoriteCommands, Icons.star, Colors.amber),
            const Divider(),
          ],
          
          // 按类型显示其他命令
          for (final entry in commandsByType.entries) ...[
            if (entry.value.isNotEmpty && !(entry.key == SSHCommandType.general && favoriteCommands.isNotEmpty))
              _buildCommandSection(
                context,
                _getCommandTypeName(entry.key), 
                entry.value, 
                _getIconForCommandType(entry.key), 
                _getColorForCommandType(entry.key)
              ),
            if (entry.value.isNotEmpty && !(entry.key == SSHCommandType.general && favoriteCommands.isNotEmpty))
              const Divider(),
          ],
        ],
      ),
    );
  }
  
  /// 构建命令分类部分
  Widget _buildCommandSection(
    BuildContext context,
    String title,
    List<SSHCommandModel> commands,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: commands.length,
          itemBuilder: (context, index) {
            final command = commands[index];
            return ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Icon(
                  _getIconForCommandType(command.type), 
                  color: _getColorForCommandType(command.type).withOpacity(0.7),
                  size: 20,
                ),
              ),
              title: Text(
                command.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                command.command,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).pop(command);
              },
              trailing: IconButton(
                icon: Icon(
                  command.isFavorite ? Icons.star : Icons.star_border,
                  color: command.isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  _toggleFavoriteCommand(command);
                },
                tooltip: command.isFavorite ? '取消收藏' : '收藏命令',
              ),
            );
          },
        ),
      ],
    );
  }
  
  /// 切换命令的收藏状态
  void _toggleFavoriteCommand(SSHCommandModel command) {
    if (_commandController != null && !_isDisposed) {
      _commandController!.toggleFavorite(command.id);
      _updateQuickCommands();
      notifyListeners();
    }
  }
  
  /// 处理快捷命令点击
  Future<void> handleQuickCommand(BuildContext context, SSHCommandModel command) async {
    if (_isDisposed || !_model.isCommandEnabled) return;
    
    try {
      // 更新命令文本框内容
      _model.commandText = command.command;
      
      // 发送命令
      await sendCommand(context);
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '执行快捷命令失败: $e',
        );
      }
    }
  }
  
  /// 获取命令类型名称
  String _getCommandTypeName(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.system:
        return '系统命令';
      case SSHCommandType.network:
        return '网络命令';
      case SSHCommandType.file:
        return '文件命令';
      case SSHCommandType.custom:
        return '自定义命令';
      case SSHCommandType.general:
      default:
        return '常用命令';
    }
  }
  
  /// 获取命令类型图标
  IconData _getIconForCommandType(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.system:
        return Icons.computer;
      case SSHCommandType.network:
        return Icons.wifi;
      case SSHCommandType.file:
        return Icons.folder;
      case SSHCommandType.custom:
        return Icons.build;
      case SSHCommandType.general:
      default:
        return Icons.terminal;
    }
  }
  
  /// 获取命令类型颜色
  Color _getColorForCommandType(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.system:
        return Colors.blue;
      case SSHCommandType.network:
        return Colors.green;
      case SSHCommandType.file:
        return Colors.orange;
      case SSHCommandType.custom:
        return Colors.teal;
      case SSHCommandType.general:
      default:
        return Colors.blueGrey;
    }
  }
  
  /// 显示命令历史对话框
  Future<void> showCommandHistory(BuildContext context) async {
    if (_isDisposed || !_model.isHistoryEnabled) return;
    
    try {
      final history = getCommandHistory();
      
      if (history.isEmpty) {
        if (context.mounted) {
          MessageComponentFactory.showInfo(
            context,
            message: '没有命令历史记录',
          );
        }
        return;
      }
      
      final selectedCommand = await _showHistoryDialog(context, history);
      if (selectedCommand != null && context.mounted) {
        _model.commandText = selectedCommand;
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '显示命令历史出错: $e',
        );
      }
    }
  }
  
  /// 显示命令历史对话框
  Future<String?> _showHistoryDialog(BuildContext context, List<String> history) async {
    // 反转历史记录，最新的命令显示在前面
    final reversedHistory = history.reversed.toList();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('命令历史'),
            const Spacer(),
            // 清除按钮
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清除历史',
              onPressed: () {
                // 确认清除
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清除'),
                    content: const Text('确定要清除所有命令历史记录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          clearCommandHistory();
                          // 关闭两个对话框
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          if (context.mounted) {
                            MessageComponentFactory.showInfo(
                              context,
                              message: '命令历史已清除',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                );
              },
            ),
            // 关闭按钮
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: reversedHistory.length,
            itemBuilder: (context, index) {
              final command = reversedHistory[index];
              return ListTile(
                leading: const Icon(Icons.terminal),
                title: Text(command),
                onTap: () {
                  Navigator.of(context).pop(command);
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  /// 更新命令文本
  void updateCommandText(String text) {
    if (_isDisposed) return;
    _model.commandText = text;
  }
  
  /// 切换快捷命令显示
  void toggleQuickCommands() {
    if (_isDisposed) return;
    _model.showQuickCommands = !_model.showQuickCommands;
    notifyListeners();
  }
  
  /// 从模型获取必要的数据
  String get commandText => _model.commandText;
  List<SSHCommandModel> get quickCommands => _model.quickCommands;
  bool get isQuickCommandsVisible => _model.showQuickCommands;
  
  @override
  void dispose() {
    _isDisposed = true;
    
    if (_connectionStateSubscription != null) {
      _connectionStateSubscription!.cancel();
      _connectionStateSubscription = null;
    }
    
    super.dispose();
  }
} 