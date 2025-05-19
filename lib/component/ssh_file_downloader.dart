// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_header_controller.dart';
import '../models/ssh_header_model.dart';
import '../component/message_component.dart';
import '../component/remote_directory_browser.dart';
import '../models/ssh_model.dart';

/// SSH文件下载组件
class SSHFileDownloader {
  /// 从SSH服务器下载文件
  static Future<Map<String, String>?> downloadFile({
    required BuildContext context,
    required SSHController sshController,
  }) async {
    try {
      // 首先选择远程文件
      final String? remoteFilePath = await _selectRemoteFile(
        context: context,
        sshController: sshController,
      );
      
      if (remoteFilePath == null) {
        // 用户取消选择
        MessageComponentFactory.showInfo(
          context,
          message: '已取消文件下载',
        );
        return null;
      }
      
      // 获取文件名称
      final String fileName = remoteFilePath.substring(
        remoteFilePath.lastIndexOf('/') + 1
      );
      
      // 选择本地保存路径
      String? localDirectoryPath = await FilePicker.platform.getDirectoryPath();
      if (localDirectoryPath == null) {
        // 用户取消选择
        MessageComponentFactory.showInfo(
          context,
          message: '已取消文件下载',
        );
        return null;
      }
      
      // 构建完整的本地文件路径
      final String localFilePath = '$localDirectoryPath${Platform.pathSeparator}$fileName';
      
      // 显示开始下载消息
      MessageComponentFactory.showInfo(
        context,
        message: '开始下载文件: $fileName',
      );
      
      // 显示下载进度对话框
      final completer = await _showDownloadProgressDialog(
        context: context,
        fileName: fileName,
        sshController: sshController,
      );
      
      // 获取头部控制器来执行文件下载
      final headerController = SSHHeaderController(
        model: SSHHeaderModel(title: '文件下载'),
        sshController: sshController,
      );
      
      // 下载文件 - 这里直接使用SSHController的接口，因为SSHHeaderController没有直接下载的方法
      // 在实际应用中，应该修改SSHHeaderController添加直接下载方法
      bool success = false;
      Map<String, String>? result;
      
      try {
        // 下载文件并跟踪传输状态 
        final fileInfo = SSHFileTransferInfo(
          localPath: localFilePath,
          remotePath: remoteFilePath,
          state: FileTransferState.starting,
        );
        
        // 通知headerController开始文件传输
        headerController.startFileTransfer(fileInfo);
        
        // 获取SFTP会话并下载文件
        final client = sshController.currentSession?.client;
        if (client != null) {
          final sftp = await client.sftp();
          final remoteFile = await sftp.open(remoteFilePath);
          
          // 获取文件大小
          final stat = await remoteFile.stat();
          final fileSize = stat.size ?? 0;
          
          // 更新状态为正在进行
          headerController.updateFileTransferState(FileTransferState.inProgress);
          
          // 创建本地文件
          final localFile = File(localFilePath);
          final sink = localFile.openWrite(mode: FileMode.writeOnly);
          
          // 读取远程文件
          final allBytes = await remoteFile.readBytes();
          // 添加字节到本地文件
          sink.add(allBytes);
          // 关闭流和文件
          await sink.flush();
          await sink.close();
          await remoteFile.close();
          
          // 验证文件大小
          final localFileSize = await localFile.length();
          success = (localFileSize == fileSize);
          
          if (success) {
            // 更新下载进度为100%
            headerController.updateFileTransferProgress(1.0);
            // 更新状态为已完成
            headerController.updateFileTransferState(FileTransferState.completed);
            
            result = {
              'remotePath': remoteFilePath,
              'localPath': localFilePath,
            };
          } else {
            // 更新状态为失败
            headerController.updateFileTransferState(FileTransferState.failed);
          }
        }
      } catch (e) {
        debugPrint('文件下载错误: $e');
        // 更新状态为失败
        headerController.updateFileTransferState(FileTransferState.failed);
        success = false;
      }
      
      // 关闭进度对话框
      completer.complete();
      
      // 显示下载结果
      if (success) {
        MessageComponentFactory.showSuccess(
          context,
          message: '文件下载成功: $localFilePath',
        );
        
        // 在终端中显示消息 - 使用sendToShellClient替代sendToShell
        if (sshController.isConnected) {
          sshController.sendToShellClient('echo "已下载文件: $remoteFilePath 到本地: $localFilePath"\n');
        }
        
        // 返回远程和本地文件路径
        return result;
      } else {
        MessageComponentFactory.showError(
          context,
          message: '文件下载失败',
        );
        return null;
      }
    } catch (e) {
      MessageComponentFactory.showError(
        context,
        message: '文件下载出错: $e',
      );
      return null;
    }
  }
  
