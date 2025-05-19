// ignore_for_file: unused_element, use_super_parameters, deprecated_member_use, unused_import, unnecessary_null_comparison, use_build_context_synchronously, undefined_hidden_name, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart' hide SSHException; // 引入dartssh2库，隐藏与本地类冲突的异常
import 'dart:math' as math;

import '../models/ip_model.dart';
import '../models/ssh_model.dart';
import '../models/ssh_saved_session_model.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_session_controller.dart';
import '../controllers/ssh_header_controller.dart';
import 'ssh_session_tab_manager.dart';
import 'message_component.dart';
import '../main.dart'; // 导入以访问导航观察器
import '../providers/sidebar_provider.dart' hide EmptyTerminalWidget; // 隐藏同名类
import 'empty_terminal_widget.dart';
import '../models/ssh_header_model.dart';

/// SSH多终端管理组件
class SSHMultiTerminal extends StatefulWidget {
  /// 初始会话设备
  final IPDeviceModel initialDevice;
  
  /// 初始会话凭据
  final String initialUsername;
  final String initialPassword;
  final int initialPort;
  
  /// 当前活动的SSH控制器实例，用于全局访问
  static SSHController? activeController;
  
  /// 获取当前活动的SSH控制器
  static SSHController? getCurrentController() {
    return activeController;
  }
  
  /// 设置当前活动的SSH控制器
  static void setActiveController(SSHController? controller) {
    if (controller != null && controller != activeController) {
      debugPrint('SSHMultiTerminal: 全局活动控制器已更新');
      activeController = controller;
    }
  }
  
  /// 获取当前活动SSH控制器的连接状态
  static bool isActiveControllerConnected() {
    return activeController?.isConnected ?? false;
  }
  
  /// 确保全局活动控制器已就绪
  static Future<bool> ensureActiveControllerReady() async {
    if (activeController == null) {
      debugPrint('SSHMultiTerminal: 活动控制器为null');
      return false;
    }
    
    // 尝试等待连接建立
    for (int i = 0; i < 3; i++) {
      if (activeController!.isConnected) {
        debugPrint('SSHMultiTerminal: 活动控制器已连接');
        return true;
      }
      
      debugPrint('SSHMultiTerminal: 等待活动控制器连接 (尝试 ${i+1}/3)');
      await Future.delayed(const Duration(seconds: 1));
    }
    
    debugPrint('SSHMultiTerminal: 活动控制器未能连接，等待超时');
    return false;
  }
  
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
    // 创建独立的SSH控制器实例
    final controller = _createNewSSHController();
    
    // 设置全局活动控制器
    SSHMultiTerminal.activeController = controller;
    debugPrint('SSHMultiTerminal: 已设置初始活动控制器');
    
    // 创建初始会话标签
    final initialTab = SSHSessionTab(
      displayName: '${widget.initialDevice.ipAddress} - ${widget.initialUsername}',
      device: widget.initialDevice,
      username: widget.initialUsername,
      password: widget.initialPassword,
      port: widget.initialPort,
      controller: controller,
    );
    
    // 创建会话终端
    final terminal = Terminal(maxLines: 10000);
    
    // 添加到会话列表
    _sessions.add(_SSHTerminalSession(
      tab: initialTab,
      terminal: terminal,
    ));
    
    // 标记为使用过
    _sessions.last.isTerminalUsed = true;
    
