// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';

/// 远程目录浏览器对话框
class RemoteDirectoryBrowser extends StatefulWidget {
  /// SSH控制器
  final SSHController sshController;
  
  /// 初始路径
  final String initialPath;
  
  /// 构造函数
  const RemoteDirectoryBrowser({
    Key? key,
    required this.sshController,
    this.initialPath = '/tmp',
  }) : super(key: key);
  
  /// 显示远程目录浏览器对话框
  static Future<String?> show({
    required BuildContext context,
    required SSHController sshController,
    String initialPath = '/tmp',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => RemoteDirectoryBrowser(
        sshController: sshController,
        initialPath: initialPath,
      ),
    );
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
      final contents = await widget.sshController.getRemoteDirectoryContents(path);
      
      setState(() {
        _directoryContents = contents;
        _currentPath = path;
        _pathController.text = path;
        _isLoading = false;
      });
    } catch (e) {
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