  /// 显示下载进度对话框
  static Future<_ProgressDialogCompleter> _showDownloadProgressDialog({
    required BuildContext context,
    required String fileName,
    required SSHController sshController,
  }) async {
    final completer = _ProgressDialogCompleter();
    
    // 创建临时的SSH头部控制器
    final headerModel = SSHHeaderModel(
      title: '文件下载',
      isConnected: sshController.isConnected,
    );
    
    final headerController = SSHHeaderController(
      model: headerModel,
      sshController: sshController,
    );
    
    // 创建StreamSubscription监听文件传输进度
    final progressSubscription = headerController.fileTransferProgressStream.listen((progress) {
      completer.updateProgress(progress);
    });
    
    // 创建StreamSubscription监听文件传输状态
    final stateSubscription = headerController.fileTransferStateStream.listen((state) {
      if (state == FileTransferState.failed) {
        completer.updateStatus('下载失败');
      } else if (state == FileTransferState.completed) {
        completer.updateStatus('下载完成');
      }
    });
    
    // 在完成时关闭订阅
    completer.onComplete = () {
      progressSubscription.cancel();
      stateSubscription.cancel();
      headerController.dispose(); // 释放临时控制器资源
    };
    
    // 显示对话框
    showDialog(
      context: context,
      barrierDismissible: false, // 阻止用户通过点击外部关闭对话框
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // 阻止返回键关闭
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.download_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('下载文件'),
              ],
            ),
            content: StreamBuilder<double>(
              stream: completer.progressStream,
              initialData: 0.0,
              builder: (context, snapshot) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('文件名: $fileName'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: snapshot.data,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<String>(
                          stream: completer.statusStream,
                          initialData: '正在下载...',
                          builder: (context, statusSnapshot) {
                            return Text(statusSnapshot.data ?? '正在下载...');
                          },
                        ),
                        Text('${(snapshot.data! * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 仅在下载完成或失败时允许关闭对话框
                  if (completer.isCompleted) {
                    Navigator.of(context).pop();
                  }
                },
                child: StreamBuilder<bool>(
                  stream: completer.completedStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data! ? '关闭' : '请稍候...',
                      style: TextStyle(
                        color: snapshot.data! ? Colors.blue : Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    
    return completer;
  }
  
  /// 选择远程文件
  static Future<String?> _selectRemoteFile({
    required BuildContext context,
    required SSHController sshController,
  }) async {
    // 创建一个SSHHeaderController实例
    final headerModel = SSHHeaderModel(
      title: '文件下载',
      isConnected: sshController.isConnected,
    );
    
    final headerController = SSHHeaderController(
      model: headerModel,
      sshController: sshController,
    );
    
    // 首先浏览远程目录选择目标文件所在目录
    final String? selectedDirectory = await RemoteDirectoryBrowser.show(
      context: context,
      sshController: sshController,
      initialPath: '/home',
    );
    
    if (selectedDirectory == null) {
      return null; // 用户取消选择
    }
    
    // 列出该目录下的所有文件
    final List<String> dirContents = await headerController.getRemoteDirectoryContents(selectedDirectory);
    
    // 过滤出文件（非目录）
    final List<String> files = dirContents
        .where((item) => item.startsWith('[文件]'))
        .map((item) => item.replaceFirst('[文件] ', ''))
        .toList();
    
    if (files.isEmpty) {
      // 该目录下没有文件
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('没有文件'),
          content: Text('在 $selectedDirectory 目录下没有找到文件'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return null;
    }
    
    // 让用户选择一个文件
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('选择要下载的文件'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(file),
                onTap: () {
                  // 返回完整文件路径
                  Navigator.of(context).pop('$selectedDirectory/$file');
                },
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
  }
}

/// 进度对话框完成器
class _ProgressDialogCompleter {
  /// 进度控制器
  final _progressController = StreamController<double>();
  
  /// 状态控制器
  final _statusController = StreamController<String>();
  
  /// 完成状态控制器
  final _completedController = StreamController<bool>();
  
  /// 完成回调
  VoidCallback? onComplete;
  
  /// 是否已完成
  bool isCompleted = false;
  
  /// 进度流
  Stream<double> get progressStream => _progressController.stream;
  
  /// 状态流
  Stream<String> get statusStream => _statusController.stream;
  
  /// 完成状态流
  Stream<bool> get completedStream => _completedController.stream;
  
  /// 更新进度
  void updateProgress(double progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }
  
  /// 更新状态
  void updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
  
  /// 标记为完成
  void complete() {
    isCompleted = true;
    if (!_completedController.isClosed) {
      _completedController.add(true);
    }
    
    if (onComplete != null) {
      onComplete!();
    }
    
    // 关闭所有流
    _close();
  }
  
  /// 关闭所有控制器
  void _close() {
    if (!_progressController.isClosed) _progressController.close();
    if (!_statusController.isClosed) _statusController.close();
    if (!_completedController.isClosed) _completedController.close();
  }
  
  /// 释放资源
  void dispose() {
    _close();
    onComplete = null;
  }
} 