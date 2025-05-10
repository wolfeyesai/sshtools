// ignore_for_file: unreachable_switch_default, unused_element, unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 资源类型枚举
enum ResourceType {
  cpuTemperature,  // CPU温度
  cpuUsage,        // CPU使用率
  diskTotal,       // 磁盘总容量
  diskUsed,        // 已使用磁盘空间
  diskUsage,       // 磁盘使用率
  memoryTotal,     // 内存总量
  memoryUsed,      // 已使用内存
  memoryUsage,     // 内存使用率
}

/// 资源状态级别
enum StatusLevel {
  normal,   // 正常
  warning,  // 警告
  danger,   // 危险
  unknown,  // 未知
}

/// 资源模型 - 管理系统资源数据
class ResourceModel extends ChangeNotifier {
  // 资源数据
  final Map<ResourceType, double> _resourceValues = {};
  
  // 资源历史数据 - 用于图表显示
  final Map<ResourceType, List<double>> _resourceHistory = {};
  
  // 最大历史记录点数
  final int _maxHistoryPoints = 20;
  
  // Getters
  Map<ResourceType, double> get resourceValues => _resourceValues;
  Map<ResourceType, List<double>> get resourceHistory => _resourceHistory;
  
  // 构造函数
  ResourceModel() {
    // 初始化资源值
    for (var type in ResourceType.values) {
      _resourceValues[type] = 0.0;
      _resourceHistory[type] = [];
    }
  }
  
  // 更新资源值
  void updateResourceValue(ResourceType type, double value) {
    _resourceValues[type] = value;
    
    // 更新历史记录
    final history = _resourceHistory[type]!;
    history.add(value);
    
    // 保持历史记录在最大点数之内
    if (history.length > _maxHistoryPoints) {
      history.removeAt(0);
    }
    
    notifyListeners();
  }
  
  // 批量更新资源值
  void updateResourceValues(Map<ResourceType, double> values) {
    values.forEach((type, value) {
      updateResourceValue(type, value);
    });
  }
  
  // 从JSON更新资源值
  void updateFromJson(Map<String, dynamic> json) {
    final map = <ResourceType, double>{};
    
    _fieldToResourceType.forEach((field, type) {
      if (json.containsKey(field)) {
        final value = double.tryParse(json[field].toString()) ?? 0.0;
        map[type] = value;
      }
    });
    
    updateResourceValues(map);
  }
  
  // 获取资源状态级别
  StatusLevel getStatusLevel(ResourceType type) {
    final value = _resourceValues[type] ?? 0.0;
    
    switch (type) {
      case ResourceType.cpuTemperature:
        if (value < 60.0) return StatusLevel.normal;
        if (value < 80.0) return StatusLevel.warning;
        return StatusLevel.danger;
      case ResourceType.cpuUsage:
        if (value < 50.0) return StatusLevel.normal;
        if (value < 80.0) return StatusLevel.warning;
        return StatusLevel.danger;
      case ResourceType.diskUsage:
        if (value < 70.0) return StatusLevel.normal;
        if (value < 90.0) return StatusLevel.warning;
        return StatusLevel.danger;
      case ResourceType.memoryUsage:
        if (value < 70.0) return StatusLevel.normal;
        if (value < 90.0) return StatusLevel.warning;
        return StatusLevel.danger;
      case ResourceType.diskTotal:
      case ResourceType.diskUsed:
      case ResourceType.memoryTotal:
      case ResourceType.memoryUsed:
        return StatusLevel.normal; // 这些是信息型指标，没有警告级别
      default:
        return StatusLevel.unknown;
    }
  }
  
  // 获取状态颜色
  Color getStatusColor(StatusLevel level) {
    switch (level) {
      case StatusLevel.normal:
        return Colors.green;
      case StatusLevel.warning:
        return Colors.orange;
      case StatusLevel.danger:
        return Colors.red;
      case StatusLevel.unknown:
      default:
        return Colors.grey;
    }
  }
  
  // 获取资源类型名称
  String getResourceTypeName(ResourceType type) {
    switch (type) {
      case ResourceType.cpuTemperature:
        return 'CPU温度';
      case ResourceType.cpuUsage:
        return 'CPU使用率';
      case ResourceType.diskTotal:
        return '磁盘总容量';
      case ResourceType.diskUsed:
        return '已用磁盘';
      case ResourceType.diskUsage:
        return '磁盘使用率';
      case ResourceType.memoryTotal:
        return '内存总量';
      case ResourceType.memoryUsed:
        return '已用内存';
      case ResourceType.memoryUsage:
        return '内存使用率';
      default:
        return '未知';
    }
  }
  
  // 获取状态级别名称
  String getStatusLevelName(StatusLevel level) {
    switch (level) {
      case StatusLevel.normal:
        return '正常';
      case StatusLevel.warning:
        return '警告';
      case StatusLevel.danger:
        return '危险';
      case StatusLevel.unknown:
      default:
        return '未知';
    }
  }
}

// 资源类型到JSON字段名的映射
const Map<ResourceType, String> _resourceTypeToField = {
  ResourceType.cpuTemperature: 'cpuTemperature',
  ResourceType.cpuUsage: 'cpuUsage',
  ResourceType.diskTotal: 'diskTotal',
  ResourceType.diskUsed: 'diskUsed',
  ResourceType.diskUsage: 'diskUsage',
  ResourceType.memoryTotal: 'memoryTotal',
  ResourceType.memoryUsed: 'memoryUsed',
  ResourceType.memoryUsage: 'memoryUsage',
};

// JSON字段名到资源类型的映射
const Map<String, ResourceType> _fieldToResourceType = {
  'cpuTemperature': ResourceType.cpuTemperature,
  'cpuUsage': ResourceType.cpuUsage,
  'diskTotal': ResourceType.diskTotal,
  'diskUsed': ResourceType.diskUsed,
  'diskUsage': ResourceType.diskUsage,
  'memoryTotal': ResourceType.memoryTotal,
  'memoryUsed': ResourceType.memoryUsed,
  'memoryUsage': ResourceType.memoryUsage,
}; 