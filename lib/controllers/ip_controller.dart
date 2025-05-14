// IP控制器，用于获取本机IP地址信息和扫描SSH设备

// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/ip_model.dart';

/// 网络适配器信息
class NetworkAdapterInfo {
  final String name;
  final String displayName;
  final String ipAddress;
  final bool isActiveAdapter;
  
  NetworkAdapterInfo({
    required this.name,
    required this.displayName,
    required this.ipAddress,
    this.isActiveAdapter = false,
  });
}

/// IP信息控制器
class IPController extends ChangeNotifier {
  /// 网络信息工具
  final NetworkInfo _networkInfo = NetworkInfo();
  
  /// 当前设备IP信息
  IPDeviceModel? _deviceIP;
  
  /// 可用的网络适配器列表
  final List<NetworkAdapterInfo> _networkAdapters = [];
  
  /// 当前选择的网络适配器索引
  int _selectedAdapterIndex = -1;
  
  /// 是否正在加载
  bool _isLoading = true;
  
  /// 状态信息
  String _status = '准备获取IP地址';
  
  /// 扫描到的SSH设备列表
  final List<IPDeviceModel> _scannedSSHDevices = [];
  
  /// 是否正在扫描SSH设备
  bool _isScanning = false;
  
  /// 当前扫描进度 (0-1)
  double _scanProgress = 0.0;
  
  /// 扫描状态信息
  String _scanStatus = '';
  
  /// 获取当前设备IP信息
  IPDeviceModel? get deviceIP => _deviceIP;
  
  /// 获取可用的网络适配器列表
  List<NetworkAdapterInfo> get networkAdapters => List.unmodifiable(_networkAdapters);
  
  /// 获取当前选择的网络适配器索引
  int get selectedAdapterIndex => _selectedAdapterIndex;
  
  /// 获取是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取状态信息
  String get status => _status;
  
  /// 获取扫描到的SSH设备列表
  List<IPDeviceModel> get scannedSSHDevices => List.unmodifiable(_scannedSSHDevices);
  
  /// 获取是否正在扫描SSH设备
  bool get isScanning => _isScanning;
  
  /// 获取当前扫描进度
  double get scanProgress => _scanProgress;
  
  /// 获取扫描状态信息
  String get scanStatus => _scanStatus;

  /// 构造函数
  IPController() {
    // 初始化控制器
    loadNetworkAdapters();
  }
  
  /// 加载所有网络适配器
  Future<void> loadNetworkAdapters() async {
    _isLoading = true;
    _status = '正在检测网络适配器...';
    _networkAdapters.clear();
    notifyListeners();
    
    try {
      // 获取所有网络接口
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      // 优先级：以太网 > WLAN > 其他非本地接口
      List<NetworkAdapterInfo> tempAdapters = [];
      
      // 输出所有网络接口的信息用于调试
      for (var interface in interfaces) {
        debugPrint('网络接口: ${interface.name}');
        for (var addr in interface.addresses) {
          debugPrint('  地址: ${addr.address} (${addr.isLoopback ? "回环" : "非回环"})');
          
          // 跳过回环地址和自动私有IP
          if (!addr.isLoopback && 
              !addr.address.startsWith('169.254') &&
              addr.address != '127.0.0.1') {
            
            // 确定适配器显示名称
            String displayName = interface.name;
            
            // 针对不同类型网络适配器设置更友好的名称
            if (interface.name.toLowerCase().contains('ethernet') || 
                interface.name.toLowerCase().contains('以太网')) {
              displayName = '以太网 (${interface.name})';
            } else if (interface.name.toLowerCase().contains('wi-fi') || 
                       interface.name.toLowerCase().contains('wireless') ||
                       interface.name.toLowerCase().contains('wlan') ||
                       interface.name.toLowerCase().contains('无线')) {
              displayName = '无线网络 (${interface.name})';
            } else if (interface.name.toLowerCase().contains('hyper-v') ||
                       interface.name.toLowerCase().contains('virtual')) {
              displayName = '虚拟网络 (${interface.name})';
            } else {
              displayName = '网络接口 (${interface.name})';
            }
            
            // 添加到适配器列表
            tempAdapters.add(NetworkAdapterInfo(
              name: interface.name,
              displayName: displayName,
              ipAddress: addr.address,
              isActiveAdapter: false, // 默认不激活
            ));
          }
        }
      }
      
      // 对适配器进行排序：以太网 > 无线网络 > 其他
      tempAdapters.sort((a, b) {
        // 优先以太网
        if (a.displayName.contains('以太网') && !b.displayName.contains('以太网')) {
          return -1;
        }
        if (!a.displayName.contains('以太网') && b.displayName.contains('以太网')) {
          return 1;
        }
        
        // 其次无线网络
        if (a.displayName.contains('无线') && !b.displayName.contains('无线')) {
          return -1;
        }
        if (!a.displayName.contains('无线') && b.displayName.contains('无线')) {
          return 1;
        }
        
        // 虚拟网络放最后
        if (a.displayName.contains('虚拟') && !b.displayName.contains('虚拟')) {
          return 1;
        }
        if (!a.displayName.contains('虚拟') && b.displayName.contains('虚拟')) {
          return -1;
        }
        
        // 其他情况按名称排序
        return a.displayName.compareTo(b.displayName);
      });
      
      // 设置第一个适配器为活动适配器
      if (tempAdapters.isNotEmpty) {
        tempAdapters[0] = NetworkAdapterInfo(
          name: tempAdapters[0].name,
          displayName: tempAdapters[0].displayName,
          ipAddress: tempAdapters[0].ipAddress,
          isActiveAdapter: true,
        );
        _selectedAdapterIndex = 0;
      }
      
      // 更新适配器列表
      _networkAdapters.addAll(tempAdapters);
      
      // 如果找到了适配器，加载第一个适配器的IP
      if (_networkAdapters.isNotEmpty) {
        await _loadAdapterIP(_selectedAdapterIndex);
      } else {
        // 没有找到适配器，尝试备用方法
        await loadDeviceIP();
      }
    } catch (e) {
      debugPrint('获取网络适配器列表出错: $e');
      // 出错时使用备用方法
      await loadDeviceIP();
    }
  }
  