    // 连接到服务器
    _connectSession(0);
  }
  
  /// 添加新会话
  void _addNewSession() async {
    try {
      // 基于当前活动会话创建新会话（如果有）
      if (_sessions.isEmpty || _activeSessionIndex < 0 || _activeSessionIndex >= _sessions.length) {
        // 没有活动会话，显示错误
        _showError('没有可复制的活动会话');
        return;
      }
      
      // 禁用添加按钮，防止多次点击
      // 使用SnackBar提示用户正在创建新会话
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('正在创建新会话，请稍候...'),
          duration: Duration(seconds: 2),
        ));
      }
      
      // 获取当前活动会话的设备和凭据信息
      final activeSession = _sessions[_activeSessionIndex];
      final device = activeSession.tab.device;
      final username = activeSession.tab.username;
      final password = activeSession.tab.password;
      final port = activeSession.tab.port;
      
      // 生成新的会话名称，增加编号
      final baseDisplayName = activeSession.tab.displayName;
      
      // 计算当前会话编号（如果名称中有 #N 格式）
      int newIndex = 1;
      final regex = RegExp(r'#(\d+)$');
      final match = regex.firstMatch(baseDisplayName);
      
      String baseName = baseDisplayName;
      if (match != null && match.groupCount >= 1) {
        try {
          // 如果已有编号，提取基本名称和编号
          newIndex = int.parse(match.group(1)!) + 1;
          baseName = baseDisplayName.substring(0, match.start);
        } catch (e) {
          debugPrint('解析会话编号出错: $e');
        }
      }
      
      // 查找是否已存在相同编号的会话
      while (_sessions.any((s) => s.tab.displayName == '$baseName#$newIndex')) {
        newIndex++;
      }
      
      // 生成新的显示名称
      final newDisplayName = '$baseName#$newIndex';
      
      debugPrint('创建新会话: $newDisplayName，基于: $baseDisplayName');
      
      // 使用Future.delayed避免在当前帧操作
      Future.delayed(Duration.zero, () async {
        if (!mounted) return;
        
        // 创建一个全新的独立SSH控制器 - 这是关键，确保它不与现有会话共享状态
        // 调用一个Factory方法来获取新的控制器实例
        final newController = _createNewSSHController();
        
        // 创建终端
        final terminal = Terminal(maxLines: 10000);
        
        // 创建新会话标签
        final newTab = SSHSessionTab(
          displayName: newDisplayName,
          device: device,
          username: username,
          password: password,
          port: port,
          controller: newController,
        );
        
        // 添加到会话列表，但不立即切换
        final newSessionIndex = _sessions.length;
        
        setState(() {
          _sessions.add(_SSHTerminalSession(
            tab: newTab,
            terminal: terminal,
          ));
          
          // 标记为使用过
          _sessions.last.isTerminalUsed = true;
        });
        
        // 连接新会话前进行短暂延迟
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (!mounted) return;
        
        // 连接新会话
        await _connectSession(newSessionIndex);
        
        // 连接成功后再切换到新会话
        if (mounted) {
          setState(() {
            _activeSessionIndex = newSessionIndex;
          });
        }
      });
    } catch (e) {
      _showError('添加会话出错: $e');
    }
  }
  
  /// 创建新的SSH控制器实例
  SSHController _createNewSSHController() {
    // 创建全新的独立控制器实例
    final controller = SSHController();
    
    // 防止控制器被过早销毁
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 将控制器添加到生命周期管理（如果需要）
    });
    
    return controller;
  }
  
  /// 切换会话
  void _switchSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      setState(() {
        _activeSessionIndex = index;
        
        // 更新全局活动控制器
        SSHMultiTerminal.activeController = _sessions[index].tab.controller;
        debugPrint('SSHMultiTerminal: 已更新活动控制器到会话 #$index');
        
        // 检查控制器是否连接，如果未连接尝试建立连接
        if (!_sessions[index].tab.controller.isConnected) {
          debugPrint('SSHMultiTerminal: 切换到的会话未连接，尝试建立连接');
          // 使用Future.microtask避免在setState中进行异步操作
          Future.microtask(() => _connectSession(index));
        } else {
          debugPrint('SSHMultiTerminal: 切换到的会话已连接');
        }
      });
    }
  }
  
  /// 关闭会话
  void _closeSession(int index) {
    if (index < 0 || index >= _sessions.length) {
      return; // 只检查索引范围是否有效
    }
    
    // 获取会话
    final session = _sessions[index];
    
    // 检查是否有文件传输正在进行
    // 创建一个临时的SSH头部控制器
    final headerModel = SSHHeaderModel(
      title: '终端',
      isConnected: session.tab.controller.isConnected,
    );
    
    final headerController = SSHHeaderController(
      model: headerModel,
      sshController: session.tab.controller,
    );
    
    if (headerController.isTransferringFile) {
      // 显示文件传输警告对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('文件传输进行中'),
            ],
          ),
          content: const Text(
            '有文件传输正在进行，关闭会话将中断传输。\n您确定要关闭此会话吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 强制关闭会话
                _forceCloseSession(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('强制关闭'),
            ),
          ],
        ),
      );
      return;
    }
    
    // 如果没有文件传输，直接关闭
    _forceCloseSession(index);
  }
  
  /// 连接会话
  Future<void> _connectSession(int index) async {
    if (index < 0 || index >= _sessions.length) {
      return; // 只检查索引范围是否有效
    }
    
    // 获取会话
    final session = _sessions[index];
    
    // 更新全局活动控制器
    SSHMultiTerminal.activeController = session.tab.controller;
    debugPrint('SSHMultiTerminal: 已更新活动控制器到会话 #$index');
    
    if (!mounted) return;
    
    // 检查连接状态，如果已连接，无需再连接
    if (session.tab.controller.isConnected) {
      // 如果已连接但终端没显示内容，尝试重新启动shell会话
      try {
        final sshSession = session.tab.controller.currentSession?.session;
        if (sshSession != null) {
          debugPrint('SSH已连接，重用现有Shell会话');
          
          // 强制重新初始化终端
          _setupTerminal(session, sshSession, index);
          
          // 预热SFTP客户端
          _preheatSFTPClient(session.tab.controller);
          
          return;
        }
      } catch (e) {
        debugPrint('检查现有Shell会话时出错: $e');
      }
    }
    
    // 创建终端会话
    final terminal = session.terminal;
    
    // 显示连接状态
    terminal.write('正在连接到 ${session.tab.device.ipAddress}...\r\n');
    
    try {
      // 断开可能存在的连接
      try {
        await session.tab.controller.disconnect();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('断开可能存在的连接出错: $e');
      }
      
      // 连接到SSH服务器
      final success = await session.tab.controller.connect(
        host: session.tab.device.ipAddress,
        username: session.tab.username,
        password: session.tab.password,
        port: session.tab.port,
        context: context,
      );
      
      if (!mounted) return;
      
      if (success) {
        // 延迟一段时间，确保SSH客户端完全初始化
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        
        // 确保终端尺寸已设置
        if (terminal.viewWidth <= 0 || terminal.viewHeight <= 0) {
          terminal.resize(80, 24);
          debugPrint('初始化终端尺寸: 80x24');
        }
        
        // 连接成功，启动Shell会话
        final sshSession = await session.tab.controller.startShell();
        
        // 再次延迟，确保Shell会话完全初始化
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        
        if (sshSession != null) {
          // 取消之前可能存在的流订阅
          if (session.terminalSubscription != null) {
            await session.terminalSubscription!.cancel();
            session.terminalSubscription = null;
          }
          
          // 取消之前可能存在的状态监听
          if (session.connectionStateSubscription != null) {
            await session.connectionStateSubscription!.cancel();
            session.connectionStateSubscription = null;
          }
          
          _setupTerminal(session, sshSession, index);
          
          // 显示连接成功消息
          terminal.write('连接成功！请稍候，正在初始化终端...\r\n');
          
          // 预热SFTP客户端
          _preheatSFTPClient(session.tab.controller);
          
          // 发送一些初始命令，确保Shell显示提示符
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              try {
                // 发送终端刷新命令
                session.tab.controller.sendToShellClient('\r');
                session.tab.controller.sendToShellClient('export TERM=xterm\r');
                
                // 安全地触发刷新
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
                
                // 额外的初始化命令
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    session.tab.controller.sendToShellClient('stty sane\r');
                    
                    // 安全地触发刷新
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                    
                    // 最终的提示符触发
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        session.tab.controller.sendToShellClient('\r');
                        
                        // 安全地触发刷新
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      }
                    });
                  }
                });
              } catch (e) {
                debugPrint('发送初始命令时出错: $e');
              }
            }
          });
        } else {
          // Shell会话创建失败
          terminal.write('创建Shell会话失败\r\n');
        }
      } else {
        // 连接失败
        terminal.write('连接失败\r\n');
      }
    } catch (e) {
      if (mounted) {
        // 显示连接错误
        terminal.write('连接错误: $e\r\n');
      }
    }
  }
  
  /// 预热SFTP客户端以确保SFTP功能可用
  void _preheatSFTPClient(SSHController controller) {
    // 在后台尝试获取SFTP客户端，预热SFTP子系统
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        debugPrint('SSHMultiTerminal: 预热SFTP客户端...');
        final sftp = await controller.getSFTPClient();
        if (sftp != null) {
          // 尝试进行一个简单的SFTP操作以完全初始化SFTP子系统
          try {
            await sftp.stat('/'); // 获取根目录状态
            debugPrint('SSHMultiTerminal: SFTP客户端预热成功');
          } catch (e) {
            debugPrint('SSHMultiTerminal: SFTP操作失败，但客户端已初始化: $e');
          }
        } else {
          debugPrint('SSHMultiTerminal: 获取SFTP客户端失败');
        }
      } catch (e) {
        debugPrint('SSHMultiTerminal: 预热SFTP客户端时出错: $e');
      }
    });
  }
  
  /// 设置终端和流处理
  void _setupTerminal(
    _SSHTerminalSession session, 
    SSHSession sshSession, 
    int index
  ) {
    final terminal = session.terminal;
    
    // 强制设置终端初始大小
    if (terminal.viewWidth <= 0 || terminal.viewHeight <= 0) {
      terminal.resize(80, 24); // 设置一个合理的默认值
      debugPrint('重新设置终端尺寸: 80x24');
    }
    
    // 订阅Shell输出
    session.terminalSubscription = sshSession.stdout.listen((data) {
      try {
        // 记录收到的数据用于调试
        if (data.isNotEmpty) {
          debugPrint('收到Shell数据: ${data.length}字节');
        }
        
        // 将数据写入终端
        terminal.write(utf8.decode(data, allowMalformed: true));
        
        // 使用安全的方式触发刷新，避免在构建过程中调用setState
        if (mounted && index == _activeSessionIndex) {
          // 不直接调用setState，使用延迟微任务安排UI更新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                // 空的setState强制刷新
              });
            }
          });
        }
      } catch (e) {
        debugPrint('向终端写入数据时出错: $e');
      }
    }, onError: (e) {
      debugPrint('Shell输出流错误: $e');
    });
    
    // 设置终端输入回调
    terminal.onOutput = (data) {
      try {
        // 将用户输入发送到Shell
        session.tab.controller.sendToShellClient(data);
      } catch (e) {
        debugPrint('向Shell发送数据时出错: $e');
      }
    };
    
    // 终端调整大小处理
    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      try {
        // 可以通过数据传输为SSH终端设置终端窗口大小
        debugPrint('终端大小调整: ${width}x${height}');
        
        // 安全地触发更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      } catch (e) {
        debugPrint('调整终端大小时出错: $e');
      }
    };
    
    // 订阅连接状态变化
    session.connectionStateSubscription = session.tab.controller.connectionStateStream.listen((state) {
      if (state == SSHConnectionState.disconnected || state == SSHConnectionState.failed) {
        try {
          terminal.write('\r\n连接已断开\r\n');
          
          // 安全地触发UI更新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        } catch (e) {
          debugPrint('连接断开时写入终端出错: $e');
        }
      }
    }, onError: (e) {
      debugPrint('连接状态流错误: $e');
    });
  }
  
  /// 强制关闭会话
  void _forceCloseSession(int index) {
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
    
    // 处理关闭非最后一个会话的情况
    
    // 保存会话引用用于后续清理
    final sessionToClose = _sessions[index];
    
    // 计算新的活动会话索引
    int newActiveIndex = _activeSessionIndex;
    if (index == _activeSessionIndex) {
      // 如果关闭的是当前活动会话
      if (index == _sessions.length - 1) {
        // 如果关闭的是最后一个会话，选择前一个
        newActiveIndex = math.max(0, index - 1);
      } else {
        // 否则选择下一个
        newActiveIndex = index;
      }
    } else if (index < _activeSessionIndex) {
      // 如果关闭的会话索引小于当前活动索引，调整活动索引
      newActiveIndex--;
    }
    
    // 更新状态：从列表中移除会话并更新活动索引
    setState(() {
      _sessions.removeAt(index);
      _activeSessionIndex = newActiveIndex;
    });
    
    // 延迟清理资源以避免在setState期间修改
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // 取消终端输出订阅
        if (sessionToClose.terminalSubscription != null) {
          sessionToClose.terminalSubscription!.cancel();
          sessionToClose.terminalSubscription = null;
        }
        
        // 取消连接状态订阅
        if (sessionToClose.connectionStateSubscription != null) {
          sessionToClose.connectionStateSubscription!.cancel();
          sessionToClose.connectionStateSubscription = null;
        }
        
        // 断开连接
        if (sessionToClose.tab.controller.isConnected) {
          sessionToClose.tab.controller.disconnect();
        }
      } catch (e) {
        debugPrint('关闭SSH会话资源时出错: $e');
      }
    });
  }
  
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
  Widget build(BuildContext context) {
    // 检查会话列表是否为空
    if (_sessions.isEmpty) {
      return const EmptyTerminalWidget();
    }
    
    // 获取当前活动会话
    final activeSession = _sessions[_activeSessionIndex];
    
    return Column(
      children: [
        // 会话标签栏
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Row(
            children: [
              // 会话标签
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final isActive = index == _activeSessionIndex;
                    
                    return SessionTabWidget(
                      title: session.tab.displayName,
                      isActive: isActive,
                      onTap: () => _switchSession(index),
                      onClose: () => _closeSession(index),
                      isConnected: session.tab.controller.isConnected,
                    );
                  },
                ),
              ),
              
              // 添加新会话按钮
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '添加新会话',
                onPressed: _addNewSession,
              ),
            ],
          ),
        ),
        
        // 会话终端内容
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // 终端视图
                TerminalView(activeSession.terminal),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// 重新连接会话
  Future<void> _reconnectSession(int index) async {
    if (index < 0 || index >= _sessions.length) return;
    
    // 获取会话
    final session = _sessions[index];
    
    // 显示重连消息
    try {
      session.terminal.write('\r\n正在重新连接...\r\n');
    } catch (e) {
      debugPrint('写入重连消息时出错: $e');
    }
    
    // 安全地刷新UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // 尝试重新连接
    await _connectSession(index);
  }
  
  @override
  void dispose() {
    // 释放所有会话资源
    for (final session in _sessions) {
      try {
        // 取消终端输出订阅
        if (session.terminalSubscription != null) {
          session.terminalSubscription!.cancel();
        }
        
        // 取消连接状态订阅
        if (session.connectionStateSubscription != null) {
          session.connectionStateSubscription!.cancel();
        }
        
        // 断开连接
        if (session.tab.controller.isConnected) {
          session.tab.controller.disconnect();
        }
      } catch (e) {
        debugPrint('释放SSH会话资源时出错: $e');
      }
    }
    
    super.dispose();
  }
}

