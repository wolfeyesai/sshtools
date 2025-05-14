import 'package:uuid/uuid.dart';

/// SSH保存的会话模型
/// 用于保存SSH会话配置，便于快速连接
class SSHSavedSessionModel {
  /// 会话ID
  final String id;
  
  /// 会话名称
  String name;
  
  /// 主机地址
  String host;
  
  /// 端口
  int port;
  
  /// 用户名
  String username;
  
  /// 密码
  String password;
  
  /// 是否为收藏
  bool isFavorite;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后连接时间
  DateTime lastConnectedAt;
  
  /// 构造函数
  SSHSavedSessionModel({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.password,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    lastConnectedAt = lastConnectedAt ?? DateTime.now();
  
  /// 从JSON创建会话模型
  factory SSHSavedSessionModel.fromJson(Map<String, dynamic> json) {
    return SSHSavedSessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      password: json['password'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastConnectedAt: DateTime.parse(json['lastConnectedAt'] as String),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt.toIso8601String(),
    };
  }
  
  /// 创建副本
  SSHSavedSessionModel copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? isFavorite,
  }) {
    return SSHSavedSessionModel(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      lastConnectedAt: DateTime.now(),
    );
  }
  
  /// 创建会话副本
  SSHSavedSessionModel copy() {
    return SSHSavedSessionModel(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      password: password,
      isFavorite: isFavorite,
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt,
    );
  }
  
  /// 获取会话显示名称
  String get displayName => '$name ($username@$host:$port)';
} 