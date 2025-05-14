// IP模型类，用于存储当前IP地址信息

// ignore_for_file: use_super_parameters

/// IP类型枚举
enum IPType {
  localNetwork,  // 局域网IP
  internet,      // 互联网IP
  unknown        // 未知类型
}

/// 设备状态枚举
enum DeviceStatus {
  online,    // 在线
  offline,   // 离线
  unknown    // 未知状态
}

/// 简化的IP模型
class IPModel {
  /// IP地址
  final String ipAddress;
  
  /// IP类型
  final IPType type;
  
  /// 构造函数
  IPModel({
    required this.ipAddress,
    this.type = IPType.unknown,
  });
  
  /// 从JSON创建
  factory IPModel.fromJson(Map<String, dynamic> json) {
    return IPModel(
      ipAddress: json['ipAddress'] as String? ?? '',
      type: _parseIPType(json['type']),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'type': type.toString().split('.').last,
    };
  }
  
  /// 解析IP类型
  static IPType _parseIPType(dynamic value) {
    if (value == null) return IPType.unknown;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'localnetwork':
          return IPType.localNetwork;
        case 'internet':
          return IPType.internet;
        default:
          return IPType.unknown;
      }
    }
    
    return IPType.unknown;
  }
}

/// SSH设备信息类
class SSHDeviceInfo {
  /// 设备名称
  final String name;
  
  /// 设备类型
  final String deviceType;
  
  /// 操作系统
  final String os;
  
  /// SSH端口
  final int port;
  
  /// 设备状态
  final DeviceStatus status;
  
  /// 构造函数
  SSHDeviceInfo({
    required this.name,
    required this.deviceType,
    required this.os,
    this.port = 22,
    this.status = DeviceStatus.unknown,
  });
  
  /// 从JSON创建
  factory SSHDeviceInfo.fromJson(Map<String, dynamic> json) {
    return SSHDeviceInfo(
      name: json['name'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      os: json['os'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      status: _parseDeviceStatus(json['status']),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'deviceType': deviceType,
      'os': os,
      'port': port,
      'status': status.toString().split('.').last,
    };
  }
  
  /// 解析设备状态
  static DeviceStatus _parseDeviceStatus(dynamic value) {
    if (value == null) return DeviceStatus.unknown;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'online':
          return DeviceStatus.online;
        case 'offline':
          return DeviceStatus.offline;
        default:
          return DeviceStatus.unknown;
      }
    }
    
    return DeviceStatus.unknown;
  }
}

/// IP设备模型，扩展了基本IP模型
class IPDeviceModel extends IPModel {
  /// 主机名
  final String hostname;
  
  /// MAC地址
  final String macAddress;
  
  /// SSH设备信息，如果有的话
  final SSHDeviceInfo? sshInfo;
  
  /// 构造函数
  IPDeviceModel({
    required String ipAddress,
    IPType type = IPType.unknown,
    this.hostname = '',
    this.macAddress = '',
    this.sshInfo,
  }) : super(ipAddress: ipAddress, type: type);
  
  /// 显示名称（优先使用SSH名称，其次是主机名，最后是IP地址）
  String get displayName => sshInfo?.name.isNotEmpty == true 
      ? sshInfo!.name 
      : (hostname.isNotEmpty ? hostname : ipAddress);
  
  /// 从JSON创建
  factory IPDeviceModel.fromJson(Map<String, dynamic> json) {
    return IPDeviceModel(
      ipAddress: json['ipAddress'] as String? ?? '',
      type: IPModel._parseIPType(json['type']),
      hostname: json['hostname'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      sshInfo: json['sshInfo'] != null 
          ? SSHDeviceInfo.fromJson(json['sshInfo'] as Map<String, dynamic>) 
          : null,
    );
  }
  
  /// 转换为JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'hostname': hostname,
      'macAddress': macAddress,
      'sshInfo': sshInfo?.toJson(),
    };
  }
} 