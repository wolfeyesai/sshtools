// ignore_for_file: unused_import, unused_element, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dartssh2/dartssh2.dart';
import '../models/ssh_header_model.dart';
import '../models/ssh_model.dart';
import '../models/ip_model.dart';
import '../controllers/ssh_controller.dart';
import '../component/message_component.dart';
import '../component/ssh_file_uploader.dart';
import '../component/ssh_file_downloader.dart';

/// SSH页头控制器，用于管理SSH页头的业务逻辑
class SSHHeaderController extends ChangeNotifier {
  /// 模型引用
  final SSHHeaderModel _model;
  
  /// SSH控制器引用
  final SSHController _sshController;
  
  /// 连接状态订阅
  StreamSubscription<SSHConnectionState>? _connectionStateSubscription;
  
  /// 是否已销毁
  bool _isDisposed = false;
  
  /// 文件传输信息
  SSHFileTransferInfo? _currentFileTransfer;
  
  /// 文件传输进度监听器
  final _fileTransferProgressController = StreamController<double>.broadcast();
  
  /// 文件传输状态监听器
  final _fileTransferStateController = StreamController<FileTransferState>.broadcast();
  
  /// 是否正在进行文件传输
  bool _isTransferringFile = false;

  /// 构造函数
  SSHHeaderController({
    required SSHHeaderModel model,
    required SSHController sshController,
  }) : _model = model,
       _sshController = sshController {
    _init();
  }
  
  /// 初始化控制器
  void _init() {
    // 订阅SSH连接状态变化
    _connectionStateSubscription = _sshController.connectionStateStream.listen(_handleConnectionStateChange);
  }
  
  /// 处理连接状态变化
  void _handleConnectionStateChange(SSHConnectionState state) {
    if (_isDisposed) return;
    
    // 更新模型中的连接状态
    _model.isConnected = state == SSHConnectionState.connected;
  }
  
  /// 处理文件上传
  Future<String?> handleFileUpload(BuildContext context) async {
    if (_isDisposed || !_model.isFileUploadEnabled) return null;
    
    try {
      // 禁用上传按钮，防止重复操作
      _model.setFileUploadEnabled(false);
      
      // 使用SSHFileUploader进行文件上传操作
      final result = await SSHFileUploader.uploadFile(
        context: context,
        sshController: _sshController,
      );
      
      // 重新启用上传按钮
      _model.setFileUploadEnabled(true);
      
      return result;
    } catch (e) {
      // 确保按钮状态恢复
      _model.setFileUploadEnabled(true);
      _showError(context, '文件上传失败: $e');
      return null;
    }
  }
  
  /// 处理文件下载
  Future<Map<String, String>?> handleFileDownload(BuildContext context) async {
    if (_isDisposed || !_model.isFileDownloadEnabled) return null;
    
    try {
      // 禁用下载按钮，防止重复操作
      _model.setFileDownloadEnabled(false);
      
      // 使用SSHFileDownloader进行文件下载操作
      final result = await SSHFileDownloader.downloadFile(
        context: context,
        sshController: _sshController,
      );
      
      // 重新启用下载按钮
      _model.setFileDownloadEnabled(true);
      
      return result;
    } catch (e) {
      // 确保按钮状态恢复
      _model.setFileDownloadEnabled(true);
      _showError(context, '文件下载失败: $e');
      return null;
    }
  }
  
  /// 显示错误消息
  void _showError(BuildContext context, String message) {
    MessageComponentFactory.showError(
      context,
      message: message,
    );
  }
  
  /// 显示成功消息
  void _showSuccess(BuildContext context, String message) {
    MessageComponentFactory.showSuccess(
      context,
      message: message,
    );
  }
  
  /// 获取远程目录内容
  Future<List<String>> getRemoteDirectoryContents(String path) async {
    if (_isDisposed || !_sshController.isConnected) {
      debugPrint('SSHHeaderController.getRemoteDirectoryContents: 未连接到SSH服务器');
      throw SSHException('未连接到SSH服务器');
    }
    
    debugPrint('SSHHeaderController.getRemoteDirectoryContents: 开始获取路径 $path 的内容');
    
    try {
      // 获取SFTP子系统
      final client = _sshController.currentSession?.client;
      if (client == null) {
        throw SSHException('SSH客户端未初始化');
      }
      
      final sftp = await client.sftp();
      debugPrint('SSHHeaderController.getRemoteDirectoryContents: 成功获取SFTP子系统');
      
      // 验证路径是否存在
      try {
        final stat = await sftp.stat(path);
        if (!stat.isDirectory) {
          debugPrint('SSHHeaderController.getRemoteDirectoryContents: 路径不是目录: $path');
          throw SSHException('路径不是目录: $path');
        }
        debugPrint('SSHHeaderController.getRemoteDirectoryContents: 目录存在且有效');
      } catch (e) {
        debugPrint('SSHHeaderController.getRemoteDirectoryContents: 检查目录状态出错: $e');
        if (e is! SSHException) {
          throw SSHException('目录不存在或无法访问: $path ($e)');
        }
        rethrow;
      }
      
      // 读取目录内容 - dartssh2的readdir返回Stream<List<SftpName>>
      final contents = <String>[];
      
      debugPrint('SSHHeaderController.getRemoteDirectoryContents: 开始读取目录内容...');
      await for (final list in sftp.readdir(path)) {
        for (final item in list) {
          final name = item.filename;
          final isDir = item.longname.startsWith('d');
          
          // 忽略当前目录和上级目录标记
          if (name != '.' && name != '..') {
            contents.add('${isDir ? '[目录] ' : '[文件] '}$name');
          }
        }
      }
      
      // 按类型和名称排序：先目录后文件
      contents.sort((a, b) {
        final aIsDir = a.startsWith('[目录]');
        final bIsDir = b.startsWith('[目录]');
        
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        
        return a.compareTo(b);
      });
      
      debugPrint('SSHHeaderController.getRemoteDirectoryContents: 成功获取到${contents.length}个项目');
      return contents;
    } catch (e) {
      debugPrint('SSHHeaderController.getRemoteDirectoryContents 获取远程目录内容失败: $e');
      if (e is SSHException) {
        rethrow; // 保留原始异常
      }
      throw SSHException('获取目录内容失败: $e');
    }
  }
  
