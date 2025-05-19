// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use, unused_import, unused_local_variable

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/ssh_header_controller.dart'; 
import '../models/ssh_header_model.dart';
import '../component/message_component.dart';
import '../component/remote_directory_browser.dart';
import '../component/ssh_multi_terminal.dart';
import '../models/ssh_model.dart';
import 'package:dartssh2/dartssh2.dart';

/// SSH文件上传组件
class SSHFileUploader {
  // 全局进度跟踪器 - 保持在页面切换之间的上传状态
  static final Map<String, _UploadTask> _activeUploads = <String, _UploadTask>{};
  
  /// 上传文件到SSH服务器
  static Future<String?> uploadFile({
    required BuildContext context,
    required SSHController sshController,
  }) async {
    try {
      // 尝试使用全局活动控制器（如果存在并已连接）
      final activeController = SSHMultiTerminal.getCurrentController();
      if (activeController != null && activeController.isConnected) {
        debugPrint('SSHFileUploader: 使用全局活动控制器替代传入的控制器');
        sshController = activeController;
      } else {
        debugPrint('SSHFileUploader: 使用传入的SSH控制器');
      }
      
      // 使用文件选择器选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileName = result.files.single.name;
        final File file = File(filePath);
        
        // 显示远程目标路径对话框
        final String? remoteFilePath = await _showRemotePathDialog(
          context: context,
          sshController: sshController,
          fileName: fileName,
        );
        
        if (remoteFilePath == null) {
          // 用户取消上传
          return null;
        }
        
        // 生成唯一任务ID
        final taskId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // 创建上传任务
        final uploadTask = _UploadTask(
          taskId: taskId,
          fileName: fileName,
          localFile: file,
          remoteFilePath: remoteFilePath,
          sshController: sshController,
        );
        
        // 添加到活跃上传列表
        _activeUploads[taskId] = uploadTask;
        
        // 显示上传进度对话框
        final completer = await _showUploadProgressDialog(
          context: context,
          taskId: taskId,
          fileName: fileName,
          sshController: sshController,
        );
        
        // 开始上传 - 在单独的隔离区执行，不阻塞UI
        uploadTask.start().then((_) {
          // 上传结束后（成功或失败），关闭进度对话框
          if (completer.isCompleted == false) {
            completer.complete();
          }
          
          // 从活跃上传列表中移除
          _activeUploads.remove(taskId);
          
          // 如果上下文还有效，显示结果消息
          if (uploadTask.success && context.mounted) {
            // 如果对话框仍然打开，先关闭对话框
            Navigator.of(context).popUntil((route) => route is! DialogRoute);
            
            // 显示成功消息
            MessageComponentFactory.showSuccess(
              context,
              message: '文件上传成功: $remoteFilePath',
            );
            
            // 在终端中显示文件信息 - 修改为使用sendToShellClient
            if (sshController.isConnected) {
              sshController.sendToShellClient('ls -la $remoteFilePath\n');
            }
            
            // 返回远程文件路径
            return remoteFilePath;
          } else if (!uploadTask.success && context.mounted) {
            MessageComponentFactory.showError(
              context,
              message: '文件上传失败: ${uploadTask.errorMessage}',
            );
          }
          
          return null;
        });
        
        // 返回远程文件路径，以便调用者可以使用
        return remoteFilePath;
      } else {
        // 用户未选择文件
        return null;
      }
    } catch (e) {
      MessageComponentFactory.showError(
        context,
        message: '文件上传出错: $e',
      );
      return null;
    }
  }
  
  /// 获取活跃上传任务
  static _UploadTask? getUploadTask(String taskId) {
    return _activeUploads[taskId];
  }
  
  /// 显示上传进度对话框
  static Future<_ProgressDialogCompleter> _showUploadProgressDialog({
    required BuildContext context,
    required String taskId,
    required String fileName,
    required SSHController sshController,
  }) async {
    final completer = _ProgressDialogCompleter();
    
    // 获取上传任务
    final uploadTask = _activeUploads[taskId];
    if (uploadTask == null) {
      completer.complete();
      return completer;
    }
    
    // 监听进度变化
    uploadTask.progressStream.listen((progress) {
      completer.updateProgress(progress);
    });
    
    // 监听状态变化
    uploadTask.statusStream.listen((status) {
      completer.updateStatus(status);
      if (status == '上传完成' || status.contains('失败')) {
        // 如果上传完成或失败，更新完成状态
        completer.complete();
      }
    });
    
    // 显示对话框
    showDialog(
      context: context,
      barrierDismissible: false, // 阻止用户通过点击外部关闭对话框
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            // 允许用户关闭对话框，但上传会继续在后台进行
            if (!completer.isCompleted) {
              // 显示后台上传提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('上传将在后台继续进行'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return true;
          },
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
                  Navigator.of(context).pop();
                  // 提示后台上传将继续
                  if (!completer.isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('上传将在后台继续进行'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: StreamBuilder<bool>(
                  stream: completer.completedStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data! ? '关闭' : '转到后台',
                      style: TextStyle(
                        color: Colors.blue,
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
  
  /// 显示远程路径对话框，让用户选择上传文件的目标路径
  static Future<String?> _showRemotePathDialog({
    required BuildContext context,
    required SSHController sshController,
    required String fileName,
  }) async {
    // 创建一个SSHHeaderController实例
    final headerModel = SSHHeaderModel(
      title: '文件上传',
      isConnected: sshController.isConnected,
    );
    
    final headerController = SSHHeaderController(
      model: headerModel,
      sshController: sshController,
    );
    
    String? selectedDirectory = await RemoteDirectoryBrowser.show(
      context: context,
      sshController: sshController,
      initialPath: '/home',
    );
    
    if (selectedDirectory == null) {
      return null; // 用户取消选择
    }
    
    // 确保路径末尾有斜杠
    if (!selectedDirectory.endsWith('/')) {
      selectedDirectory += '/';
    }
    
    // 默认远程文件路径
    String defaultRemotePath = '$selectedDirectory$fileName';
    
    // 让用户编辑路径
    return await showDialog<String>(
      context: context,
      builder: (context) {
        // 使用文本控制器保存编辑值
        final textController = TextEditingController(text: defaultRemotePath);
        
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('设置上传路径'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入要上传到的远程文件路径:'),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例如: /home/user/files/example.txt',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final remotePath = textController.text.trim();
                if (remotePath.isNotEmpty) {
                  Navigator.of(context).pop(remotePath);
                } else {
                  // 如果路径为空，显示错误信息
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的远程文件路径'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

/// 上传任务
class _UploadTask {
  final String taskId;
  final String fileName;
  final File localFile;
  final String remoteFilePath;
  final SSHController sshController;
  final SSHHeaderController headerController;
  
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  
  bool _success = false;
  String _errorMessage = '';
  
  _UploadTask({
    required this.taskId,
    required this.fileName,
    required this.localFile,
    required this.remoteFilePath,
    required this.sshController,
  }) : headerController = SSHHeaderController(
         model: SSHHeaderModel(
           title: '文件上传',
           isConnected: sshController.isConnected
         ),
         sshController: sshController,
       );
  
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  bool get success => _success;
  String get errorMessage => _errorMessage;
  
  Future<void> start() async {
    try {
      _updateStatus('开始上传...');
      
      // 获取SFTP子系统
      if (sshController.currentSession?.client == null) {
        throw SSHException('SSH客户端未连接');
      }
      
      final client = sshController.currentSession!.client!;
      final sftp = await client.sftp();
      
      // 检查远程文件是否存在
      bool fileExists = false;
      try {
        await sftp.stat(remoteFilePath);
        fileExists = true;
        _updateStatus('远程文件已存在，将覆盖');
      } catch (e) {
        // 文件不存在，这是正常的
        _updateStatus('创建新文件');
      }
      
      // 获取本地文件大小
      final fileSize = await localFile.length();
      if (fileSize <= 0) {
        throw SSHException('文件为空');
      }
      
      // 打开远程文件进行写入
      SftpFile? remoteFile;
      try {
        remoteFile = await sftp.open(
          remoteFilePath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
        );
      } catch (e) {
        // 尝试创建父目录
        final parentDir = remoteFilePath.substring(0, remoteFilePath.lastIndexOf('/'));
        if (parentDir.isNotEmpty) {
          _updateStatus('创建目录: $parentDir');
          
          // 递归创建目录 - 使用headerController
          await headerController.createDirectoryPath(sftp, parentDir);
          
          // 再次尝试打开文件
          remoteFile = await sftp.open(
            remoteFilePath,
            mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
          );
        }
      }
      
      if (remoteFile == null) {
        throw SSHException('无法打开远程文件');
      }
      
      // 创建进度计数器
      int bytesSent = 0;
      final controller = StreamController<int>();
      controller.stream.listen((newBytes) {
        bytesSent += newBytes;
        final progress = bytesSent / fileSize;
        _updateProgress(progress);
        // 同时更新headerController的进度
        headerController.updateFileTransferProgress(progress);
      });
      
      _updateStatus('上传中...');
      // 更新headerController的状态
      headerController.updateFileTransferState(FileTransferState.inProgress);
      
      // 创建一个进度跟踪的数据流
      final progressStream = localFile.openRead().transform(
        StreamTransformer<List<int>, Uint8List>.fromHandlers(
          handleData: (data, sink) {
            controller.add(data.length);
            sink.add(Uint8List.fromList(data));
          },
          handleDone: (sink) {
            controller.close();
            sink.close();
          },
          handleError: (error, stackTrace, sink) {
            controller.addError(error, stackTrace);
            sink.addError(error, stackTrace);
          },
        ),
      );
      
      // 写入文件
      await remoteFile.write(progressStream);
      
      // 关闭远程文件
      await remoteFile.close();
      
      // 验证上传是否成功
      final stat = await sftp.stat(remoteFilePath);
      final remoteSize = stat.size ?? 0;
      
      if (remoteSize == fileSize) {
        _success = true;
        _updateStatus('上传完成');
        _updateProgress(1.0);
        // 更新headerController状态为完成
        headerController.updateFileTransferState(FileTransferState.completed);
      } else {
        _success = false;
        _errorMessage = '文件大小不匹配';
        _updateStatus('上传失败: 文件大小不匹配');
        // 更新headerController状态为失败
        headerController.updateFileTransferState(FileTransferState.failed);
      }
    } catch (e) {
      _success = false;
      _errorMessage = e.toString();
      _updateStatus('上传失败: $e');
      _updateProgress(0.0);
      // 更新headerController状态为失败
      headerController.updateFileTransferState(FileTransferState.failed);
    }
  }
  
  void _updateProgress(double progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }
  
  void _updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
  
  void dispose() {
    if (!_progressController.isClosed) _progressController.close();
    if (!_statusController.isClosed) _statusController.close();
    headerController.dispose(); // 释放页头控制器资源
  }
}

/// 进度对话框控制器
class _ProgressDialogCompleter {
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  bool _isCompleted = false;
  
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
    }
  }
  
  void dispose() {
    _progressController.close();
    _statusController.close();
    _completedController.close();
  }
} 