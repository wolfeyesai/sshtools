// ignore_for_file: unused_import, duplicate_ignore, unused_field, use_super_parameters, deprecated_member_use, unnecessary_null_comparison

import 'dart:async';
// ignore: unused_import
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../models/ip_model.dart';
import '../models/ssh_model.dart';
import '../models/ssh_saved_session_model.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../component/message_component.dart';
import '../component/Button_component.dart';
import '../component/remote_directory_browser.dart';
import '../component/ssh_file_uploader.dart';
import '../component/ssh_file_downloader.dart';
import '../component/ssh_session_edit_dialog.dart';
import '../component/ssh_multi_terminal.dart';
import '../models/ssh_command_model.dart';
import '../controllers/ssh_command_controller.dart';
import '../views/ssh_command_manager_screen.dart';

/// SSH终端页面
class SSHTerminalPage extends StatefulWidget {
  /// 页面标题
  static const String pageTitle = 'SSH终端';
  
  /// 路由名称
  static const String routeName = '/ssh-terminal';
  
  /// 目标设备
  final IPDeviceModel device;
  
  /// SSH凭据
  final String username;
  final String password;
  final int port;
  
  /// 构造函数
  const SSHTerminalPage({
    Key? key,
    required this.device,
    required this.username,
    required this.password,
    this.port = 22,
  }) : super(key: key);

  @override
  State<SSHTerminalPage> createState() => _SSHTerminalPageState();
}

class _SSHTerminalPageState extends State<SSHTerminalPage> {
  /// SSH控制器
  late final SSHController _sshController;
  
  /// 终端输入控制器
  final TextEditingController _commandController = TextEditingController();
  
  /// 连接状态
  String _connectionStatus = '准备连接...';
  
  /// 是否已连接
  bool _connected = false;
  
  /// 终端输出订阅
  StreamSubscription<String>? _outputSubscription;
  
  /// 连接状态订阅
  StreamSubscription<SSHConnectionState>? _connectionStateSubscription;
  