  /// 设置页面标题
  void setTitle(String title) {
    if (_isDisposed) return;
    _model.title = title;
  }
  
  /// 检查远程文件是否存在
  Future<bool> doesRemoteFileExist(SftpClient sftp, String path) async {
    try {
      await sftp.stat(path);
      return true;
    } catch (e) {
      // 如果文件不存在，sftp.stat 会抛出异常
      return false;
    }
  }
  
  /// 递归创建目录路径
  /// 因为SFTP不直接支持recursive选项，所以我们手动实现
  Future<void> createDirectoryPath(SftpClient sftp, String path) async {
    // 规范化路径，确保以'/'开头并移除结尾的'/'
    path = path.replaceAll(RegExp(r'/*$'), '');
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    
    // 如果是根目录，直接返回
    if (path == '/' || path.isEmpty) {
      return;
    }
    
    try {
      // 尝试获取目录状态，如果成功则目录已存在
      final stat = await sftp.stat(path);
      if (stat.isDirectory) {
        return; // 目录已存在
      } else {
        throw SSHException('路径存在但不是目录: $path');
      }
    } catch (e) {
      // 目录不存在，创建父目录
      final parentDir = path.substring(0, path.lastIndexOf('/'));
      if (parentDir.isNotEmpty) {
        // 首先确保父目录存在
        await createDirectoryPath(sftp, parentDir);
      }
      
      // 创建当前目录
      try {
        await sftp.mkdir(path);
        debugPrint('成功创建目录: $path');
      } catch (e) {
        // 如果目录已经存在（可能是并发创建），忽略错误
        if (!e.toString().contains('already exists')) {
          throw SSHException('创建目录失败: $path - $e');
        }
      }
    }
  }
  
  /// 验证上传的文件完整性
  Future<bool> verifyUploadedFile(
    SftpClient sftp, 
    String remoteFilePath, 
    int expectedSize
  ) async {
    try {
      // 获取远程文件信息
      final fileAttributes = await sftp.stat(remoteFilePath);
      
      // 检查文件大小是否匹配
      final remoteSize = fileAttributes.size;
      
      if (remoteSize == null) {
        debugPrint('无法获取远程文件大小');
        return false;
      }
      
      // 大小匹配则视为验证通过
      return remoteSize == expectedSize;
    } catch (e) {
      debugPrint('验证上传文件失败: $e');
      return false;
    }
  }
  
  /// 重置控制器状态
  void reset() {
    if (_isDisposed) return;
    _model.reset();
  }
  
  /// 获取当前文件传输
  SSHFileTransferInfo? get currentFileTransfer => _currentFileTransfer;
  
  /// 获取文件传输进度流
  Stream<double> get fileTransferProgressStream => _fileTransferProgressController.stream;
  
  /// 获取文件传输状态流
  Stream<FileTransferState> get fileTransferStateStream => _fileTransferStateController.stream;
  
  /// 是否正在传输文件
  bool get isTransferringFile => _isTransferringFile;
  
  /// 更新文件传输进度
  void updateFileTransferProgress(double progress) {
    if (!_isDisposed && !_fileTransferProgressController.isClosed) {
      _fileTransferProgressController.add(progress);
    }
  }
  
  /// 更新文件传输状态
  void updateFileTransferState(FileTransferState state) {
    if (!_isDisposed && !_fileTransferStateController.isClosed) {
      _fileTransferStateController.add(state);
    }
    
    // 如果传输已完成或失败，重置传输状态
    if (state == FileTransferState.completed || state == FileTransferState.failed) {
      _isTransferringFile = false;
    }
  }
  
  /// 开始文件传输
  void startFileTransfer(SSHFileTransferInfo transferInfo) {
    if (_isDisposed) return;
    
    _currentFileTransfer = transferInfo;
    _isTransferringFile = true;
    updateFileTransferState(FileTransferState.starting);
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // 取消连接状态订阅
    if (_connectionStateSubscription != null) {
      _connectionStateSubscription!.cancel();
      _connectionStateSubscription = null;
    }
    
    // 关闭文件传输相关的流
    try {
      if (!_fileTransferProgressController.isClosed) {
        _fileTransferProgressController.close();
      }
      
      if (!_fileTransferStateController.isClosed) {
        _fileTransferStateController.close();
      }
    } catch (e) {
      debugPrint('关闭文件传输流时出错: $e');
    }
    
    // 清理资源
    _currentFileTransfer = null;
    
    super.dispose();
  }
} 