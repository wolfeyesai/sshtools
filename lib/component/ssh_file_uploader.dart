// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../component/message_component.dart';
import '../component/remote_directory_browser.dart';
import '../models/ssh_model.dart';

/// SSH文件上传组件
class SSHFileUploader {
  /// 上传文件到SSH服务器
  static Future<void> uploadFile({
    required BuildContext context,
    required SSHController sshController,
    Function(String)? onSuccess,
  }) async {
    try {
      // 使用文件选择器选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileName = result.files.single.name;
        final File file = File(filePath);
        
        // 显示开始上传消息
        MessageComponentFactory.showInfo(
          context,
          message: '开始上传文件: $fileName',
        );
        
        // 显示上传目标路径对话框
        final String? remoteFilePath = await _showRemotePathDialog(
          context: context,
          sshController: sshController,
          fileName: fileName,
        );
        
        if (remoteFilePath == null) {
          // 用户取消上传
          MessageComponentFactory.showInfo(
            context,
            message: '已取消文件上传',
          );
          return;
        }
        
        // 显示上传进度对话框
        final completer = await _showUploadProgressDialog(
          context: context,
          fileName: fileName,
          sshController: sshController,
        );
        
        // 上传文件
        final success = await sshController.uploadFile(
          localFile: file,
          remoteFilePath: remoteFilePath,
        );
        
        // 关闭进度对话框
        completer.complete();
        
        // 显示上传结果
        if (success) {
          MessageComponentFactory.showSuccess(
            context,
            message: '文件上传成功: $remoteFilePath',
          );
          
          // 如果定义了成功回调，执行回调
          if (onSuccess != null) {
            onSuccess(remoteFilePath);
          }
        } else {
          MessageComponentFactory.showError(
            context,
            message: '文件上传失败',
          );
        }
      } else {
        // 用户未选择文件
        MessageComponentFactory.showInfo(
          context,
          message: '未选择任何文件',
        );
      }
    } catch (e) {
      MessageComponentFactory.showError(
        context,
        message: '文件上传出错: $e',
      );
    }
  }
  
  /// 显示上传进度对话框
  static Future<_ProgressDialogCompleter> _showUploadProgressDialog({
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
        completer.updateStatus('上传失败');
      } else if (state == FileTransferState.completed) {
        completer.updateStatus('上传完成');
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
                const Icon(Icons.upload_file, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('上传文件'),
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
                          initialData: '正在上传...',
                          builder: (context, statusSnapshot) {
                            return Text(statusSnapshot.data ?? '正在上传...');
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
                  // 仅在上传完成或失败时允许关闭对话框
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
  
  /// 显示远程路径对话框
  static Future<String?> _showRemotePathDialog({
    required BuildContext context,
    required SSHController sshController,
    required String fileName,
  }) async {
    final TextEditingController pathController = TextEditingController();
    
    // 默认路径为/tmp/{fileName}
    pathController.text = '/tmp/$fileName';
    
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('上传文件'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '文件名: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pathController,
                      decoration: const InputDecoration(
                        labelText: '远程路径',
                        hintText: '/tmp/filename',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: '浏览远程目录',
                    onPressed: () async {
                      // 使用远程目录浏览器选择路径
                      final selectedPath = await RemoteDirectoryBrowser.show(
                        context: context,
                        sshController: sshController,
                        initialPath: pathController.text.contains('/')
                            ? pathController.text.substring(0, pathController.text.lastIndexOf('/'))
                            : '/tmp',
                      );
                      
                      if (selectedPath != null) {
                        // 用户选择了目录
                        pathController.text = '$selectedPath/$fileName';
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '提示: 请确保该路径可写入',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(pathController.text.trim());
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('确定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } finally {
      pathController.dispose();
    }
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