  /// 显示错误消息
  void _showError(String message) {
    if (mounted) {
      MessageComponentFactory.showError(
        context,
        message: message,
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // 获取Provider中的SSH控制器
    _sshController = Provider.of<SSHController>(context, listen: false);
    
    // 订阅连接状态变化
    _connectionStateSubscription = _sshController.connectionStateStream.listen((state) {
      // 使用额外的安全检查，确保只在组件仍然挂载且未被标记为销毁时更新状态
      if (mounted && _connectionStateSubscription != null) {
        // 使用try-catch包装setState调用
        try {
          setState(() {
            _connected = state == SSHConnectionState.connected;
            _connectionStatus = _getStatusFromState(state);
          });
        } catch (e) {
          debugPrint('更新连接状态时出错: $e');
          // 发生错误时，可能是组件已经处于释放过程中，取消订阅
          _connectionStateSubscription?.cancel();
          _connectionStateSubscription = null;
        }
      }
    });
  }
  
  /// 获取状态描述
  String _getStatusFromState(SSHConnectionState state) {
    switch (state) {
      case SSHConnectionState.connecting:
        return '正在连接...';
      case SSHConnectionState.connected:
        return '已连接';
      case SSHConnectionState.disconnected:
        return '已断开连接';
      case SSHConnectionState.failed:
        return '连接失败';
    }
  }
  
  @override
  void dispose() {
    // 直接设置变量为null，防止后续更新
    _connected = false;
    
    // 保存引用，然后设置为null
    final outputSub = _outputSubscription;
    final connStateSub = _connectionStateSubscription;
    final cmdController = _commandController;
    
    _outputSubscription = null;
    _connectionStateSubscription = null;
    
    // 先调用父类的dispose确保组件正确销毁
    super.dispose();
    
    // 然后在下一帧开始异步释放资源
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // 取消订阅
        if (outputSub != null) {
          outputSub.cancel();
        }
      } catch (e) {
        debugPrint('取消输出订阅出错: $e');
      }
      
      try {
        // 取消连接状态订阅
        if (connStateSub != null) {
          connStateSub.cancel();
        }
      } catch (e) {
        debugPrint('取消连接状态订阅出错: $e');
      }
      
      try {
        // 释放控制器
        if (cmdController != null) {
          cmdController.dispose();
        }
      } catch (e) {
        debugPrint('释放命令控制器出错: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用try-catch包装整个build方法
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(SSHTerminalPage.pageTitle),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // 命令管理按钮
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: '命令管理',
              onPressed: _openCommandManager,
            ),
            
            // 上传文件按钮
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: '上传文件',
              onPressed: _handleFileUpload,
            ),
            
            // 下载文件按钮
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: '下载文件',
              onPressed: _handleFileDownload,
            ),
            
            // 保存会话按钮
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存会话',
              onPressed: _saveCurrentSession,
            ),
          ],
        ),
        body: Column(
          children: [
            // 多终端管理组件
            Expanded(
              child: SSHMultiTerminal(
                initialDevice: widget.device,
                initialUsername: widget.username,
                initialPassword: widget.password,
                initialPort: widget.port,
              ),
            ),
            
            // 命令输入区域
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 快捷命令区域
                  _buildQuickCommands(),
                  
                  // 命令输入行
                  Row(
                    children: [
                      Expanded(
                        child: GFTextField(
                          controller: _commandController,
                          decoration: InputDecoration(
                            hintText: '输入命令',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            // 添加命令历史按钮
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(4),
                              child: GFIconButton(
                                icon: Icon(
                                  Icons.history,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                type: GFButtonType.solid,
                                onPressed: _showCommandHistory,
                                shape: GFIconButtonShape.circle,
                                size: GFSize.SMALL,
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ),
                            ),
                            fillColor: Theme.of(context).colorScheme.surface,
                            filled: true,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onFieldSubmitted: (_) => _sendCommand(),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 命令菜单按钮
                      GFButton(
                        onPressed: _showCommandMenu,
                        icon: Icon(
                          Icons.menu,
                          size: 20,
                          color: Colors.white,
                        ),
                        text: '',
                        type: GFButtonType.solid,
                        shape: GFButtonShape.pills,
                        size: GFSize.SMALL,
                        color: Colors.indigo,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        boxShadow: BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 发送按钮
                      GFButton(
                        onPressed: _sendCommand,
                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        text: '发送',
                        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        type: GFButtonType.solid,
                        shape: GFButtonShape.pills,
                        size: GFSize.SMALL,
                        color: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        blockButton: false,
                        boxShadow: BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // 如果构建过程中出错，返回简单的错误页面
      debugPrint('SSH终端页面构建错误: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('SSH终端'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                '页面加载出错',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('请尝试重新连接或重启应用'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  /// 发送命令到终端
  void _sendCommand() {
    if (!mounted) {
      _showError('无法发送命令');
      return;
    }
    
    final command = _commandController.text.trim();
    if (command.isNotEmpty) {
      try {
        _sshController.sendToShell('$command\n');
        _commandController.clear();
      } catch (e) {
        _showError('发送命令失败: $e');
      }
    }
  }
  
  /// 处理文件上传
  void _handleFileUpload() {
    if (!mounted) {
      _showError('未连接到SSH服务器');
      return;
    }
    
    // 使用SSHFileUploader进行文件上传操作
    SSHFileUploader.uploadFile(
      context: context,
      sshController: _sshController,
      onSuccess: (remoteFilePath) {
        // 上传成功后，在终端中显示文件信息
        if (_connected) {
          _sshController.sendToShell('ls -la $remoteFilePath\n');
        }
      },
    );
  }
  
  /// 处理文件下载
  void _handleFileDownload() {
    if (!mounted) {
      _showError('未连接到SSH服务器');
      return;
    }
    
    // 使用SSHFileDownloader进行文件下载操作
    SSHFileDownloader.downloadFile(
      context: context,
      sshController: _sshController,
      onSuccess: (remoteFilePath, localFilePath) {
        // 下载成功后，在终端中显示消息
        if (_connected) {
          _sshController.sendToShell('echo "已下载文件: $remoteFilePath 到本地: $localFilePath"\n');
        }
      },
    );
  }
  
  /// 打开命令管理器
  Future<void> _openCommandManager() async {
    if (!mounted) {
      _showError('请先连接到SSH服务器');
      return;
    }
    
    // 跳转到命令管理页面
    if (!mounted) return;
    final selectedCommand = await Navigator.of(context).push<SSHCommandModel>(
      MaterialPageRoute(
        builder: (context) => const SSHCommandManagerPage(),
      ),
    );
    
    // 如果选择了命令，则执行
    if (selectedCommand != null && mounted) {
      _commandController.text = selectedCommand.command;
      _sendCommand();
    }
  }
  
  /// 构建快捷命令区域
  Widget _buildQuickCommands() {
    // 不使用Consumer，改为直接调用Provider.of
    // 这样可以避免在Widget树重建时Provider触发不必要的更新
    if (!mounted) return Container();
    
    try {
      final commandController = Provider.of<SSHCommandController>(context, listen: false);
      final favoriteCommands = commandController.favoriteCommands;
      
      if (favoriteCommands.isEmpty) {
        return Container(); // 如果没有收藏命令则不显示
      }
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快捷命令标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '快捷命令',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // 快捷命令列表
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favoriteCommands.map((cmd) {
                return GFButton(
                  onPressed: () {
                    if (mounted) {
                      _commandController.text = cmd.command;
                    } 
                  },
                  text: cmd.name,
                  textStyle: const TextStyle(fontSize: 12),
                  size: GFSize.SMALL,
                  type: GFButtonType.outline2x,
                  shape: GFButtonShape.pills,
                  color: _getCommandTypeColor(cmd.type),
                  icon: Icon(
                    _getCommandTypeIcon(cmd.type),
                    size: 14, 
                    color: _getCommandTypeColor(cmd.type),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  boxShadow: const BoxShadow(
                    color: Colors.transparent,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('构建快捷命令区域出错: $e');
      return Container();
    }
  }
  
  /// 获取命令类型图标
  IconData _getCommandTypeIcon(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.general:
        return Icons.terminal;
      case SSHCommandType.system:
        return Icons.computer;
      case SSHCommandType.network:
        return Icons.wifi;
      case SSHCommandType.file:
        return Icons.folder;
      case SSHCommandType.custom:
        return Icons.build;
    }
  }
  
  /// 获取命令类型颜色
  Color _getCommandTypeColor(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.general:
        return Colors.blue;
      case SSHCommandType.system:
        return Colors.green;
      case SSHCommandType.network:
        return Colors.orange;
      case SSHCommandType.file:
        return Colors.amber;
      case SSHCommandType.custom:
        return Colors.purple;
    }
  }
  
  /// 显示命令菜单
  Future<void> _showCommandMenu() async {
    if (!mounted) {
      return;
    }
    
    // 获取命令控制器
    final commandController = Provider.of<SSHCommandController>(context, listen: false);
    
    // 如果没有命令，打开命令管理页面
    if (commandController.commands.isEmpty) {
      // 初始化命令控制器，加载预设命令
      await commandController.init();
      
      // 如果仍然没有命令，直接打开命令管理页面
      if (commandController.commands.isEmpty) {
        _openCommandManager();
        return;
      }
    }
    
    // 显示命令选择对话框
    if (!mounted) return;
    final selectedCommand = await showDialog<SSHCommandModel>(
      context: context,
      builder: (context) => _buildCommandSelectionDialog(commandController),
    );
    
    // 执行所选命令
    if (selectedCommand != null && mounted) {
      _commandController.text = selectedCommand.command;
      // 自动发送选中的命令
      _sendCommand();
    }
  }
  
  /// 构建命令分组部分
  Widget _buildCommandSection(String title, List<SSHCommandModel> commands, IconData icon, Color color) {
    if (commands.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commands.map((command) => GFButton(
            onPressed: () => Navigator.of(context).pop(command),
            text: command.name,
            textStyle: const TextStyle(fontSize: 12, color: Colors.white),
            size: GFSize.SMALL,
            type: GFButtonType.solid,
            color: Colors.indigo,
            icon: Icon(
              _getCommandTypeIcon(command.type),
              size: 14, 
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            boxShadow: BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          )).toList(),
        ),
      ],
    );
  }
  
  /// 构建命令选择对话框
  Widget _buildCommandSelectionDialog(SSHCommandController commandController) {
    try {
      // 按类型对命令进行分组
      final Map<SSHCommandType, List<SSHCommandModel>> commandsByType = {};
      
      // 收藏的命令始终显示在前面
      final favoriteCommands = commandController.favoriteCommands;
      
      // 获取每种类型的命令
      for (final type in SSHCommandType.values) {
        try {
          final commands = commandController.getCommandsByType(type);
          if (commands.isNotEmpty) {
            commandsByType[type] = commands;
          }
        } catch (e) {
          debugPrint('获取${_getCommandTypeName(type)}命令出错: $e');
        }
      }
      
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.code, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('选择命令'),
            const Spacer(),
            // 管理按钮
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('管理'),
              onPressed: () {
                Navigator.of(context).pop();
                _openCommandManager();
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 收藏命令部分
                if (favoriteCommands.isNotEmpty) ...[
                  _buildCommandSection('收藏命令', favoriteCommands, Icons.star, Colors.amber),
                  const Divider(),
                ],
                
                // 按类型显示其他命令
                for (final entry in commandsByType.entries) ...[
                  if (entry.value.isNotEmpty && !(entry.key == SSHCommandType.general && favoriteCommands.isNotEmpty))
                    _buildCommandSection(
                      _getCommandTypeName(entry.key), 
                      entry.value, 
                      _getCommandTypeIcon(entry.key),
                      _getCommandTypeColor(entry.key),
                    ),
                  if (entry.value.isNotEmpty)
                    const Divider(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      );
    } catch (e) {
      debugPrint('构建命令选择对话框出错: $e');
      return AlertDialog(
        title: const Text('命令选择'),
        content: const Text('加载命令时出错，请稍后重试。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      );
    }
  }
  
  /// 获取命令类型名称
  String _getCommandTypeName(SSHCommandType type) {
    switch (type) {
      case SSHCommandType.general:
        return '通用命令';
      case SSHCommandType.system:
        return '系统命令';
      case SSHCommandType.network:
        return '网络命令';
      case SSHCommandType.file:
        return '文件操作';
      case SSHCommandType.custom:
        return '自定义命令';
    }
  }
  
  /// 显示命令历史
  Future<void> _showCommandHistory() async {
    if (!mounted) {
      return;
    }
    
    final commandHistory = _sshController.getCommandHistory();
    
    if (commandHistory.isEmpty) {
      if (mounted) {
        MessageComponentFactory.showInfo(
          context,
          message: '暂无命令历史记录',
        );
      }
      return;
    }
    
    // 显示命令历史选择对话框
    if (!mounted) return;
    final selectedCommand = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('命令历史'),
            const Spacer(),
            // 清空历史按钮
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '清空历史',
              onPressed: () {
                _sshController.clearCommandHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: commandHistory.length,
            reverse: true, // 最新的命令显示在顶部
            itemBuilder: (context, index) {
              final command = commandHistory[commandHistory.length - 1 - index];
              return ListTile(
                title: Text(
                  command,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
                leading: const Icon(Icons.terminal),
                onTap: () => Navigator.of(context).pop(command),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    // 执行所选命令
    if (selectedCommand != null && mounted) {
      _commandController.text = selectedCommand;
      // 自动发送选中的历史命令
      _sendCommand();
    }
  }
  
  /// 保存当前会话
  Future<void> _saveCurrentSession() async {
    try {
      // 创建会话信息
      final sessionName = '${widget.device.displayName} 会话';
      
      // 显示会话编辑对话框让用户确认或修改会话信息
      final session = await SSHSessionEditDialog.show(
        context: context,
        session: SSHSavedSessionModel(
          name: sessionName,
          host: widget.device.ipAddress,
          port: widget.port,
          username: widget.username,
          password: widget.password,
        ),
      );
      
      if (session != null && mounted) {
        // 保存会话信息
        final sessionController = Provider.of<SSHSessionController>(context, listen: false);
        await sessionController.addSession(session);
        
        if (mounted) {
          MessageComponentFactory.showSuccess(
            context,
            message: '会话 "${session.name}" 已保存',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('保存会话失败: $e');
      }
    }
  }
} 