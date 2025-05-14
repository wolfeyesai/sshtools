// ignore_for_file: use_super_parameters, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ssh_command_model.dart';
import '../controllers/ssh_command_controller.dart';
import '../component/ssh_command_edit_dialog.dart';
import '../component/message_component.dart';
import '../component/Button_component.dart';
import '../component/import_export_manager.dart';
import '../controllers/ssh_session_controller.dart';

/// SSH命令管理页面
class SSHCommandManagerPage extends StatefulWidget {
  /// 页面标题
  static const String pageTitle = 'SSH命令管理';
  
  /// 路由名称
  static const String routeName = '/ssh-command-manager';

  const SSHCommandManagerPage({Key? key}) : super(key: key);

  @override
  State<SSHCommandManagerPage> createState() => _SSHCommandManagerPageState();
}

class _SSHCommandManagerPageState extends State<SSHCommandManagerPage> with SingleTickerProviderStateMixin {
  /// 标签控制器
  late TabController _tabController;
  
  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();
  
  /// 搜索关键词
  String _searchKeyword = '';
  
  /// 初始化状态
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // 初始化命令控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SSHCommandController>(context, listen: false).init();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  /// 添加新命令
  Future<void> _addCommand() async {
    try {
      final command = await SSHCommandEditDialog.show(context);
      
      if (command != null && mounted) {
        final controller = Provider.of<SSHCommandController>(context, listen: false);
        await controller.addCommand(command);
        
        if (mounted) {
          MessageComponentFactory.showSuccess(
            context,
            message: '命令 "${command.name}" 已添加',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageComponentFactory.showError(
          context,
          message: '添加命令失败: $e',
        );
      }
      debugPrint('添加命令失败: $e');
    }
  }
  
  /// 编辑命令
  Future<void> _editCommand(SSHCommandModel command) async {
    try {
      final updatedCommand = await SSHCommandEditDialog.show(
        context,
        command: command,
      );
      
      if (updatedCommand != null && mounted) {
        final controller = Provider.of<SSHCommandController>(context, listen: false);
        await controller.updateCommand(updatedCommand);
        
        if (mounted) {
          MessageComponentFactory.showSuccess(
            context,
            message: '命令 "${updatedCommand.name}" 已更新',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageComponentFactory.showError(
          context,
          message: '更新命令失败: $e',
        );
      }
      debugPrint('更新命令失败: $e');
    }
  }
  
  /// 删除命令
  Future<void> _deleteCommand(SSHCommandModel command) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除命令 "${command.name}" 吗？'),
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
    
    if (confirmed == true) {
      final controller = Provider.of<SSHCommandController>(context, listen: false);
      await controller.deleteCommand(command.id);
      
      if (mounted) {
        MessageComponentFactory.showSuccess(
          context,
          message: '命令 "${command.name}" 已删除',
        );
      }
    }
  }
  
  /// 切换收藏状态
  Future<void> _toggleFavorite(SSHCommandModel command) async {
    final controller = Provider.of<SSHCommandController>(context, listen: false);
    await controller.toggleFavorite(command.id);
  }
  
  /// 构建命令卡片
  Widget _buildCommandCard(SSHCommandModel command) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 命令头部（名称+操作按钮）
          ListTile(
            title: Text(
              command.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(command.typeName),
            leading: _getIconForCommandType(command.type),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 收藏按钮
                IconButton(
                  icon: Icon(
                    command.isFavorite ? Icons.star : Icons.star_border,
                    color: command.isFavorite ? Colors.amber : null,
                  ),
                  tooltip: command.isFavorite ? '取消收藏' : '收藏',
                  onPressed: () => _toggleFavorite(command),
                ),
                
                // 编辑按钮
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                  onPressed: () => _editCommand(command),
                ),
                
                // 删除按钮
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除',
                  color: Colors.red,
                  onPressed: () => _deleteCommand(command),
                ),
              ],
            ),
          ),
          
