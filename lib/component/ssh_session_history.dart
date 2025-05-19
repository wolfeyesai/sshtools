// ignore_for_file: use_super_parameters, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_session_controller.dart';
import '../models/ssh_saved_session_model.dart';
import '../controllers/ssh_controller.dart';
import '../providers/sidebar_provider.dart';
import '../views/ssh_terminal_screen.dart';
import '../models/ip_model.dart';
import 'message_component.dart';

/// SSH会话历史组件
class SSHSessionHistory extends StatefulWidget {
  /// 构造函数
  const SSHSessionHistory({Key? key}) : super(key: key);

  @override
  State<SSHSessionHistory> createState() => _SSHSessionHistoryState();
}

class _SSHSessionHistoryState extends State<SSHSessionHistory> {
  /// 用于限制日志打印频率
  static DateTime? _lastLogTime;
  
  /// 检查是否应该打印日志
  bool _shouldPrintLog() {
    final now = DateTime.now();
    if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds > 15) {
      _lastLogTime = now;
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initSessionController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSessionController();
  }

  /// 初始化会话控制器
  void _initSessionController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_shouldPrintLog()) {
          debugPrint('SSHSessionHistory: 初始化会话控制器');
        }
        final sessionController = Provider.of<SSHSessionController>(context, listen: false);
        // 直接调用loadSessions而不是init，避免重复初始化
        Future.delayed(Duration.zero, () {
          sessionController.loadSessions();
        });
      }
    });
  }
  
  /// 连接到会话
  void _connectToSession(BuildContext context, SSHSavedSessionModel session) {
    // 使用try-catch包装整个方法
    try {
      if (!context.mounted) return;
      
      // 创建一个简单的IPDeviceModel用于终端页面
      final device = IPDeviceModel(
        ipAddress: session.host,
        hostname: session.name,
      );
      
      // 获取Provider并准备更新
      final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
      final sessionController = Provider.of<SSHSessionController>(context, listen: false);
      
      // 在切换页面前先更新会话时间，错误处理
      try {
        sessionController.markSessionAsUsed(session.id);
      } catch (e) {
        if (_shouldPrintLog()) {
          debugPrint('标记会话使用时间出错: $e');
        }
      }
      
      // 创建终端页面，但不立即使用
      final terminalPage = SSHTerminalPage(
        device: device,
        username: session.username,
        password: session.password,
        port: session.port,
      );
      
      // 将连接操作推迟到下一个帧
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (!context.mounted) return;
          
          // 首先显示轻量级消息
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('正在连接到 ${session.name}...'),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          
          // 先切换到终端页面索引，然后更新内容
          // 重要：先设置索引再更新页面内容
          sidebarProvider.setIndex(1);
          
          // 添加更长的延迟确保先完成索引切换
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              if (!context.mounted) return;
              
              // 更新终端页面内容
              sidebarProvider.updateTerminalPage(terminalPage);
              
              // 记录调试信息
              if (_shouldPrintLog()) {
                debugPrint('已切换到终端页面并更新内容: ${session.name} (${session.host})');
              }
            } catch (e) {
              if (_shouldPrintLog()) {
                debugPrint('更新终端页面出错: $e');
              }
            }
          });
        } catch (e) {
          if (_shouldPrintLog()) {
            debugPrint('连接会话处理出错: $e');
          }
        }
      });
    } catch (e) {
      if (_shouldPrintLog()) {
        debugPrint('SSH会话连接出错: $e');
      }
      
      // 非常轻量级的错误处理，避免状态更新问题
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接错误: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// 删除会话
  Future<void> _deleteSession(BuildContext context, SSHSavedSessionModel session) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除会话 "${session.name}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      
      if (confirmed == true && context.mounted) {
        final sessionController = Provider.of<SSHSessionController>(context, listen: false);
        
        // 使用Future.microtask确保在UI渲染完成后执行状态更新
        Future.microtask(() async {
          await sessionController.deleteSession(session.id);
          
          if (context.mounted) {
            MessageComponentFactory.showSuccess(
              context,
              message: '会话 "${session.name}" 已删除',
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        MessageComponentFactory.showError(
          context,
          message: '删除会话失败: $e',
        );
      }
    }
  }
  
  /// 切换收藏状态
  Future<void> _toggleFavorite(BuildContext context, SSHSavedSessionModel session) async {
    try {
      if (!context.mounted) return;
      
      final sessionController = Provider.of<SSHSessionController>(context, listen: false);
      
      // 使用Future.microtask确保在UI渲染完成后执行状态更新
      Future.microtask(() async {
        await sessionController.toggleFavorite(session.id);
      });
    } catch (e) {
      if (_shouldPrintLog()) {
        debugPrint('切换收藏状态失败: $e');
      }
    }
  }
  
  /// 清空历史记录
  Future<void> _clearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有会话历史吗？收藏的会话将被保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      await Provider.of<SSHSessionController>(context, listen: false)
          .clearHistory();
          
      if (context.mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: '会话历史已清空',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = Provider.of<SSHSessionController>(context, listen: false);
    // 不再使用局部变量存储shouldLog结果，而是每次需要时都直接调用方法
    
    if (_shouldPrintLog()) {
      debugPrint('SSHSessionHistory: build方法被调用');
    }
    
    // 避免在build方法中直接执行异步操作
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 确保数据已经加载
          if (sessionController.sessions.isEmpty) {
            if (_shouldPrintLog()) {
              debugPrint('SSHSessionHistory: 会话列表为空，尝试重新加载');
            }
            sessionController.loadSessions();
          } else if (_shouldPrintLog()) {
            debugPrint('SSHSessionHistory: 会话列表已加载 ${sessionController.sessions.length} 个会话');
          }
        }
      });
    }
    
    return Consumer<SSHSessionController>(
      builder: (context, controller, child) {
        try {
          // 获取会话列表，先显示收藏的，然后是最近使用的
          // 使用List.from创建一个新列表，避免直接使用可能不可变的列表
          final List<SSHSavedSessionModel> favoritesSessions = List.from(controller.favoriteSessions);
          final List<SSHSavedSessionModel> nonFavoritesSessions = 
              controller.sessions.where((s) => !s.isFavorite).toList();
              
          final List<SSHSavedSessionModel> sessions = [...favoritesSessions, ...nonFavoritesSessions];
          
          if (_shouldPrintLog()) {
            debugPrint('SSHSessionHistory: Consumer构建UI，会话数: ${sessions.length}');
          }
          
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题和操作按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '历史连接',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      tooltip: '清空历史',
                      onPressed: () => _clearHistory(context),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              
              // 会话列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= sessions.length) {
                      // 防止索引越界
                      return const SizedBox.shrink();
                    }
                    final session = sessions[index];
                    return _buildSessionCard(context, session);
                  },
                ),
              ),
            ],
          );
        } catch (e) {
          // 出现错误时显示备用UI
          if (_shouldPrintLog()) {
            debugPrint('SSH会话历史构建出错: $e');
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  '加载历史连接时出错',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  onPressed: () {
                    // 强制刷新
                    Provider.of<SSHSessionController>(context, listen: false).init();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
  
  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '暂无连接历史',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '连接SSH设备后将自动保存连接记录',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建会话卡片
  Widget _buildSessionCard(BuildContext context, SSHSavedSessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  radius: 20,
                  child: Icon(
                    Icons.computer,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 信息部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            session.username,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.link, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            '${session.host}:${session.port}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            '最后连接: ${_formatDateTime(session.lastConnectedAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 操作按钮
                Column(
                  children: [
                    // 收藏按钮
                    IconButton(
                      icon: Icon(
                        session.isFavorite ? Icons.star : Icons.star_border,
                        color: session.isFavorite ? Colors.amber : null,
                        size: 18,
                      ),
                      tooltip: session.isFavorite ? '取消收藏' : '收藏',
                      onPressed: () => _toggleFavorite(context, session),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    
                    // 删除按钮
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      tooltip: '删除',
                      onPressed: () => _deleteSession(context, session),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                ),
              ],
            ),
          ),
           
          const Divider(height: 1),
            
          // 连接按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.terminal, size: 16),
                label: const Text(
                  '连接SSH',
                  style: TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _connectToSession(context, session),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 30) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 