  /// 选择特定的网络适配器
  Future<void> selectNetworkAdapter(int index) async {
    if (index < 0 || index >= _networkAdapters.length) {
      return;
    }
    
    _isLoading = true;
    
    // 更新选定适配器
    List<NetworkAdapterInfo> updatedAdapters = [];
    for (int i = 0; i < _networkAdapters.length; i++) {
      updatedAdapters.add(NetworkAdapterInfo(
        name: _networkAdapters[i].name,
        displayName: _networkAdapters[i].displayName,
        ipAddress: _networkAdapters[i].ipAddress,
        isActiveAdapter: (i == index),
      ));
    }
    
    _networkAdapters.clear();
    _networkAdapters.addAll(updatedAdapters);
    _selectedAdapterIndex = index;
    
    notifyListeners();
    
    // 加载选定适配器的IP
    await _loadAdapterIP(index);
  }
  
  /// 加载指定适配器的IP
  Future<void> _loadAdapterIP(int index) async {
    if (index < 0 || index >= _networkAdapters.length) {
      await loadDeviceIP(); // 回退到默认方法
      return;
    }
    
    final adapter = _networkAdapters[index];
    
    _deviceIP = IPDeviceModel(
      ipAddress: adapter.ipAddress,
      type: IPType.localNetwork,
      hostname: adapter.displayName,
      macAddress: '',
    );
    
    _status = '已获取IP地址';
    _isLoading = false;
    notifyListeners();
  }
  
