// ignore_for_file: unused_element, use_super_parameters, deprecated_member_use, unused_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/xterm.dart';
import 'dart:math' as math;

import '../models/ip_model.dart';
import '../models/ssh_model.dart';
import '../models/ssh_saved_session_model.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import 'ssh_session_edit_dialog.dart';
import 'ssh_session_tab_manager.dart';
import 'message_component.dart';
import '../main.dart'; // 导入以访问导航观察器
import '../providers/sidebar_provider.dart' hide EmptyTerminalWidget; // 隐藏同名类
import 'empty_terminal_widget.dart';

/// SSH多终端管理组件
class SSHMultiTerminal extends StatefulWidget {
  /// 初始会话设备
  final IPDeviceModel initialDevice;
  
  /// 初始会话凭据
  final String initialUsername;
  final String initialPassword;
  final int initialPort;
  
  /// 构造函数
  const SSHMultiTerminal({
    Key? key,
    required this.initialDevice,
    required this.initialUsername,
    required this.initialPassword,
    this.initialPort = 22,
  }) : super(key: key);

  @override
  State<SSHMultiTerminal> createState() => _SSHMultiTerminalState();
}

class _SSHMultiTerminalState extends State<SSHMultiTerminal> {
  /// 活动会话索引
  int _activeSessionIndex = 0;
  
  /// 会话列表
  final List<_SSHTerminalSession> _sessions = [];
  
  @override
  void initState() {
    super.initState();
    
    // 添加初始会话
    _addInitialSession();
  }
  
  /// 添加初始会话
  void _addInitialSession() {
    // 创建初始会话标签
    final initialTab = SSHSessionTab(
      displayName: '${widget.initialDevice.ipAddress} - ${widget.initialUsername}',
      device: widget.initialDevice,
      username: widget.initialUsername,
      password: widget.initialPassword,
      port: widget.initialPort,
      controller: Provider.of<SSHController>(context, listen: false),
    );
    
    // 创建会话终端
    final terminal = Terminal(maxLines: 10000);
    
    // 添加到会话列表
    _sessions.add(_SSHTerminalSession(
      tab: initialTab,
      terminal: terminal,
    ));
    
    // 连接到服务器
    _connectSession(0);
  }
  
  /// 添加新会话
  void _addNewSession() {
    if (_sessions.isEmpty || _activeSessionIndex < 0 || _activeSessionIndex >= _sessions.length) {
      return;
    }
    
    // 获取当前活动会话
    final currentSession = _sessions[_activeSessionIndex];
    
    // 复制当前会话配置
    final newSessionIndex = _sessions.length;
    final randomId = math.Random().nextInt(1000);
    
    // 创建新的会话控制器实例
    final newController = SSHController();
    
    // 创建新会话标签
    final newTab = currentSession.tab.copy(
      displayName: '${currentSession.tab.displayName} #$randomId',
      controller: newController,
    );
    
    // 创建新终端
    final terminal = Terminal(maxLines: 10000);
    
    // 添加到会话列表
    setState(() {
      _sessions.add(_SSHTerminalSession(
        tab: newTab,
        terminal: terminal,
      ));
      _activeSessionIndex = newSessionIndex;
    });
    
    // 连接新会话
    _connectSession(newSessionIndex);
  }
  
