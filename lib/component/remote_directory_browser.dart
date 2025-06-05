// ignore_for_file: use_super_parameters, unused_import, await_only_futures, unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_header_controller.dart';
import '../models/ssh_header_model.dart';
import '../models/ssh_model.dart';
import 'ssh_multi_terminal.dart';  // 导入SSH多终端组件以访问活动控制器

/// 远程目录浏览器对话框
class RemoteDirectoryBrowser extends StatefulWidget {
  /// SSH控制器
  final SSHController sshController;
  
  /// SSH头部控制器
  final SSHHeaderController headerController;
  
  /// 初始路径
  final String initialPath;
  
  /// 构造函数
  const RemoteDirectoryBrowser({
    Key? key,
    required this.sshController,
    required this.headerController,
    this.initialPath = '/tmp',
  }) : super(key: key);
  
  /// 显示远程目录浏览器对话框
  static Future<String?> show({
    required BuildContext context,
    required SSHController sshController,
    String initialPath = '/tmp',
  }) async {
    // 先延时等待SSH连接完全建立和认证完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 优先使用全局活动控制器并确保其已准备好
    final activeController = SSHMultiTerminal.getCurrentController();
    if (activeController != null && activeController.isConnected) {
      debugPrint('RemoteDirectoryBrowser.show: 全局活动控制器已连接，将使用它替代传入的控制器');
      sshController = activeController;
    } else if (activeController != null) {
      // 全局控制器存在但可能未连接，尝试等待其连接
      debugPrint('RemoteDirectoryBrowser.show: 全局活动控制器存在但未连接，尝试等待连接');
      final isReady = await SSHMultiTerminal.ensureActiveControllerReady();
      
      if (isReady) {
        debugPrint('RemoteDirectoryBrowser.show: 全局活动控制器已就绪，将使用它替代传入的控制器');
        sshController = activeController;
      } else {
        debugPrint('RemoteDirectoryBrowser.show: 全局活动控制器未就绪，将使用传入的控制器');
      }
    } else {
      debugPrint('RemoteDirectoryBrowser.show: 没有全局活动控制器，将使用传入的控制器');
    }
    
    debugPrint('RemoteDirectoryBrowser.show: 开始创建SSH头部控制器，SSH控制器连接状态: ${sshController.isConnected}');
    
    // 创建临时的SSH头部控制器
    final headerModel = SSHHeaderModel(
      title: '浏览目录',
      isConnected: sshController.isConnected,
    );
    
    final headerController = SSHHeaderController(
      model: headerModel,
      sshController: sshController,
    );
    
    try {
      // 预热SFTP客户端，尝试提前获取一次
      try {
        debugPrint('RemoteDirectoryBrowser.show: 尝试预热SFTP客户端');
        final sftp = await sshController.getSFTPClient();
        if (sftp != null) {
          debugPrint('RemoteDirectoryBrowser.show: SFTP客户端预热成功');
          
          // 预热成功后立即尝试列出初始目录，进一步确认SFTP可用
          try {
            final items = await sftp.readdir(initialPath);
            debugPrint('RemoteDirectoryBrowser.show: 已成功列出初始目录，SFTP完全可用');
          } catch (e) {
            debugPrint('RemoteDirectoryBrowser.show: 列出初始目录失败: $e');
          }
        } else {
          debugPrint('RemoteDirectoryBrowser.show: SFTP客户端预热失败，等待后再试');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('RemoteDirectoryBrowser.show: SFTP客户端预热出错: $e');
      }
      
      debugPrint('RemoteDirectoryBrowser.show: 准备显示对话框');
      
      return await showDialog<String>(
        context: context,
        builder: (context) => RemoteDirectoryBrowser(
          sshController: sshController,
          headerController: headerController,
          initialPath: initialPath,
        ),
      );
    } finally {
      // 确保对话框关闭后释放控制器资源
      headerController.dispose();
    }
  }

  @override
  State<RemoteDirectoryBrowser> createState() => _RemoteDirectoryBrowserState();
}

class _RemoteDirectoryBrowserState extends State<RemoteDirectoryBrowser> {
  /// 当前路径
  late String _currentPath;
  
  /// 目录内容
  List<String> _directoryContents = [];
  
  /// 加载状态
  bool _isLoading = true;
  
  /// 错误信息
  String? _errorMessage;
  
