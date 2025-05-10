// ignore_for_file: avoid_print

import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

typedef WebsocketMessageCallback = void Function(dynamic message);

/// 注册流控制器需要在哪些页面使用
///
/// 目前分三种类型：
///
/// 1.[loginPage]用户未登录时（用户处于登录相关页面）
/// 2.[mainPage]用户已登录，处于主页及其他登录后的页面下
/// 3.[chatPage]用户处在聊天页面
enum StreamControllerNameEnum {
  loginPage,
  mainPage,
  chatPage;
}

/// WebSocket心跳和轮询工具类
class StreamTool {
  /// 定时轮询方法
  /// [interval] 轮询间隔时间
  /// [callback] 每次轮询执行的回调函数
  /// [count] 轮询次数，默认为无限次
  Stream<String> timedPolling(
      Duration interval, Future<String> Function() callback, int count) {
    return Stream.periodic(interval, (i) => i)
        .take(count)
        .asyncMap((i) => callback());
  }
}

/// WebSocket连接辅助类
class BlWebSocket {
  BlWebSocket();

  static BlWebSocket? singleton;

  factory BlWebSocket.getInstance() => singleton ??= BlWebSocket();

  /// 用于连接websocket的链接uri
  Uri? wsUri;

  /// websocket连接后的对象
  WebSocketChannel? webSocketChannel;

  /// 指定的stream流控制器存放map
  Map<String, BehaviorSubject<String>>? streamControllerList;

  /// 是否开启心跳
  bool isOpenHeartBeat = true;

  /// 用于控制心跳轮询
  StreamSubscription<String>? subscription;

  /// 是否是用户主动触发关闭连接
  bool isDisconnectByUser = false;

  /// 消息回调函数列表，改为List以支持多个回调
  final List<WebsocketMessageCallback> messageCallbacks = [];

  /// 连接断开回调
  Function()? onDone;

  /// 连接出错回调
  Function? onError;

  /// 添加消息回调函数
  void addMessageCallback(WebsocketMessageCallback callback) {
    // 检查回调函数是否已存在
    bool exists = false;
    int hashCode = callback.hashCode;
    
    for (int i = 0; i < messageCallbacks.length; i++) {
      if (identical(messageCallbacks[i], callback)) {
        exists = true;
        print("警告：尝试添加已存在的WebSocket回调函数，引用ID: $hashCode");
        break;
      }
    }
    
    if (!exists) {
      messageCallbacks.add(callback);
      print("成功添加WebSocket消息回调，当前回调总数: ${messageCallbacks.length}，新回调ID: $hashCode");
    } else {
      print("跳过添加重复的WebSocket回调，当前回调总数保持: ${messageCallbacks.length}，尝试添加ID: $hashCode");
    }
  }

  /// 移除消息回调函数
  void removeMessageCallback(WebsocketMessageCallback callback) {
    bool removed = false;
    int hashCode = callback.hashCode;
    int initialCount = messageCallbacks.length;
    
    for (int i = messageCallbacks.length - 1; i >= 0; i--) {
      if (identical(messageCallbacks[i], callback)) {
        messageCallbacks.removeAt(i);
        removed = true;
        print("成功移除WebSocket消息回调，ID: $hashCode，剩余回调数: ${messageCallbacks.length}");
      }
    }
    
    if (!removed) {
      print("警告：尝试移除不存在的WebSocket回调，ID: $hashCode，当前回调数保持: $initialCount");
    }
  }

  /// 兼容旧代码的消息回调设置器
  /// 注意：使用此方法会清除之前的所有回调并只添加一个新回调
  set messageCallback(WebsocketMessageCallback? callback) {
    messageCallbacks.clear();
    if (callback != null) {
      messageCallbacks.add(callback);
      print("使用传统方式设置WebSocket消息回调，当前回调数: 1");
    }
  }

  /// 初始化WebSocket连接
  /// [wsPath] WebSocket服务器地址，例如: ws://localhost:1234
  /// [token] 认证令牌，用于WebSocket连接认证
  /// [isOpenHeartBeat] 是否开启心跳检测，默认为true
  void initSocket({
    required String wsPath, 
    String? token, 
    bool isOpenHeartBeat = true
  }) {
    if (webSocketChannel != null) {
      print("socket实例已存在，请勿重复创建");
      return;
    }

    // 如果提供了token，添加到URL中
    String url = token != null ? "$wsPath?token=$token" : wsPath;
    wsUri = Uri.tryParse(url);
    
    if (wsUri == null) return;
    this.isOpenHeartBeat = isOpenHeartBeat;
    connectWebsocket(isInitField: true);
  }

  /// 建立WebSocket连接
  /// [isInitField] 是否是由初始化触发的此方法
  void connectWebsocket({bool isInitField = false}) {
    try {
      print("正在连接WebSocket: ${wsUri.toString()}");
      webSocketChannel = WebSocketChannel.connect(wsUri!);
      if (!isInitField) {
        isDisconnectByUser = false;
      }
    } catch (e) {
      print("WebSocket连接创建失败: $e");
      // 通知错误回调
      if (onError != null) {
        onError!(e, StackTrace.current);
      }
    }
  }