          // 命令内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (command.description.isNotEmpty) ...[
                  Text(
                    command.description,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // 命令代码块
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    command.command,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // 显示标签
                if (command.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: command.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ButtonComponent.create(
                        type: ButtonType.custom,
                        label: '立即执行',
                        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                        onPressed: () {
                          // 直接返回命令，让终端页面执行
                          Navigator.of(context).pop(command);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建命令列表
  Widget _buildCommandList(List<SSHCommandModel> commands) {
    // 防止命令列表为null
    final List<SSHCommandModel> safeCommands = commands;
    
    if (safeCommands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '没有命令',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addCommand,
              icon: const Icon(Icons.add),
              label: const Text('添加命令'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // 过滤搜索结果
    List<SSHCommandModel> filteredCommands = [];
    try {
      filteredCommands = _searchKeyword.isEmpty
          ? safeCommands
          : safeCommands.where((cmd) {
              final keyword = _searchKeyword.toLowerCase();
              return cmd.name.toLowerCase().contains(keyword) ||
                  cmd.command.toLowerCase().contains(keyword) ||
                  cmd.description.toLowerCase().contains(keyword);
            }).toList();
    } catch (e) {
      debugPrint('过滤命令失败: $e');
      filteredCommands = safeCommands;
    }
    
    if (filteredCommands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的命令',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchKeyword = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('清除搜索'),
            ),
          ],
        ),
      );
    }
    
    // 使用try-catch包装整个列表构建过程
    try {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCommands.length,
        itemBuilder: (context, index) {
          if (index < 0 || index >= filteredCommands.length) {
            // 防止索引越界
            return const SizedBox.shrink();
          }
          return _buildCommandCard(filteredCommands[index]);
        },
      );
    } catch (e) {
      debugPrint('构建命令列表出错: $e');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('加载命令列表出错'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchKeyword = '';
                  _searchController.clear();
                });
              },
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }
  }
  
  /// 获取命令类型对应的图标
  Widget _getIconForCommandType(SSHCommandType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case SSHCommandType.general:
        iconData = Icons.terminal;
        iconColor = Colors.blue;
        break;
      case SSHCommandType.system:
        iconData = Icons.computer;
        iconColor = Colors.green;
        break;
      case SSHCommandType.network:
        iconData = Icons.wifi;
        iconColor = Colors.orange;
        break;
      case SSHCommandType.file:
        iconData = Icons.folder;
        iconColor = Colors.amber;
        break;
      case SSHCommandType.custom:
        iconData = Icons.build;
        iconColor = Colors.purple;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      foregroundColor: iconColor,
      child: Icon(iconData),
    );
  }
  
  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索命令...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchKeyword = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });
        },
      ),
    );
  }
  
  /// 构建应用栏操作按钮
  List<Widget> _buildAppBarActions() {
    return [
      // 导入导出按钮
      IconButton(
        icon: const Icon(Icons.import_export),
        tooltip: '导入/导出命令',
        onPressed: () {
          final commandController = Provider.of<SSHCommandController>(context, listen: false);
          final sessionController = Provider.of<SSHSessionController>(context, listen: false);
          ImportExportManager.show(
            context,
            commandController: commandController,
            sessionController: sessionController,
          );
        },
      ),
      
      // 添加命令按钮
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '添加命令',
        onPressed: _addCommand,
      ),
      
      // 重置预设按钮
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: '重置为预设命令',
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认重置'),
              content: const Text('重置将会删除所有自定义命令，并恢复预设命令。此操作无法撤销，确定要继续吗？'),
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
                  child: const Text('重置'),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            final controller = Provider.of<SSHCommandController>(context, listen: false);
            await controller.resetToPresets();
            
            if (mounted) {
              MessageComponentFactory.showSuccess(
                context,
                message: '命令已重置为预设值',
              );
            }
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.terminal, size: 24),
            const SizedBox(width: 8),
            const Text(SSHCommandManagerPage.pageTitle),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _buildAppBarActions(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(
              icon: Icon(Icons.star),
              text: '收藏',
            ),
            const Tab(
              icon: Icon(Icons.all_inclusive),
              text: '全部',
            ),
            Tab(
              icon: _getIconForCommandType(SSHCommandType.general),
              text: '通用命令',
            ),
            Tab(
              icon: _getIconForCommandType(SSHCommandType.system),
              text: '系统命令',
            ),
            Tab(
              icon: _getIconForCommandType(SSHCommandType.network),
              text: '网络命令',
            ),
            Tab(
              icon: _getIconForCommandType(SSHCommandType.file),
              text: '文件操作',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          
          // 命令列表
          Expanded(
            child: Consumer<SSHCommandController>(
              builder: (context, controller, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 收藏标签
                    _buildCommandList(controller.favoriteCommands),
                    
                    // 全部标签
                    _buildCommandList(controller.commands),
                    
                    // 通用命令标签
                    _buildCommandList(controller.getCommandsByType(SSHCommandType.general)),
                    
                    // 系统命令标签
                    _buildCommandList(controller.getCommandsByType(SSHCommandType.system)),
                    
                    // 网络命令标签
                    _buildCommandList(controller.getCommandsByType(SSHCommandType.network)),
                    
                    // 文件操作标签
                    _buildCommandList(controller.getCommandsByType(SSHCommandType.file)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCommand,
        tooltip: '添加命令',
        child: const Icon(Icons.add),
      ),
    );
  }
} 