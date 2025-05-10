import 'package:flutter/material.dart';

// SSH设备模型
class SshDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isFavorite;

  SshDevice({
    required this.id, 
    required this.name, 
    required this.host, 
    required this.port,
    required this.username,
    required this.password,
    this.isFavorite = false
  });

  // 用于比较和复制的方法
  SshDevice copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? isFavorite,
  }) {
    return SshDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// SSH设备管理模型
class DeviceModel extends ChangeNotifier {
  List<SshDevice> _devices = [];
  bool _isLoading = false;

  List<SshDevice> get devices => _devices;
  bool get isLoading => _isLoading;

  // 获取收藏的设备
  List<SshDevice> get favoriteDevices => 
      _devices.where((device) => device.isFavorite).toList();

  // 添加新设备
  void addDevice(SshDevice device) {
    _devices.add(device);
    notifyListeners();
  }

  // 更新设备
  void updateDevice(SshDevice updatedDevice) {
    final index = _devices.indexWhere((device) => device.id == updatedDevice.id);
    if (index != -1) {
      _devices[index] = updatedDevice;
      notifyListeners();
    }
  }

  // 删除设备
  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    notifyListeners();
  }

  // 切换设备收藏状态
  void toggleFavorite(String deviceId) {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        isFavorite: !_devices[index].isFavorite
      );
      notifyListeners();
    }
  }

  void setDevices(List<SshDevice> devices) {
    _devices = devices;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 