  /// 监听WebSocket连接
  /// [messageCallback] 消息回调函数
  /// [onDone] 连接断开回调
  /// [onError] 连接错误回调
  void listen({
    WebsocketMessageCallback? messageCallback,
    Function()? onDone,
    Function? onError
  }) {
    if (webSocketChannel == null) {
      return;
    }
    
    // 如果传入了消息回调，添加到回调列表
    if (messageCallback != null) {
      addMessageCallback(messageCallback);
    }
    
    this.onDone = onDone;
    this.onError = onError;
    
    streamControllerList ??= <String, BehaviorSubject<String>>{};

    // 监听WebSocket消息
    webSocketChannel?.stream.listen(
      (message) {
        print("websocket收到消息: ${message.toString()}, 类型: ${message.runtimeType}");
        
        if (message is String && message.isEmpty) {
          // 空消息处理（如心跳回应）
          return;
        }
        
        // 分发消息到各个注册的流控制器
        streamControllerList?.forEach((key, value) {
          if (!value.isClosed) {
            value.sink.add(message);
          }
        });
        
        // 调用所有注册的消息回调
        for (var callback in messageCallbacks) {
          try {
            callback(message);
          } catch (e) {
            print("WebSocket消息回调执行出错: $e");
          }
        }
      }, 
      onDone: () {
        print("websocket连接已关闭");
        this.onDone?.call();
        // 掉线重连
        reConnect();
      }, 
      onError: (Object error, StackTrace stackTrace) {
        print("websocket错误: ${error.toString()}, 堆栈: ${stackTrace.toString()}");
        showToast(msg: "连接服务器失败!");
        this.onError?.call(error, stackTrace);
      }, 
      cancelOnError: false
    );
    
    // 连接建立成功后的处理
    webSocketChannel?.ready.then((value) {
      print("websocket连接已就绪");
      isDisconnectByUser = false;
      if (isOpenHeartBeat) {
        // 开始执行心跳操作
        startHeartBeat();
      }
    });
  }

  /// 显示提示消息
  void showToast({required String msg}) {
    print("[Toast] $msg");
    // 实际项目中，替换为真实的Toast显示实现
  }

  /// 断线重连
  void reConnect() {
    if (isDisconnectByUser) return;
    
    try {
      print("准备进行WebSocket重连，10秒后尝试...");
      Future.delayed(
        const Duration(seconds: 10),
        () {
          try {
            subscription?.cancel();
            subscription = null;
            
            // 安全关闭现有连接
            try {
              webSocketChannel?.sink.close(status.abnormalClosure, "掉线重连");
            } catch (e) {
              print("关闭旧WebSocket连接出错: $e");
            }
            
            webSocketChannel = null;
            
            // 检查URI是否有效
            if (wsUri == null) {
              print("重连失败: WebSocket URI为空");
              return;
            }
            
            print("正在重新连接到: ${wsUri.toString()}");
            connectWebsocket(isInitField: true);
            
            // 重新注册监听
            listen(
              onDone: onDone, 
              onError: onError
            );
            
            print("WebSocket重连完成");
          } catch (e) {
            print("WebSocket重连过程中出错: $e");
          }
        },
      );
    } catch (e) {
      print("安排WebSocket重连时出错: $e");
    }
  }

  /// 发送消息
  /// [message] 要发送的消息内容
  /// [needDisplayMsg] 是否需要在本地显示发送的消息，默认为true
  void sendMessage({required String message, bool needDisplayMsg = true}) {
    print("发送消息: $message");
    
    if (needDisplayMsg) {
      streamControllerList?.forEach((key, value) {
        if (!value.isClosed) {
          value.sink.add(message);
        }
      });
    }

    webSocketChannel?.sink.add(message);
  }

  /// 开启心跳检测
  void startHeartBeat() {
    if (subscription != null) {
      print("心跳检测已开启，无需重复开启");
      return;
    }
    
    Future.delayed(
      const Duration(seconds: 30),
      () {
        var pollingStream = StreamTool().timedPolling(
            const Duration(seconds: 30), () => Future(() => ""), 100000000);
        
        // 监听轮询流，发送心跳包
        subscription = pollingStream.listen((result) {
          sendMessage(message: "heart beat", needDisplayMsg: false);
        });
      },
    );
  }

  /// 断开连接并释放资源
  /// [isDisconnectByUser] 是否由用户主动断开连接，默认为false
  void disconnect({bool isDisconnectByUser = false}) {
    this.isDisconnectByUser = isDisconnectByUser;
    
    subscription?.cancel();
    subscription = null;
    
    streamControllerList?.forEach((key, value) {
      value.close();
    });
    streamControllerList?.clear();
    
    // 清空消息回调列表
    messageCallbacks.clear();
    
    webSocketChannel?.sink.close(status.normalClosure, "用户主动断开连接");
    webSocketChannel = null;
  }

  /// 为指定场景创建Stream控制器
  /// [streamControllerName] 流控制器名称枚举
  void setNewStreamController(StreamControllerNameEnum streamControllerName) {
    if (streamControllerList?.containsKey(streamControllerName.name) ?? false) {
      streamControllerList?[streamControllerName.name]?.close();
    }
    streamControllerList?[streamControllerName.name] = BehaviorSubject();
  }

  /// 获取指定场景的Stream
  /// [streamControllerName] 流控制器名称枚举
  /// 返回对应的消息流，如果不存在则返回null
  Stream<String>? getStream(StreamControllerNameEnum streamControllerName) {
    return streamControllerList?[streamControllerName.name]?.stream;
  }

  /// 检查WebSocket是否已连接
  bool isConnected() {
    return webSocketChannel != null;
  }
}