  /// 加载当前设备IP地址（备用方法）
  Future<void> loadDeviceIP() async {
    _isLoading = true;
    _status = '正在获取IP地址...';
    notifyListeners();
    
    try {
      // 延迟一下，确保UI有足够时间显示加载状态
      await Future.delayed(const Duration(milliseconds: 300));
      
      String? ipAddress;
      String? networkName;
      
      // 针对Windows平台优化IP地址获取
      if (Platform.isWindows) {
        // 使用备选方法直接获取IP地址
        final networkInfo = await _getWindowsNetworkInfo();
        ipAddress = networkInfo['ipAddress'];
        networkName = networkInfo['networkName'] ?? '本地网络';
      } else {
        // 尝试从网络信息插件获取WiFi IP地址
        ipAddress = await _networkInfo.getWifiIP();
        networkName = await _networkInfo.getWifiName();
      }
      
      // 如果获取不到IP地址，尝试其他方法获取IP
      if (ipAddress == null || ipAddress.isEmpty) {
        ipAddress = await _getAlternativeIP();
        
        // 如果仍然获取不到，使用备用方法
        if (ipAddress == null || ipAddress.isEmpty) {
          final backupNetworkInfo = await _getBackupNetworkInfo();
          ipAddress = backupNetworkInfo['ipAddress'];
          networkName = backupNetworkInfo['networkName'] ?? networkName;
        }
      }
      
      if (ipAddress != null && ipAddress.isNotEmpty) {
        _deviceIP = IPDeviceModel(
          ipAddress: ipAddress,
          type: IPType.localNetwork,
          hostname: networkName?.replaceAll('"', '') ?? '本机',
          macAddress: '',
        );
        _status = '已获取IP地址';
      } else {
        _status = '未能获取IP地址';
        // 尝试使用本地环回地址作为备选
        _deviceIP = IPDeviceModel(
          ipAddress: '127.0.0.1',
          type: IPType.localNetwork,
          hostname: '本地环回地址',
          macAddress: '',
        );
      }
    } catch (e) {
      _status = '获取IP地址出错: $e';
      // 发生错误时，也使用本地环回地址
      _deviceIP = IPDeviceModel(
        ipAddress: '127.0.0.1',
        type: IPType.localNetwork,
        hostname: '本地环回地址 (发生错误)',
        macAddress: '',
      );
      debugPrint('获取IP详细错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Windows平台专用的网络信息获取方法
  Future<Map<String, String>> _getWindowsNetworkInfo() async {
    try {
      // 检查网络接口
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      // 优先级：以太网 > WLAN > 其他非本地接口
      
      // 首先查找以太网接口
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('ethernet') || 
            interface.name.toLowerCase().contains('以太网') ||
            interface.name.toLowerCase().contains('有线')) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && addr.address != '127.0.0.1') {
              debugPrint('找到以太网IP: ${addr.address} (${interface.name})');
              return {
                'ipAddress': addr.address,
                'networkName': '以太网 (${interface.name})'
              };
            }
          }
        }
      }
      
