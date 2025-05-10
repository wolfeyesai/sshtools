// ignore_for_file: use_super_parameters, library_private_types_in_public_api, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import '../controllers/data_collection_controller.dart';
import 'package:provider/provider.dart';

/// 数据收集设置屏幕
class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({super.key});

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  @override
  Widget build(BuildContext context) {
    // 使用Consumer获取DataCollectionController并监听其变化
    return Consumer<DataCollectionController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('数据收集设置'),
            actions: [
              // 保存按钮
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => controller.saveSettings(context),
                tooltip: '保存设置',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和说明
                const Text(
                  '数据收集参数设置',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '配置数据收集的频率和类型，用于性能分析和系统优化。',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                
                // 数据收集开关卡片
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('数据收集设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // 启用数据收集开关
                        SwitchListTile(
                          title: const Text('启用数据收集'),
                          subtitle: const Text('开启后将收集游戏性能和用户操作数据'),
                          value: controller.isEnabled,
                          onChanged: (value) {
                            controller.isEnabled = value;
                            controller.notifyListeners();
                          },
                        ),
                        
                        // 分割线
                        const Divider(),
                        
                        // 只在启用数据收集时显示下列选项
                        if (controller.isEnabled) ...[
                          // 收集频率滑块
                          _buildParameterSlider(
                            label: '收集频率 (Hz)',
                            description: '数据收集的频率，越高精度越好但消耗资源越多',
                            value: controller.sampleRate.toDouble(),
                            min: 1.0,
                            max: 60.0,
                            divisions: 59,
                            onChanged: (value) => controller.sampleRate = value.toInt(),
                            valueDisplay: '${controller.sampleRate} Hz',
                          ),
                          
                          // 收集类型多选框
                          const Text('收集数据类型', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          CheckboxListTile(
                            title: const Text('性能数据'),
                            subtitle: const Text('FPS、延迟和资源使用情况'),
                            value: controller.collectPerformance,
                            onChanged: (value) {
                              if (value != null) {
                                controller.collectPerformance = value;
                                controller.notifyListeners();
                              }
                            },
                          ),
                          
                          CheckboxListTile(
                            title: const Text('用户输入'),
                            subtitle: const Text('鼠标、键盘操作和设置变更'),
                            value: controller.collectUserInput,
                            onChanged: (value) {
                              if (value != null) {
                                controller.collectUserInput = value;
                                controller.notifyListeners();
                              }
                            },
                          ),
                          
                          CheckboxListTile(
                            title: const Text('游戏事件'),
                            subtitle: const Text('开火、命中和游戏状态变化'),
                            value: controller.collectGameEvents,
                            onChanged: (value) {
                              if (value != null) {
                                controller.collectGameEvents = value;
                                controller.notifyListeners();
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 数据存储卡片
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('数据存储设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // 数据保留时间滑块
                        _buildParameterSlider(
                          label: '数据保留天数',
                          description: '收集的数据将在指定天数后自动删除',
                          value: controller.dataRetentionDays.toDouble(),
                          min: 1.0,
                          max: 90.0,
                          divisions: 89,
                          onChanged: (value) => controller.dataRetentionDays = value.toInt(),
                          valueDisplay: '${controller.dataRetentionDays} 天',
                        ),
                        
                        // 自动上传开关
                        SwitchListTile(
                          title: const Text('自动上传数据'),
                          subtitle: const Text('定期将收集的数据上传到服务器'),
                          value: controller.autoUpload,
                          onChanged: (value) {
                            controller.autoUpload = value;
                            controller.notifyListeners();
                          },
                        ),
                        
                        // 上传频率下拉菜单(只在自动上传开启时显示)
                        if (controller.autoUpload) 
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: '上传频率',
                                border: OutlineInputBorder(),
                              ),
                              value: controller.uploadFrequency,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  controller.uploadFrequency = newValue;
                                  controller.notifyListeners();
                                }
                              },
                              items: <String>['实时', '每小时', '每天', '每周']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 清除数据按钮
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('清除所有数据'),
                      onPressed: () => _showClearDataDialog(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    
                    // 重置按钮
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置为默认值'),
                      onPressed: () => controller.resetToDefaults(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// 构建单个参数的滑块控件
  Widget _buildParameterSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: min,
                max: max,
                divisions: divisions,
                value: value,
                onChanged: onChanged,
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                valueDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  /// 显示清除数据确认对话框
  void _showClearDataDialog(BuildContext context, DataCollectionController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认清除数据'),
          content: const Text('所有收集的数据将被永久删除。此操作无法撤销，确定要继续吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确认清除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有数据已清除')),
                );
              },
            ),
          ],
        );
      },
    );
  }
} 