  /// 切换会话
  void _switchSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      setState(() {
        _activeSessionIndex = index;
      });
    }
  }
  
  /// 关闭会话
  void _closeSession(int index) {
    if (index < 0 || index >= _sessions.length) {
      return; // 只检查索引范围是否有效
    }
    
    // 检查是否关闭最后一个会话
    final isLastSession = (_sessions.length == 1);
    
    // 如果是最后一个会话，切换到空终端页面而不是pop
    if (isLastSession) {
      if (mounted) {
        // 先保存会话引用
        final sessionToClose = _sessions[index];
        
        try {
          // 获取SidebarProvider
          final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
          
          // 更新为空终端页面
          sidebarProvider.updateTerminalPage(const EmptyTerminalWidget());
          
          // 更新界面状态，清空会话列表
          setState(() {
            _sessions.clear();
            _activeSessionIndex = -1; // 设置无效索引
          });
          
          // 延迟释放资源
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              if (sessionToClose.terminalSubscription != null) {
                sessionToClose.terminalSubscription!.cancel();
                sessionToClose.terminalSubscription = null;
              }
              
              if (sessionToClose.connectionStateSubscription != null) {
                sessionToClose.connectionStateSubscription!.cancel();
                sessionToClose.connectionStateSubscription = null;
              }
              
              sessionToClose.tab.controller.disconnect();
            } catch (e) {
              debugPrint('关闭最后一个SSH会话资源时出错: $e');
            }
          });
        } catch (e) {
          debugPrint('切换到空终端页面出错: $e');
          
          // 出错时尝试直接返回
          if (navigatorObserver.canNavigate() && mounted) {
            Navigator.of(context).pop();
          }
        }
      }
      return;
    }
    
    // 不是最后一个会话，正常处理
    final session = _sessions[index];
    
    // 先更新状态
    setState(() {
      // 移除会话
      _sessions.removeAt(index);
      
      // 调整当前活动会话索引
      if (_activeSessionIndex >= _sessions.length) {
        _activeSessionIndex = _sessions.length - 1;
      } else if (_activeSessionIndex > index) {
        _activeSessionIndex--;
      }
    });
    
    // 延迟释放资源
    Future.microtask(() {
      try {
        session.terminalSubscription?.cancel();
        session.connectionStateSubscription?.cancel();
        session.tab.controller.disconnect();
      } catch (e) {
        debugPrint('关闭SSH会话出错: $e');
      }
    });
  }
  
  /// 连接会话
  Future<void> _connectSession(int sessionIndex) async {
    if (sessionIndex < 0 || sessionIndex >= _sessions.length) return;
    
    final session = _sessions[sessionIndex];
    final tab = session.tab;
    
    setState(() {
      tab.connectionStatus = '正在连接到 ${tab.device.ipAddress}:${tab.port}...';
    });
    
    try {
      final success = await tab.controller.connect(
        host: tab.device.ipAddress,
        username: tab.username,
        password: tab.password,
        port: tab.port,
      );
      
      if (success) {
        // 启动Shell会话
        final shellSession = await tab.controller.startShell();
        
        if (shellSession != null) {
          // 订阅会话输出
          session.terminalSubscription = shellSession.stdout.listen((data) {
            session.terminal.write(utf8.decode(data, allowMalformed: true));
          });
          
          // 将终端的输入发送到SSH会话
          session.terminal.onOutput = (data) {
            tab.controller.sendToShell(data);
          };
          
          setState(() {
            tab.isConnected = true;
            tab.connectionStatus = '已连接到 ${tab.device.ipAddress}';
          });
          
          // 发送初始命令
          await Future.delayed(const Duration(milliseconds: 500));
          tab.controller.sendToShell('ls -la\n');
        } else {
          setState(() {
            tab.connectionStatus = '无法创建Shell会话';
          });
          _showError('无法创建Shell会话');
        }
      } else {
        setState(() {
          tab.connectionStatus = '连接失败';
        });
        _showError('连接到SSH服务器失败');
      }
    } catch (e) {
      setState(() {
        tab.connectionStatus = '连接出错: $e';
      });
      _showError('连接出错: $e');
    }
    
    // 订阅连接状态
    session.connectionStateSubscription = tab.controller.connectionStateStream.listen((state) {
      if (!mounted) return;
      
      switch (state) {
        case SSHConnectionState.connecting:
          setState(() {
            tab.connectionStatus = '正在连接...';
          });
          break;
        case SSHConnectionState.connected:
          setState(() {
            tab.connectionStatus = '已连接';
            tab.isConnected = true;
          });
          break;
        case SSHConnectionState.disconnected:
          setState(() {
            tab.connectionStatus = '已断开连接';
            tab.isConnected = false;
          });
          break;
        case SSHConnectionState.failed:
          setState(() {
            tab.connectionStatus = '连接失败';
            tab.isConnected = false;
          });
          break;
      }
    });
  }
  
  /// 显示错误消息
  void _showError(String message) {
    if (!mounted) return;
    
    MessageComponentFactory.showError(
      context,
      message: message,
    );
  }
  
  /// 保存当前会话
  Future<void> _saveCurrentSession() async {
    if (_sessions.isEmpty || _activeSessionIndex < 0 || _activeSessionIndex >= _sessions.length) {
      return;
    }
    
    final session = _sessions[_activeSessionIndex];
    if (!session.tab.isConnected) {
      _showError('未连接到SSH服务器');
      return;
    }
    
    try {
      // 创建会话信息
      final sessionName = '${session.tab.device.displayName} 会话';
      
      // 显示会话编辑对话框让用户确认或修改会话信息
      final savedSession = await SSHSessionEditDialog.show(
        context: context,
        session: SSHSavedSessionModel(
          name: sessionName,
          host: session.tab.device.ipAddress,
          port: session.tab.port,
          username: session.tab.username,
          password: session.tab.password,
        ),
      );
      
      if (savedSession != null && mounted) {
        // 保存会话信息
        final sessionController = Provider.of<SSHSessionController>(context, listen: false);
        await sessionController.addSession(savedSession);
        
        if (mounted) {
          MessageComponentFactory.showSuccess(
            context,
            message: '会话 "${savedSession.name}" 已保存',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('保存会话失败: $e');
      }
    }
  }
  
  @override
  void dispose() {
    // 记录需要释放的会话，但先调用super.dispose()
    final sessionsList = List<_SSHTerminalSession>.from(_sessions);
    
    // 先调用父类的dispose，确保组件正确销毁
    super.dispose();
    
    // 然后再异步释放资源，这样不会影响组件销毁流程
    Future.delayed(const Duration(milliseconds: 100), () {
      for (final session in sessionsList) {
        try {
          // 先取消流订阅
          session.terminalSubscription?.cancel();
          session.connectionStateSubscription?.cancel();
          
          // 然后断开控制器
          session.tab.controller.disconnect();
        } catch (e) {
          debugPrint('在dispose中断开SSH会话出错: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      // 安全检查，如果会话列表为空，返回空状态提示
      if (_sessions.isEmpty) {
        // 返回占位符，实际会被SidebarProvider中的EmptyTerminalWidget替代
        return const Center(
          child: Text('无活动会话', style: TextStyle(fontSize: 16, color: Colors.grey)),
        );
      }
      
      // 获取安全的当前活动会话索引
      final safeActiveIndex = math.min(_activeSessionIndex, _sessions.length - 1);
      if (safeActiveIndex < 0) {
        // 索引无效，返回占位符
        return const Center(
          child: Text('无活动会话', style: TextStyle(fontSize: 16, color: Colors.grey)),
        );
      }
      
      final session = _sessions[safeActiveIndex];
      final theme = Theme.of(context);
      
      return Column(
        children: [
          // 会话标签管理器
          SSHSessionTabManager(
            activeIndex: safeActiveIndex,
            sessions: _sessions.map((s) => s.tab).toList(),
            onAddSession: _addNewSession,
            onSwitchSession: _switchSession,
            onCloseSession: _closeSession,
          ),
          
          // 终端区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                child: Stack(
                  children: [
                    // 终端视图
                    TerminalView(
                      session.terminal,
                      autofocus: true,
                      // 终端样式配置
                      theme: TerminalTheme(
                        cursor: Colors.white,
                        selection: theme.colorScheme.primary.withOpacity(0.5),
                        foreground: Colors.white,
                        background: const Color(0xFF1E1E1E),
                        black: const Color(0xFF000000),
                        red: const Color(0xFFE74C3C),
                        green: const Color(0xFF2ECC71),
                        yellow: const Color(0xFFF1C40F),
                        blue: const Color(0xFF3498DB),
                        magenta: const Color(0xFF9B59B6),
                        cyan: const Color(0xFF1ABC9C),
                        white: const Color(0xFFECF0F1),
                        brightBlack: const Color(0xFF7F8C8D),
                        brightRed: const Color(0xFFE74C3C),
                        brightGreen: const Color(0xFF2ECC71),
                        brightYellow: const Color(0xFFFFD54F),
                        brightBlue: const Color(0xFF3498DB),
                        brightMagenta: const Color(0xFF9B59B6),
                        brightCyan: const Color(0xFF1ABC9C),
                        brightWhite: const Color(0xFFFFFFFF),
                        searchHitBackground: theme.colorScheme.secondary.withOpacity(0.4),
                        searchHitBackgroundCurrent: theme.colorScheme.secondary.withOpacity(0.7),
                        searchHitForeground: Colors.white,
                      ),
                    ),
                    
                    // 连接状态叠加层
                    if (!session.tab.isConnected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: session.tab.connectionStatus.contains('失败')
                                      ? Colors.red
                                      : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                session.tab.connectionStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      // 异常处理，显示错误页面而不是黑屏
      debugPrint('SSH终端界面构建错误: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('加载终端出错', style: TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (navigatorObserver.canNavigate() && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }
  }
}

/// SSH终端会话
class _SSHTerminalSession {
  /// 会话标签
  final SSHSessionTab tab;
  
  /// 终端控制器
  final Terminal terminal;
  
  /// 终端输出订阅
  StreamSubscription? terminalSubscription;
  
  /// 连接状态订阅
  StreamSubscription? connectionStateSubscription;
  
  /// 构造函数
  _SSHTerminalSession({
    required this.tab,
    required this.terminal,
  });
} 