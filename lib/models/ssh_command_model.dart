import 'package:uuid/uuid.dart';

/// SSH命令类型
enum SSHCommandType {
  general, // 通用命令
  system,  // 系统命令
  network, // 网络命令
  file,    // 文件操作
  custom,  // 自定义类别
}

/// SSH自定义命令模型
class SSHCommandModel {
  /// 命令ID
  final String id;
  
  /// 命令名称
  String name;
  
  /// 命令内容
  String command;
  
  /// 命令描述
  String description;
  
  /// 命令类型
  SSHCommandType type;
  
  /// 是否收藏
  bool isFavorite;
  
  /// 自定义标签
  List<String> tags;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  DateTime updatedAt;
  
  /// 构造函数
  SSHCommandModel({
    String? id,
    required this.name,
    required this.command,
    this.description = '',
    this.type = SSHCommandType.custom,
    this.isFavorite = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    tags = tags ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
  
  /// 从JSON创建命令模型
  factory SSHCommandModel.fromJson(Map<String, dynamic> json) {
    return SSHCommandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String,
      description: json['description'] as String? ?? '',
      type: SSHCommandType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SSHCommandType.custom,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags: json['tags'] != null 
        ? List<String>.from(json['tags']) 
        : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'description': description,
      'type': type.toString(),
      'isFavorite': isFavorite,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// 创建副本
  SSHCommandModel copyWith({
    String? name,
    String? command,
    String? description,
    SSHCommandType? type,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return SSHCommandModel(
      id: id,
      name: name ?? this.name,
      command: command ?? this.command,
      description: description ?? this.description,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 添加标签
  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
    }
  }
  
  /// 移除标签
  void removeTag(String tag) {
    if (tags.contains(tag)) {
      tags.remove(tag);
      updatedAt = DateTime.now();
    }
  }
  
  /// 获取命令类型名称
  String get typeName {
    switch (type) {
      case SSHCommandType.general:
        return '通用命令';
      case SSHCommandType.system:
        return '系统命令';
      case SSHCommandType.network:
        return '网络命令';
      case SSHCommandType.file:
        return '文件操作';
      case SSHCommandType.custom:
        return '自定义';
    }
  }
}

/// 预设SSH命令
class SSHCommandPresets {
  /// 获取预设命令列表
  static List<SSHCommandModel> getPresets() {
    return [
      // 系统命令
      SSHCommandModel(
        name: '系统信息',
        command: 'uname -a',
        description: '显示系统信息',
        type: SSHCommandType.system,
      ),
      SSHCommandModel(
        name: '磁盘空间',
        command: 'df -h',
        description: '显示磁盘空间使用情况',
        type: SSHCommandType.system,
      ),
      SSHCommandModel(
        name: '内存使用',
        command: 'free -h',
        description: '显示内存使用情况',
        type: SSHCommandType.system,
      ),
      SSHCommandModel(
        name: '进程列表',
        command: 'ps aux',
        description: '显示所有运行中的进程',
        type: SSHCommandType.system,
      ),
      
      // 网络命令
      SSHCommandModel(
        name: '网络接口',
        command: 'ifconfig',
        description: '显示网络接口信息',
        type: SSHCommandType.network,
      ),
      SSHCommandModel(
        name: '路由表',
        command: 'route -n',
        description: '显示路由表',
        type: SSHCommandType.network,
      ),
      SSHCommandModel(
        name: '网络连接',
        command: 'netstat -tulpn',
        description: '显示所有网络连接',
        type: SSHCommandType.network,
      ),
      
      // 文件操作
      SSHCommandModel(
        name: '查找文件',
        command: 'find / -name "*.log" 2>/dev/null',
        description: '查找指定扩展名的文件',
        type: SSHCommandType.file,
      ),
      SSHCommandModel(
        name: '文件权限',
        command: 'ls -la',
        description: '显示当前目录的详细信息',
        type: SSHCommandType.file,
      ),
    ];
  }
} 