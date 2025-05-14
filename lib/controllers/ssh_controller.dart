// SSH控制器，用于管理SSH连接和操作

// ignore_for_file: unused_import, unused_local_variable, unnecessary_import, use_build_context_synchronously, await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ssh_model.dart';
import 'ssh_session_controller.dart';

/// SSH控制器
class SSHController extends ChangeNotifier {
  /// 当前会话模型
  SSHSessionModel? _currentSession;
  
  /// 文件传输信息
  SSHFileTransferInfo? _currentFileTransfer;
  
  /// 连接状态监听器
  final _connectionStateController = StreamController<SSHConnectionState>.broadcast();
  
  /// 命令输出监听器
  final _commandOutputController = StreamController<String>.broadcast();
  
  /// 文件传输进度监听器
  final _fileTransferProgressController = StreamController<double>.broadcast();
  
  /// 文件传输状态监听器
  final _fileTransferStateController = StreamController<FileTransferState>.broadcast();
  
  /// 是否已销毁
  bool _isDisposed = false;
  
  /// 是否正在处理通知
  bool _isNotifying = false;
  
  /// 最后一次通知时间
  DateTime _lastNotifyTime = DateTime.now();
  
  /// 安全地通知监听器
  void _safeNotifyListeners() {
    // 避免重入和频繁通知
    if (_isDisposed || _isNotifying) return;
    
    // 节流控制，避免短时间内多次通知
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds < 100) {
      // 如果距离上次通知时间小于100毫秒，使用Future.delayed延迟执行
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed) _safeNotifyListeners();
      });
      return;
    }
    
    try {
      _isNotifying = true;
      _lastNotifyTime = now;
      
      // 使用Future.microtask确保在下一帧开始前通知，避免在帧渲染中触发更新
      Future.microtask(() {
        try {
          if (!_isDisposed) {
            notifyListeners();
          }
        } catch (e) {
          debugPrint('SSHController通知监听器执行时出错: $e');
        } finally {
          _isNotifying = false;
        }
      });
    } catch (e) {
      _isNotifying = false;
      debugPrint('SSHController安排通知监听器时出错: $e');
    }
  }
  
  /// 安全地向流发送数据
  void _safeAddToStream<T>(StreamController<T> controller, T data) {
    if (_isDisposed) return;
    
    // 使用Future.microtask确保在当前帧完成后执行流操作
    Future.microtask(() {
      try {
        // 再次检查是否已销毁及流是否关闭
        if (_isDisposed || controller.isClosed) return;
        
        controller.add(data);
      } catch (e) {
        debugPrint('向流发送数据时出错: $e');
      }
    });
  }
  
  /// 获取当前会话
  SSHSessionModel? get currentSession => _currentSession;
  
  /// 获取当前文件传输
  SSHFileTransferInfo? get currentFileTransfer => _currentFileTransfer;
  
  /// 获取连接状态流
  Stream<SSHConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// 获取命令输出流
  Stream<String> get commandOutputStream => _commandOutputController.stream;
  
  /// 获取文件传输进度流
  Stream<double> get fileTransferProgressStream => _fileTransferProgressController.stream;
  
  /// 获取文件传输状态流
  Stream<FileTransferState> get fileTransferStateStream => _fileTransferStateController.stream;
  
  /// 获取当前连接状态
  bool get isConnected => !_isDisposed && (_currentSession?.isConnected ?? false);
  
  /// 连接到SSH服务器
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int timeout = 10,
    BuildContext? context,
  }) async {
    if (_isDisposed) return false;
    
    try {
      // 创建连接配置
      final config = SSHConnectionConfig(
        host: host,
        port: port,
        username: username,
        password: password,
        timeout: timeout,
      );
      
      // 创建会话模型
      final sessionId = const Uuid().v4();
      _currentSession = SSHSessionModel(
        id: sessionId,
        config: config,
        connectionState: SSHConnectionState.connecting,
      );
      
      // 更新连接状态
      _safeAddToStream(_connectionStateController, SSHConnectionState.connecting);
      _safeNotifyListeners();
      
      // 创建SSH客户端
      final socket = await SSHSocket.connect(
        host, 
        port, 
        timeout: Duration(seconds: timeout)
      );
      
      if (_isDisposed) {
        socket.close();
        return false;
      }
      
      // 创建SSH连接
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      if (_isDisposed) {
        client.close();
        return false;
      }
      
      // 更新会话状态
      if (_currentSession != null) {
        _currentSession!.client = client;
        _currentSession!.connectionState = SSHConnectionState.connected;
        _safeAddToStream(_connectionStateController, SSHConnectionState.connected);
        _safeNotifyListeners();
        
        // 记录连接历史
        if (context != null && context.mounted) {
          try {
            final sessionController = Provider.of<SSHSessionController>(
              context, 
              listen: false
            );
            
            sessionController.recordConnection(
              host: host,
              port: port,
              username: username,
              password: password,
            );
          } catch (e) {
            debugPrint('记录SSH连接历史失败: $e');
          }
        }
        
        return true;
      } else {
        client.close();
        return false;
      }
    } catch (e) {
      if (_currentSession != null) {
        _currentSession!.connectionState = SSHConnectionState.failed;
      }
      _safeAddToStream(_connectionStateController, SSHConnectionState.failed);
      debugPrint('SSH连接失败: $e');
      _safeNotifyListeners();
      return false;
    }
  }
  
  /// 执行SSH命令并获取结果
  Future<SSHCommandResult> executeCommand(String command) async {
    if (_isDisposed || !isConnected || _currentSession?.client == null) {
      return SSHCommandResult(
        exitCode: -1,
        output: '',
        error: 'SSH控制器已销毁或未连接',
      );
    }
    
    try {
      // 执行命令
      final process = await _currentSession!.client!.execute(command);
      
      if (_isDisposed) {
        process.close();
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      // 命令输出
      final stdoutBytes = await process.stdout.toList();
      final stderrBytes = await process.stderr.toList();
      
      if (_isDisposed) {
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      final flattenStdout = stdoutBytes.expand((e) => e).toList();
      final flattenStderr = stderrBytes.expand((e) => e).toList();
      
      final stdout = utf8.decode(flattenStdout, allowMalformed: true);
      final stderr = utf8.decode(flattenStderr, allowMalformed: true);
      
      // 等待命令完成
      final exitCode = await process.exitCode;
      
      if (_isDisposed) {
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      // 输出到命令流
      _safeAddToStream(_commandOutputController, stdout);
      
      // 添加到会话历史
      if (_currentSession != null) {
        _currentSession!.addOutput('$command\n$stdout');
        _safeNotifyListeners();
      }
      
      return SSHCommandResult(
        exitCode: exitCode ?? -1,
        output: stdout,
        error: stderr,
      );
    } catch (e) {
      final errorMsg = '执行命令出错: $e';
      _safeAddToStream(_commandOutputController, errorMsg);
      
      // 添加到会话历史
      if (_currentSession != null && !_isDisposed) {
        _currentSession!.addOutput('$command\n$errorMsg');
        _safeNotifyListeners();
      }
      
      return SSHCommandResult(
        exitCode: -1,
        output: '',
        error: e.toString(),
      );
    }
  }
  
  /// 上传文件到远程服务器
  Future<bool> uploadFile({
    required File localFile,
    required String remoteFilePath,
  }) async {
    if (!isConnected || _currentSession?.client == null) {
      throw SSHException('未连接到SSH服务器');
    }
    
    SftpFile? remoteFile;
    
    try {
      // 创建文件传输信息
      _currentFileTransfer = SSHFileTransferInfo(
        localPath: localFile.path,
        remotePath: remoteFilePath,
        state: FileTransferState.starting,
      );
      
      _fileTransferStateController.add(FileTransferState.starting);
      _safeNotifyListeners();
      
      // 获取SFTP子系统
      final sftp = await _currentSession!.client!.sftp();
      
      // 状态更新
      _currentFileTransfer!.state = FileTransferState.inProgress;
      _fileTransferStateController.add(FileTransferState.inProgress);
      _safeNotifyListeners();
      
      // 检查远程文件是否已存在
      try {
        final fileExists = await _doesRemoteFileExist(sftp, remoteFilePath);
        if (fileExists) {
          debugPrint('远程文件已存在，将覆盖: $remoteFilePath');
        }
      } catch (e) {
        // 检查文件存在性时出错，继续上传（可能是权限问题或路径问题）
        debugPrint('检查远程文件存在性时出错: $e');
      }
      
      // 获取文件大小用于进度计算
      final fileSize = await localFile.length();
      
      // 打开远程文件 - 使用标准模式，清空原有内容
      // 使用官方推荐的标志组合：
      // SftpFileOpenMode.create: 如果文件不存在则创建
      // SftpFileOpenMode.write: 允许写入文件
      // SftpFileOpenMode.truncate: 清空文件内容（确保覆盖）
      try {
        remoteFile = await sftp.open(
          remoteFilePath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
        );
      } catch (e) {
        // 尝试创建父目录（如果失败）
        if (e.toString().contains('No such file')) {
          try {
            final parentDir = remoteFilePath.substring(0, remoteFilePath.lastIndexOf('/'));
            if (parentDir.isNotEmpty) {
              // 创建目录，不使用recursive参数（不支持）
              await _createDirectoryPath(sftp, parentDir);
              // 再次尝试打开文件
              remoteFile = await sftp.open(
                remoteFilePath,
                mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
              );
            }
          } catch (dirError) {
            throw SSHException('无法创建父目录: $dirError');
          }
        } else {
          throw SSHException('无法打开远程文件: $e');
        }
      }
      
      // 确保remoteFile已成功初始化
      if (remoteFile == null) {
        throw SSHException('无法打开远程文件进行写入');
      }
      
      // 创建上传进度监听器
      final progressController = StreamController<int>();
      int bytesSent = 0;
      
      // 监听上传进度并更新UI
      progressController.stream.listen((newBytes) {
        bytesSent += newBytes;
        final progress = bytesSent / fileSize;
        
        _currentFileTransfer!.progress = progress;
        _fileTransferProgressController.add(progress);
        _safeNotifyListeners();
      });
      
      // 创建一个转换流，用于跟踪上传进度
      final progressStream = localFile.openRead().transform(
        StreamTransformer<List<int>, Uint8List>.fromHandlers(
          handleData: (data, sink) {
            progressController.add(data.length);
            sink.add(Uint8List.fromList(data));
          },
          handleDone: (sink) {
            progressController.close();
            sink.close();
          },
          handleError: (error, stackTrace, sink) {
            progressController.addError(error, stackTrace);
            sink.addError(error, stackTrace);
          },
        ),
      );
      
      // 使用file.write()方法上传文件，这是官方推荐的方式
      await remoteFile.write(progressStream);
      
      // 关闭远程文件
      await remoteFile.close();
      remoteFile = null;
      
      // 验证上传文件完整性
      bool isFileValid = await _verifyUploadedFile(
        sftp, 
        remoteFilePath, 
        fileSize
      );
      
      if (!isFileValid) {
        throw SSHException('文件上传完成，但完整性校验失败');
      }
      
      // 更新状态
      _currentFileTransfer!.state = FileTransferState.completed;
      _currentFileTransfer!.endTime = DateTime.now();
      _fileTransferStateController.add(FileTransferState.completed);
      _safeNotifyListeners();
      
      return true;
    } catch (e) {
      // 确保关闭远程文件
      if (remoteFile != null) {
        try {
          await remoteFile.close();
        } catch (_) {}
      }
      
      if (_currentFileTransfer != null) {
        _currentFileTransfer!.state = FileTransferState.failed;
        _currentFileTransfer!.errorMessage = e.toString();
        _currentFileTransfer!.endTime = DateTime.now();
      }
      
      _fileTransferStateController.add(FileTransferState.failed);
      debugPrint('文件上传失败: $e');
      _safeNotifyListeners();
      
      return false;
    }
  }
  
  /// 检查远程文件是否存在
  Future<bool> _doesRemoteFileExist(SftpClient sftp, String path) async {
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
  Future<void> _createDirectoryPath(SftpClient sftp, String path) async {
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
        await _createDirectoryPath(sftp, parentDir);
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
  Future<bool> _verifyUploadedFile(
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
  
  /// 下载文件从远程服务器
  Future<bool> downloadFile({
    required String remoteFilePath,
    required String localFilePath,
  }) async {
    if (!isConnected || _currentSession?.client == null) {
      throw SSHException('未连接到SSH服务器');
    }
    
    IOSink? sink;
    SftpFile? remoteFile;
    
    try {
      // 创建文件传输信息
      _currentFileTransfer = SSHFileTransferInfo(
        localPath: localFilePath,
        remotePath: remoteFilePath,
        state: FileTransferState.starting,
      );
      
      _fileTransferStateController.add(FileTransferState.starting);
      _safeNotifyListeners();
      
      // 获取SFTP子系统
      final sftp = await _currentSession!.client!.sftp();
      
      // 打开远程文件
      remoteFile = await sftp.open(remoteFilePath);
      
      // 获取文件大小
      final stat = await remoteFile.stat();
      final fileSize = stat.size ?? 0;
      
      if (fileSize <= 0) {
        throw SSHException('无法确定远程文件大小或文件为空');
      }
      
      // 创建本地文件
      final localFile = File(localFilePath);
      sink = localFile.openWrite(mode: FileMode.writeOnly);
      
      // 状态更新
      _currentFileTransfer!.state = FileTransferState.inProgress;
      _fileTransferStateController.add(FileTransferState.inProgress);
      _safeNotifyListeners();
      
      // 一次性读取远程文件（对于大文件可能有内存问题，但确保数据完整性）
      // 注意：在实际生产环境中，可能需要采用分块读取的方式处理大文件
      final allBytes = await remoteFile.readBytes();
      
      // 计算总大小
      final int totalBytes = allBytes.length;
      int bytesProcessed = 0;
      
      // 分块写入本地文件，以便更新进度
      const int chunkSize = 64 * 1024; // 64KB块
      for (int offset = 0; offset < totalBytes; offset += chunkSize) {
        final int end = (offset + chunkSize < totalBytes) ? offset + chunkSize : totalBytes;
        final chunk = allBytes.sublist(offset, end);
        
        // 写入一块数据
        sink.add(chunk);
        
        // 更新进度
        bytesProcessed = end;
        final progress = bytesProcessed / totalBytes;
        
        _currentFileTransfer!.progress = progress;
        _fileTransferProgressController.add(progress);
        _safeNotifyListeners();
      
        // 小延迟，让UI有时间更新
        await Future.delayed(const Duration(milliseconds: 1));
      }
      
      // 确保数据写入并关闭文件
      await sink.flush();
      await sink.close();
      sink = null;
      
      await remoteFile.close();
      remoteFile = null;
      
      // 验证下载文件完整性
      final localFileSize = await localFile.length();
      if (localFileSize != fileSize) {
        throw SSHException('文件下载完成，但大小不匹配。预期:$fileSize，实际:$localFileSize');
      }
      
      // 更新状态
      _currentFileTransfer!.state = FileTransferState.completed;
      _currentFileTransfer!.endTime = DateTime.now();
      _fileTransferStateController.add(FileTransferState.completed);
      
      // 更新进度为100%
      _currentFileTransfer!.progress = 1.0;
      _fileTransferProgressController.add(1.0);
      
      _safeNotifyListeners();
      
      return true;
    } catch (e) {
      // 确保关闭资源
      if (sink != null) {
        await sink.close();
      }
      
      if (remoteFile != null) {
        try {
          await remoteFile.close();
        } catch (closeError) {
          debugPrint('关闭远程文件出错: $closeError');
        }
      }
      
      // 如果下载失败，删除可能不完整的本地文件
      try {
        final localFile = File(localFilePath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (fileError) {
        debugPrint('删除不完整下载文件出错: $fileError');
      }
      
      if (_currentFileTransfer != null) {
        _currentFileTransfer!.state = FileTransferState.failed;
        _currentFileTransfer!.errorMessage = e.toString();
        _currentFileTransfer!.endTime = DateTime.now();
      }
      
      _fileTransferStateController.add(FileTransferState.failed);
      debugPrint('文件下载失败: $e');
      _safeNotifyListeners();
      
      return false;
    }
  }
  
  /// 创建一个交互式Shell会话
  Future<SSHSession?> startShell() async {
    if (!isConnected || _currentSession?.client == null) {
      throw SSHException('未连接到SSH服务器');
    }
    
    try {
      // 创建带有伪终端的Shell会话
      final session = await _currentSession!.client!.shell();
      
      // 更新会话信息
      _currentSession!.session = session;
      _safeNotifyListeners();
      
      return session;
    } catch (e) {
      debugPrint('启动Shell失败: $e');
      return null;
    }
  }
  
  /// 断开SSH连接
  Future<void> disconnect() async {
    if (_isDisposed) return;
    
    try {
      if (_currentSession?.client != null) {
        _currentSession!.client!.close();
        _currentSession!.client = null;
        _currentSession!.session = null;
        _currentSession!.connectionState = SSHConnectionState.disconnected;
      }
      
      _safeAddToStream(_connectionStateController, SSHConnectionState.disconnected);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('断开SSH连接出错: $e');
    }
  }
  
  /// 发送数据到Shell会话
  void sendToShell(String data) {
    if (_isDisposed) return;
    
    try {
      // 检查会话是否有效并且活跃
      if (_currentSession == null || !_currentSession!.hasActiveSession) {
        debugPrint('无法发送数据：无活动会话');
        return;
      }
      
      // 尝试向会话发送数据
      _currentSession!.session!.stdin.add(utf8.encode(data));
      
      // 如果数据以换行符结尾，认为是一个完整命令，添加到历史
      if (data.endsWith('\n')) {
        final command = data.trim();
        if (command.isNotEmpty) {
          _currentSession!.addCommandToHistory(command);
        }
      }
      
      _currentSession!.lastActivityAt = DateTime.now();
      
      // 使用延迟通知避免频繁更新
      Future.microtask(() {
        if (!_isDisposed) {
          _safeNotifyListeners();
        }
      });
    } catch (e) {
      debugPrint('发送数据到Shell出错: $e');
    }
  }
  
  /// 获取远程目录内容
  Future<List<String>> getRemoteDirectoryContents(String path) async {
    if (!isConnected || _currentSession?.client == null) {
      throw SSHException('未连接到SSH服务器');
    }
    
    try {
      // 获取SFTP子系统
      final sftp = await _currentSession!.client!.sftp();
      
      // 读取目录内容 - dartssh2的readdir返回Stream<List<SftpName>>
      final contents = <String>[];
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
      
      return contents;
    } catch (e) {
      debugPrint('获取远程目录内容失败: $e');
      return [];
    }
  }
  
  /// 清除会话历史
  void clearSessionHistory() {
    if (_isDisposed) return;
    
    if (_currentSession != null) {
      _currentSession!.clearOutputHistory();
      _safeNotifyListeners();
    }
  }
  
  /// 获取命令历史
  List<String> getCommandHistory() {
    if (_isDisposed) return [];
    return _currentSession?.commandHistory ?? [];
  }
  
  /// 清除命令历史
  void clearCommandHistory() {
    if (_isDisposed) return;
    
    if (_currentSession != null) {
      _currentSession!.clearCommandHistory();
      _safeNotifyListeners();
    }
  }
  
  @override
  void dispose() {
    // 标记为已销毁
    _isDisposed = true;
    
    // 断开连接
    try {
      if (_currentSession?.client != null) {
        _currentSession!.client!.close();
        _currentSession!.client = null;
        _currentSession!.session = null;
      }
    } catch (e) {
      debugPrint('断开SSH连接时出错: $e');
    }
    
    // 关闭流控制器
    try {
      if (!_connectionStateController.isClosed) _connectionStateController.close();
      if (!_commandOutputController.isClosed) _commandOutputController.close();
      if (!_fileTransferProgressController.isClosed) _fileTransferProgressController.close();
      if (!_fileTransferStateController.isClosed) _fileTransferStateController.close();
    } catch (e) {
      debugPrint('关闭SSH控制器流时出错: $e');
    }
    
    // 释放资源
    _currentSession = null;
    _currentFileTransfer = null;
    
    super.dispose();
  }
} 