/// 会话标签组件
class SessionTabWidget extends StatelessWidget {
  /// 标签标题
  final String title;
  
  /// 是否处于活动状态
  final bool isActive;
  
  /// 是否已连接
  final bool isConnected;
  
  /// 点击事件回调
  final VoidCallback onTap;
  
  /// 关闭事件回调
  final VoidCallback onClose;
  
  /// 构造函数
  const SessionTabWidget({
    Key? key,
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    this.isConnected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.surface : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive 
              ? Theme.of(context).colorScheme.primary 
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标签标题
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              // 关闭按钮
              const SizedBox(width: 6),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SSH终端会话
class _SSHTerminalSession {
  /// 会话标签
  final SSHSessionTab tab;
  
  /// 终端实例
  final Terminal terminal;
  
  /// 终端输出订阅
  StreamSubscription? terminalSubscription;
  
  /// 连接状态订阅
  StreamSubscription<SSHConnectionState>? connectionStateSubscription;
  
  /// 是否已使用终端
  bool isTerminalUsed = false;
  
  /// 构造函数
  _SSHTerminalSession({
    required this.tab,
    required this.terminal,
  });
}

/// 会话标签配置
class TerminalTabConfig {
  final IPDeviceModel device;
  final String username;
  final String password;
  final int port;
  final SSHController controller;
  final SSHHeaderController headerController;
  
  const TerminalTabConfig({
    required this.device,
    required this.username,
    required this.password,
    required this.port,
    required this.controller,
    required this.headerController,
  });
}

/// 会话信息
class SessionInfo {
  final TerminalTabConfig tab;
  final Terminal terminal;
  StreamSubscription<List<int>>? terminalSubscription;
  StreamSubscription<SSHConnectionState>? connectionStateSubscription;
  
  SessionInfo({
    required this.tab,
    required this.terminal,
    this.terminalSubscription,
    this.connectionStateSubscription,
  });
} 