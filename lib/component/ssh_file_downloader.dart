// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../component/message_component.dart';
import '../component/remote_directory_browser.dart';
import '../models/ssh_model.dart';

/// SSH文件下载组件
class SSHFileDownloader {
  /// 从SSH服务器下载文件
  static Future<void> downloadFile({
    required BuildContext context,
    required SSHController sshController,
    Function(String, String)? onSuccess,
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
        return;
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
        return;
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
      
      // 下载文件
      final success = await sshController.downloadFile(
        remoteFilePath: remoteFilePath,
        localFilePath: localFilePath,
      );
      
      // 关闭进度对话框
      completer.complete();
      
      // 显示下载结果
      if (success) {
        MessageComponentFactory.showSuccess(
          context,
          message: '文件下载成功: $localFilePath',
        );
        
        // 如果定义了成功回调，执行回调
        if (onSuccess != null) {
          onSuccess(remoteFilePath, localFilePath);
        }
      } else {
        MessageComponentFactory.showError(
          context,
          message: '文件下载失败',
        );
      }
    } catch (e) {
      MessageComponentFactory.showError(
        context,
        message: '文件下载出错: $e',
      );
    }
  }
  
  /// 显示下载进度对话框
  static Future<_ProgressDialogCompleter> _showDownloadProgressDialog({
    required BuildContext context,
    required String fileName,
    required SSHController sshController,
  }) async {
    final completer = _ProgressDialogCompleter();
    
    // 创建StreamSubscription监听文件传输进度
    final progressSubscription = sshController.fileTransferProgressStream.listen((progress) {
      completer.updateProgress(progress);
    });
    
    // 创建StreamSubscription监听文件传输状态
    final stateSubscription = sshController.fileTransferStateStream.listen((state) {
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
    final List<String> dirContents = await sshController.getRemoteDirectoryContents(selectedDirectory);
    
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
    
    // 显示文件选择对话框
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download_rounded, color: Colors.blue),
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
              final fileName = files[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(fileName),
                onTap: () {
                  Navigator.of(context).pop('$selectedDirectory/$fileName');
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

/// 进度对话框控制器
class _ProgressDialogCompleter {
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  bool _isCompleted = false;
  VoidCallback? onComplete;
  
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get completedStream => _completedController.stream;
  bool get isCompleted => _isCompleted;
  
  void updateProgress(double progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }
  
  void updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
  
  void complete() {
    if (!_isCompleted) {
      _isCompleted = true;
      if (!_completedController.isClosed) {
        _completedController.add(true);
      }
      if (onComplete != null) {
        onComplete!();
      }
    }
  }
  
  void dispose() {
    _progressController.close();
    _statusController.close();
    _completedController.close();
  }
} 