  /// 路径控制器
  late TextEditingController _pathController;
  
  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _pathController = TextEditingController(text: _currentPath);
    _loadDirectory(_currentPath);
  }
  
  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }
  
  /// 加载指定目录的内容
  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('RemoteDirectoryBrowser: 开始加载目录 $path');
      
      // 检查是否应该使用全局活动控制器
      final activeController = SSHMultiTerminal.getCurrentController();
      if (activeController != null && activeController.isConnected && 
          activeController != widget.sshController) {
        debugPrint('RemoteDirectoryBrowser: 使用全局活动控制器替代传入的控制器');
        
        // 创建一个新的临时头部控制器来访问远程目录
        final tempHeaderModel = SSHHeaderModel(
          title: '浏览目录',
          isConnected: activeController.isConnected,
        );
        
        final tempHeaderController = SSHHeaderController(
          model: tempHeaderModel,
          sshController: activeController,
        );
        
        // 使用临时控制器加载目录
        List<String> contents = await tempHeaderController.getRemoteDirectoryContents(path);
        tempHeaderController.dispose();
        
        if (!mounted) {
          debugPrint('RemoteDirectoryBrowser: 组件已销毁，不更新状态');
          return;
        }
        
        setState(() {
          _directoryContents = contents;
          _currentPath = path;
          _pathController.text = path;
          _isLoading = false;
        });
        
        debugPrint('RemoteDirectoryBrowser: 通过全局活动控制器成功加载目录，获取到 ${contents.length} 个项目');
        return;
      }
      
      // 尝试最多3次获取目录内容
      List<String>? contents;
      for (int i = 0; i < 3; i++) {
        try {
          contents = await widget.headerController.getRemoteDirectoryContents(path);
          
          // 如果成功获取目录内容，跳出循环
          if (contents.isNotEmpty) {
            debugPrint('RemoteDirectoryBrowser: 第${i+1}次尝试成功获取目录内容');
            break;
          }
          
          // 如果列表为空，稍等片刻再试
          debugPrint('RemoteDirectoryBrowser: 第${i+1}次尝试得到空列表，等待后重试');
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('RemoteDirectoryBrowser: 第${i+1}次尝试出错: $e');
          
          // 最后一次尝试失败时不等待
          if (i < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      // 如果contents仍然为null，说明所有尝试都失败了
      if (contents == null) {
        throw Exception('无法获取目录内容，多次尝试均失败');
      }
      
      if (!mounted) {
        debugPrint('RemoteDirectoryBrowser: 组件已销毁，不更新状态');
        return;
      }
      
      setState(() {
        _directoryContents = contents!;
        _currentPath = path;
        _pathController.text = path;
        _isLoading = false;
      });
      
      debugPrint('RemoteDirectoryBrowser: 成功加载目录，获取到 ${contents.length} 个项目');
    } catch (e) {
      debugPrint('RemoteDirectoryBrowser: 加载目录失败: $e');
      
      if (!mounted) {
        debugPrint('RemoteDirectoryBrowser: 组件已销毁，不更新状态');
        return;
      }
      
      setState(() {
        _errorMessage = '无法加载目录: $e';
        _isLoading = false;
      });
    }
  }
  
  /// 导航到上级目录
  void _navigateUp() {
    if (_currentPath == '/') return;
    
    final parentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    final newPath = parentPath.isEmpty ? '/' : parentPath;
    _loadDirectory(newPath);
  }
  
  /// 导航到指定目录
  void _navigateToDirectory(String directoryName) {
    // 移除目录前的"[目录] "标记
    final cleanDirName = directoryName.replaceFirst('[目录] ', '');
    
    // 构建新路径
    String newPath;
    if (_currentPath.endsWith('/')) {
      newPath = '$_currentPath$cleanDirName';
    } else {
      newPath = '$_currentPath/$cleanDirName';
    }
    
    _loadDirectory(newPath);
  }
  
  /// 构建目录列表
  Widget _buildDirectoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadDirectory(_currentPath),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (_directoryContents.isEmpty) {
      return const Center(
        child: Text('此目录为空'),
      );
    }
    
    return ListView.builder(
      itemCount: _directoryContents.length,
      itemBuilder: (context, index) {
        final item = _directoryContents[index];
        final isDirectory = item.startsWith('[目录]');
        
        return ListTile(
          leading: Icon(
            isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: isDirectory ? Colors.amber[600] : Colors.blue[400],
          ),
          title: Text(item.replaceFirst(isDirectory ? '[目录] ' : '[文件] ', '')),
          onTap: isDirectory 
            ? () => _navigateToDirectory(item)
            : null,
          enabled: isDirectory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_open, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('选择远程目录'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 路径导航栏
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  // 上级目录按钮
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: '上级目录',
                    onPressed: _navigateUp,
                  ),
                  
                  // 路径输入框
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _loadDirectory,
                    ),
                  ),
                  
                  // 刷新按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () => _loadDirectory(_currentPath),
                  ),
                ],
              ),
            ),
            
            // 目录内容列表
            Expanded(
              child: _buildDirectoryList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(_currentPath),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('选择此目录'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
} 