      // 然后查找无线网络接口
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('wi-fi') || 
            interface.name.toLowerCase().contains('wireless') ||
            interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('无线')) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && addr.address != '127.0.0.1') {
              debugPrint('找到无线网络IP: ${addr.address} (${interface.name})');
              return {
                'ipAddress': addr.address,
                'networkName': '无线网络 (${interface.name})'
              };
            }
          }
        }
      }
      
      // 最后尝试任何非环回接口
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && 
              !addr.address.startsWith('169.254') && // 避免自动私有IP
              addr.address != '127.0.0.1') {
            debugPrint('找到其他网络IP: ${addr.address} (${interface.name})');
            return {
              'ipAddress': addr.address,
              'networkName': '网络接口 (${interface.name})'
            };
          }
        }
      }
    } catch (e) {
      debugPrint('获取Windows网络信息出错: $e');
    }
    
    return {'ipAddress': '', 'networkName': ''};
  }
  
  /// 使用备选方法获取IP地址
  Future<String?> _getAlternativeIP() async {
    try {
      // 尝试通过网络接口获取IP
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      // 输出所有网络接口的信息用于调试
      for (var interface in interfaces) {
        debugPrint('网络接口: ${interface.name}');
        for (var addr in interface.addresses) {
          debugPrint('  地址: ${addr.address} (${addr.isLoopback ? "回环" : "非回环"})');
        }
      }
      
      // 寻找有效的非本地环回IP地址
      for (var interface in interfaces) {
        // 跳过虚拟网络接口等无效接口
        if (interface.name.toLowerCase().contains('virtual') ||
            interface.name.toLowerCase().contains('vmware') ||
            interface.name.toLowerCase().contains('虚拟') ||
            interface.name.toLowerCase().contains('docker')) {
          continue;
        }
        
        for (var addr in interface.addresses) {
          // 排除回环地址和自动私有IP地址
          if (!addr.isLoopback && 
              !addr.address.startsWith('169.254') &&
              addr.address != '127.0.0.1') {
            debugPrint('找到有效IP: ${addr.address} (${interface.name})');
            return addr.address;
          }
        }
      }
      
      // 如果没有找到合适的IP地址，尝试使用网络接口名称为eth或wlan的地址
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') || 
            interface.name.toLowerCase().contains('eth') ||
            interface.name.toLowerCase().contains('en') ||
            interface.name.toLowerCase().contains('wi-fi')) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              debugPrint('通过接口名称找到IP: ${addr.address} (${interface.name})');
              return addr.address;
            }
          }
        }
      }
      
      // 如果仍然没有找到，返回第一个非环回地址
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            debugPrint('回退到备选IP: ${addr.address} (${interface.name})');
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('获取备选IP地址出错: $e');
    }
    
    return null;
  }
  
  /// 备用网络信息获取方法
  Future<Map<String, String>> _getBackupNetworkInfo() async {
    try {
      // 使用命令行获取IP地址
      List<String> output = [];
      
      if (Platform.isWindows) {
        // 在Windows上尝试使用ipconfig命令获取IP
        final result = await Process.run('ipconfig', []);
        final outputText = result.stdout.toString();
        
        // 解析输出以获取IP地址
        final lines = outputText.split('\n');
        String currentAdapter = '';
        for (var line in lines) {
          if (line.contains('适配器') || line.contains('Adapter')) {
            currentAdapter = line.trim();
          } else if ((line.contains('IPv4 地址') || line.contains('IPv4 Address')) && 
                     !line.contains('127.0.0.1') && 
                     !line.contains('169.254')) {
            // 提取IP地址
            final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
            if (ipMatch != null) {
              debugPrint('通过ipconfig找到IP: ${ipMatch.group(1)} ($currentAdapter)');
              return {
                'ipAddress': ipMatch.group(1)!,
                'networkName': currentAdapter.replaceAll(':', '')
              };
            }
          }
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        // 在Linux/MacOS上使用ifconfig或ip命令
        final result = await Process.run('ip', ['addr']);
        final outputText = result.stdout.toString();
        
        // 解析输出以获取IP地址
        final ipMatch = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)').firstMatch(outputText);
        if (ipMatch != null && 
            !ipMatch.group(1)!.startsWith('127.') && 
            !ipMatch.group(1)!.startsWith('169.254')) {
          return {
            'ipAddress': ipMatch.group(1)!,
            'networkName': 'Network Interface'
          };
        }
      }
    } catch (e) {
      debugPrint('获取备用网络信息出错: $e');
    }
    
    return {'ipAddress': '', 'networkName': ''};
  }
  
  /// 刷新IP地址
  Future<void> refreshIP() async {
    await loadNetworkAdapters();
  }
  
  /// 开始扫描网段中的SSH设备
  Future<void> scanSSHDevices() async {
    if (_deviceIP == null || _isScanning) {
      return;
    }
    
    // 提取网段
    final ipParts = _deviceIP!.ipAddress.split('.');
    if (ipParts.length != 4) {
      _scanStatus = 'IP地址格式无效';
      _isScanning = false;
      notifyListeners();
      return;
    }
    
    final subnet = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
    return scanSubnet(subnet);
  }
  
  /// 扫描指定网段
  Future<void> scanSubnet(String subnet) async {
    if (_isScanning) {
      return;
    }
    
    // 检查网段格式
    final subnetParts = subnet.split('.');
    if (subnetParts.length != 3) {
      _scanStatus = '网段格式无效，应为 x.x.x 格式';
      notifyListeners();
      return;
    }
    
    // 检查每一部分是否是有效的数字
    for (final part in subnetParts) {
      try {
        final num = int.parse(part);
        if (num < 0 || num > 255) {
          _scanStatus = '网段数值无效，应为0-255的整数';
          notifyListeners();
          return;
        }
      } catch (e) {
        _scanStatus = '网段格式无效，应为数字';
        notifyListeners();
        return;
      }
    }
    
    // 清空之前的结果
    _scannedSSHDevices.clear();
    _isScanning = true;
    _scanProgress = 0.0;
    _scanStatus = '准备开始扫描...';
    notifyListeners();
    
    try {
      _scanStatus = '正在扫描网段 $subnet.* 上的SSH设备...';
      notifyListeners();
      
      // 扫描1-254范围内的IP
      final totalIPs = 254;
      int scannedCount = 0;
      
      // 使用多个并发任务扫描以加快速度
      const concurrentScans = 20; // 同时扫描20个IP，提高速度
      
      // 批次扫描，每批次 concurrentScans 个IP
      for (int batch = 0; batch < (totalIPs / concurrentScans).ceil(); batch++) {
        final startIdx = batch * concurrentScans + 1;
        final endIdx = (batch + 1) * concurrentScans;
        
        final futures = <Future>[];
        
        for (int i = startIdx; i <= endIdx && i <= 254; i++) {
          final targetIP = '$subnet.$i';
          futures.add(_scanSingleIP(targetIP));
        }
        
        // 等待当前批次完成
        await Future.wait(futures);
        
        // 更新进度
        scannedCount += (endIdx - startIdx + 1);
        if (scannedCount > totalIPs) scannedCount = totalIPs;
        
        _scanProgress = scannedCount / totalIPs;
        _scanStatus = '已扫描 $scannedCount/$totalIPs IP (${(_scanProgress * 100).toStringAsFixed(1)}%)，'
                     '发现 ${_scannedSSHDevices.length} 个SSH设备';
        notifyListeners();
        
        // 检查是否取消扫描
        if (!_isScanning) {
          break;
        }
      }
      
      // if (_isScanning) {
      //   _scanStatus = '扫描完成，共发现 ${_scannedSSHDevices.length} 个SSH设备';
      // }
    } catch (e) {
      _scanStatus = '扫描出错: $e';
    } finally {
      _isScanning = false;
      _scanProgress = 1.0;
      notifyListeners();
    }
  }
  
  /// 扫描单个IP的SSH端口
  Future<void> _scanSingleIP(String ipAddress) async {
    if (!_isScanning) return; // 如果扫描已取消，立即返回
    
    try {
      // 尝试使用Socket连接到SSH端口
      Socket? socket;
      try {
        // SSH默认端口通常是22，减少超时时间加快扫描速度
        socket = await Socket.connect(
          ipAddress, 
          22, 
          timeout: const Duration(milliseconds: 300)
        );
        
        // 成功连接，说明SSH端口是开放的
        // 获取更多设备信息
        final banner = await _readSSHBanner(socket);
        socket.destroy();
        
        // 解析SSH banner获取信息
        final deviceInfo = _parseSSHBanner(banner);
        
        // 添加到已发现设备列表
        final device = IPDeviceModel(
          ipAddress: ipAddress,
          type: IPType.localNetwork,
          hostname: deviceInfo.name.isNotEmpty ? deviceInfo.name : 'SSH-$ipAddress',
          macAddress: '',
          sshInfo: deviceInfo,
        );
        
        _scannedSSHDevices.add(device);
      } catch (e) {
        // 连接失败，忽略
        // 只在调试模式打印错误信息，减少控制台输出
        if (kDebugMode) {
          debugPrint('无法连接到 $ipAddress: $e');
        }
      }
    } catch (e) {
      // 其他错误
      if (kDebugMode) {
        debugPrint('扫描 $ipAddress 出错: $e');
      }
    }
  }
  
  /// 尝试读取SSH banner
  Future<String> _readSSHBanner(Socket socket) async {
    try {
      // 设置超时，避免长时间等待
      final completer = Completer<String>();
      
      // 读取数据
      socket.listen(
        (data) {
          if (!completer.isCompleted) {
            completer.complete(String.fromCharCodes(data).trim());
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.complete('');
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete('');
          }
        },
      );
      
      // 添加超时
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!completer.isCompleted) {
          completer.complete('');
        }
      });
      
      return await completer.future;
    } catch (e) {
      return '';
    }
  }
  
  /// 解析SSH banner获取系统信息
  SSHDeviceInfo _parseSSHBanner(String banner) {
    String name = '';
    String deviceType = '服务器';
    String os = 'Linux';
    
    if (banner.isNotEmpty) {
      // 尝试提取SSH版本和系统信息
      if (banner.toLowerCase().contains('ubuntu')) {
        os = 'Ubuntu';
      } else if (banner.toLowerCase().contains('debian')) {
        os = 'Debian';
      } else if (banner.toLowerCase().contains('centos')) {
        os = 'CentOS';
      } else if (banner.toLowerCase().contains('fedora')) {
        os = 'Fedora';
      } else if (banner.toLowerCase().contains('openssh')) {
        os = 'OpenSSH';
      } else if (banner.toLowerCase().contains('windows')) {
        os = 'Windows';
      } else if (banner.toLowerCase().contains('bred')) {
        os = 'BRED系统';
        deviceType = 'BRED控制器';
      }
      
      // 设置名称
      name = 'SSH设备 ($os)';
    }
    
    return SSHDeviceInfo(
      name: name,
      deviceType: deviceType,
      os: os,
      port: 22,
      status: DeviceStatus.online,
    );
  }
  
  /// 取消扫描
  void cancelScan() {
    if (!_isScanning) return;
    
    _isScanning = false;
    _scanStatus = '扫描已取消';
    notifyListeners();
  }
  
  /// 清除扫描结果
  void clearScanResults() {
    if (_isScanning) return;
    
    _scannedSSHDevices.clear();
    _scanProgress = 0.0;
    _scanStatus = '';
    notifyListeners();
  }
} 