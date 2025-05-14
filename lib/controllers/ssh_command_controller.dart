// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ssh_command_model.dart';
import '../utils/logger.dart';

/// SSH命令控制器
class SSHCommandController extends ChangeNotifier {
  /// 存储键名
  static const String _storageKey = 'ssh_commands';
  
  /// 命令列表
  List<SSHCommandModel> _commands = [];
  
  /// 是否已加载预设
  bool _presetsLoaded = false;
  
  /// 是否正在执行操作
  bool _isBusy = false;
  
  /// 最后一次保存时间
  DateTime? _lastSaveTime;
  
  /// 获取命令列表
  List<SSHCommandModel> get commands => List.unmodifiable(_commands);
  
  /// 获取收藏命令
  List<SSHCommandModel> get favoriteCommands => 
      List.unmodifiable(_commands.where((cmd) => cmd.isFavorite).toList());
  
  /// 获取最后保存时间
  DateTime? get lastSaveTime => _lastSaveTime;
  
  /// 获取命令数量
  int get commandCount => _commands.length;
  
  /// 按类型获取命令
  List<SSHCommandModel> getCommandsByType(SSHCommandType type) {
    try {
      return List.unmodifiable(_commands.where((cmd) => cmd.type == type).toList());
    } catch (e) {
      log.e('SSHCommandController', '获取命令类型错误', e);
      return [];
    }
  }
  
  /// 初始化控制器
  Future<void> init() async {
    if (_isBusy) {
      log.w('SSHCommandController', 'init(): 控制器正忙，跳过初始化');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'init(): 开始初始化命令控制器');
      debugPrint('SSHCommandController.init(): 开始初始化，设置_isBusy=true');
      
      // 确保_isBusy在loadCommands内部处理
      bool success = await _loadCommandsInternal();
      
      // 如果没有命令，加载预设命令
      if (_commands.isEmpty && !_presetsLoaded) {
        log.i('SSHCommandController', 'init(): 命令列表为空，加载预设命令');
        await _loadPresetsInternal();
      }
      
      log.i('SSHCommandController', 'init(): 命令控制器初始化完成，加载了 ${_commands.length} 个命令');
    } catch (e) {
      log.e('SSHCommandController', '初始化SSH命令控制器出错', e);
      debugPrint('SSHCommandController.init(): 初始化出错: $e');
      // 初始化失败时，确保命令列表不为null
      _commands = [];
    } finally {
      _isBusy = false;
      debugPrint('SSHCommandController.init(): 初始化完成，设置_isBusy=false');
    }
  }
  
  /// 内部加载预设命令方法，不受_isBusy标志影响
  Future<bool> _loadPresetsInternal() async {
    try {
      log.i('SSHCommandController', '_loadPresetsInternal(): 加载预设命令');
      final presets = SSHCommandPresets.getPresets();
      _commands.addAll(presets);
      _presetsLoaded = true;
      await _saveCommandsInternal();
      notifyListeners();
      log.i('SSHCommandController', '_loadPresetsInternal(): 预设命令加载完成，共 ${presets.length} 个命令');
      return true;
    } catch (e) {
      log.e('SSHCommandController', '加载预设命令出错', e);
      debugPrint('SSHCommandController._loadPresetsInternal(): 加载预设命令出错: $e');
      return false;
    }
  }
  
  /// 内部加载命令方法，不受_isBusy标志影响
  Future<bool> _loadCommandsInternal() async {
    try {
      log.i('SSHCommandController', '_loadCommandsInternal(): 开始从持久化存储加载命令数据');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      log.d('SSHCommandController', '_loadCommandsInternal(): 从SharedPreferences读取的数据', jsonString);
      debugPrint('SSHCommandController._loadCommandsInternal(): 从存储读取的原始数据长度: ${jsonString?.length ?? 0}');
      
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          debugPrint('SSHCommandController._loadCommandsInternal(): 解析后的JSON列表长度: ${jsonList.length}');
          
          _commands = jsonList
              .map((json) => SSHCommandModel.fromJson(json))
              .toList();
          
          log.i('SSHCommandController', '_loadCommandsInternal(): 成功加载 ${_commands.length} 个命令');
          for (var cmd in _commands) {
            log.d('SSHCommandController', '已加载命令', '${cmd.name}: ${cmd.command}');
            debugPrint('SSHCommandController._loadCommandsInternal(): 加载命令: ${cmd.name}: ${cmd.command}');
          }
          
          notifyListeners();
          return true;
        } catch (e) {
          log.e('SSHCommandController', '解析SSH命令JSON出错', e);
          debugPrint('SSHCommandController._loadCommandsInternal(): 解析SSH命令JSON出错: $e');
          // JSON解析失败，重置命令列表
          _commands = [];
          return false;
        }
      } else {
        log.w('SSHCommandController', '_loadCommandsInternal(): 未找到命令数据或数据为空');
        debugPrint('SSHCommandController._loadCommandsInternal(): 未找到命令数据或数据为空');
        _commands = [];
        return false;
      }
    } catch (e) {
      log.e('SSHCommandController', '加载SSH命令出错', e);
      debugPrint('SSHCommandController._loadCommandsInternal(): 加载SSH命令出错: $e');
      // 加载失败，确保命令列表不为null
      _commands = [];
      return false;
    }
  }
  
  /// 内部保存命令方法，不受_isBusy标志影响
  Future<bool> _saveCommandsInternal() async {
    try {
      if (_commands.isEmpty) {
        // 如果命令列表为空，直接返回
        log.i('SSHCommandController', '_saveCommandsInternal(): 命令列表为空，跳过保存');
        debugPrint('SSHCommandController._saveCommandsInternal(): 命令列表为空，跳过保存');
        return false;
      }
      
      log.i('SSHCommandController', '_saveCommandsInternal(): 开始保存 ${_commands.length} 个命令到持久化存储');
      debugPrint('SSHCommandController._saveCommandsInternal(): 开始保存 ${_commands.length} 个命令到持久化存储');
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _commands.map((cmd) => cmd.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      debugPrint('SSHCommandController._saveCommandsInternal(): 要保存的JSON数据长度: ${jsonString.length}');
      log.d('SSHCommandController', '_saveCommandsInternal(): 要保存的JSON数据', jsonString);
      
      final result = await prefs.setString(_storageKey, jsonString);
      if (result) {
        _lastSaveTime = DateTime.now();
        log.i('SSHCommandController', '_saveCommandsInternal(): 命令数据保存成功');
        debugPrint('SSHCommandController._saveCommandsInternal(): 命令数据保存成功，时间: $_lastSaveTime');
        
        // 验证保存结果
        final savedData = prefs.getString(_storageKey);
        if (savedData != null && savedData.isNotEmpty) {
          debugPrint('SSHCommandController._saveCommandsInternal(): 验证保存结果成功，数据长度: ${savedData.length}');
          return true;
        } else {
          debugPrint('SSHCommandController._saveCommandsInternal(): 警告：验证保存结果失败，无法读取保存的数据');
          return false;
        }
      } else {
        log.e('SSHCommandController', '_saveCommandsInternal(): 命令数据保存失败');
        debugPrint('SSHCommandController._saveCommandsInternal(): 命令数据保存失败');
        return false;
      }
    } catch (e) {
      log.e('SSHCommandController', '保存SSH命令出错', e);
      debugPrint('SSHCommandController._saveCommandsInternal(): 保存SSH命令出错: $e');
      return false;
    }
  }
  
  /// 加载预设命令
  Future<void> _loadPresets() async {
    if (_isBusy) {
      log.w('SSHCommandController', '_loadPresets(): 控制器正忙，跳过加载预设');
      debugPrint('SSHCommandController._loadPresets(): 控制器正忙，使用内部方法尝试加载预设');
      await _loadPresetsInternal();
      return;
    }
    
    _isBusy = true;
    
    try {
      await _loadPresetsInternal();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 从存储加载命令
  Future<void> loadCommands() async {
    if (_isBusy) {
      log.w('SSHCommandController', 'loadCommands(): 控制器正忙，跳过加载');
      debugPrint('SSHCommandController.loadCommands(): 控制器正忙，使用内部方法尝试加载');
      await _loadCommandsInternal();
      return;
    }
    
    _isBusy = true;
    
    try {
      await _loadCommandsInternal();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 保存命令到存储
  Future<void> saveCommands() async {
    if (_isBusy) {
      log.w('SSHCommandController', 'saveCommands(): 控制器正忙，跳过保存');
      debugPrint('SSHCommandController.saveCommands(): 控制器正忙，使用内部方法尝试保存');
      await _saveCommandsInternal();
      return;
    }
    
    _isBusy = true;
    
    try {
      await _saveCommandsInternal();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 重置为预设命令
  Future<void> resetToPresets() async {
    if (_isBusy) {
      log.w('SSHCommandController', 'resetToPresets(): 控制器正忙，跳过重置');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'resetToPresets(): 重置为预设命令');
      _commands.clear();
      await _loadPresetsInternal();
      notifyListeners();
      log.i('SSHCommandController', 'resetToPresets(): 重置完成');
    } catch (e) {
      log.e('SSHCommandController', '重置预设命令出错', e);
      debugPrint('SSHCommandController.resetToPresets(): 重置预设出错: $e');
      // 确保命令列表不为null
      _commands = [];
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 导出命令为JSON字符串
  String exportCommandsToJson() {
    try {
      log.i('SSHCommandController', 'exportCommandsToJson(): 导出命令为JSON字符串');
      
      if (_commands.isEmpty) {
        log.w('SSHCommandController', 'exportCommandsToJson(): 命令列表为空，返回空数组');
        return '[]';
      }
      
      final jsonList = _commands.map((cmd) => cmd.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      log.i('SSHCommandController', 'exportCommandsToJson(): 导出成功，共 ${_commands.length} 个命令');
      return jsonString;
    } catch (e) {
      log.e('SSHCommandController', '导出命令出错', e);
      return '[]';
    }
  }
  
  /// 从JSON字符串导入命令
  Future<bool> importCommandsFromJson(String jsonString) async {
    if (_isBusy) {
      log.w('SSHCommandController', 'importCommandsFromJson(): 控制器正忙，跳过导入');
      return false;
    }
    _isBusy = true;
    
    try {
      if (jsonString.isEmpty) {
        log.w('SSHCommandController', 'importCommandsFromJson(): JSON字符串为空，跳过导入');
        return false;
      }
      
      log.i('SSHCommandController', 'importCommandsFromJson(): 开始导入命令');
      log.d('SSHCommandController', 'importCommandsFromJson(): 导入的JSON数据', jsonString);
      debugPrint('importCommandsFromJson: 导入的JSON数据长度: ${jsonString.length}');
      
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final importedCommands = jsonList
            .map((json) => SSHCommandModel.fromJson(json))
            .toList();
        
        log.i('SSHCommandController', 'importCommandsFromJson(): 解析JSON成功，准备导入 ${importedCommands.length} 个命令');
        debugPrint('importCommandsFromJson: 解析JSON成功，准备导入 ${importedCommands.length} 个命令');
        
        // 添加新命令，避免重复ID
        final existingIds = _commands.map((cmd) => cmd.id).toSet();
        int importedCount = 0;
        
        for (var cmd in importedCommands) {
          if (!existingIds.contains(cmd.id)) {
            _commands.add(cmd);
            importedCount++;
            log.d('SSHCommandController', '导入命令', '${cmd.name}: ${cmd.command}');
            debugPrint('importCommandsFromJson: 导入命令: ${cmd.name}: ${cmd.command}');
          } else {
            log.w('SSHCommandController', 'importCommandsFromJson(): 跳过已存在的命令', '${cmd.name}: ${cmd.command}');
            debugPrint('importCommandsFromJson: 跳过已存在的命令: ${cmd.name}: ${cmd.command}');
          }
        }
        
        log.i('SSHCommandController', 'importCommandsFromJson(): 成功导入 $importedCount 个新命令');
        debugPrint('importCommandsFromJson: 成功导入 $importedCount 个新命令');
        
        // 保存命令并重新加载
        await _saveCommandsInternal();
        debugPrint('importCommandsFromJson: 已保存命令，当前命令数: ${_commands.length}');
        
        notifyListeners();
        return importedCount > 0;
      } catch (e) {
        log.e('SSHCommandController', '解析或导入命令数据出错', e);
        debugPrint('importCommandsFromJson: 解析或导入命令出错: $e');
        return false;
      }
    } catch (e) {
      log.e('SSHCommandController', '导入命令出错', e);
      debugPrint('importCommandsFromJson: 导入命令出错: $e');
      return false;
    } finally {
      _isBusy = false;
    }
  }
  
  /// 添加命令
  Future<void> addCommand(SSHCommandModel command) async {
    if (_isBusy) {
      log.w('SSHCommandController', 'addCommand(): 控制器正忙，跳过添加命令');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'addCommand(): 添加命令 ${command.name}: ${command.command}');
      
      _commands.add(command);
      await saveCommands();
      notifyListeners();
      
      log.i('SSHCommandController', 'addCommand(): 命令添加成功');
    } catch (e) {
      log.e('SSHCommandController', '添加命令出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 更新命令
  Future<void> updateCommand(SSHCommandModel command) async {
    if (_isBusy) {
      log.w('SSHCommandController', 'updateCommand(): 控制器正忙，跳过更新命令');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'updateCommand(): 更新命令 ${command.name}: ${command.command}');
      
      final index = _commands.indexWhere((cmd) => cmd.id == command.id);
      
      if (index >= 0) {
        command.updatedAt = DateTime.now(); // 更新修改时间
        _commands[index] = command;
        await saveCommands();
        notifyListeners();
        
        log.i('SSHCommandController', 'updateCommand(): 命令更新成功');
      } else {
        log.w('SSHCommandController', 'updateCommand(): 未找到指定ID的命令', command.id);
      }
    } catch (e) {
      log.e('SSHCommandController', '更新命令出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 删除命令
  Future<void> deleteCommand(String id) async {
    if (_isBusy) {
      log.w('SSHCommandController', 'deleteCommand(): 控制器正忙，跳过删除命令');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'deleteCommand(): 删除命令ID', id);
      
      _commands.removeWhere((cmd) => cmd.id == id);
      await saveCommands();
      notifyListeners();
      
      log.i('SSHCommandController', 'deleteCommand(): 命令删除成功');
    } catch (e) {
      log.e('SSHCommandController', '删除命令出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(String id) async {
    if (_isBusy) {
      log.w('SSHCommandController', 'toggleFavorite(): 控制器正忙，跳过切换收藏状态');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHCommandController', 'toggleFavorite(): 切换命令收藏状态，ID', id);
      
      final index = _commands.indexWhere((cmd) => cmd.id == id);
      
      if (index >= 0) {
        _commands[index].isFavorite = !_commands[index].isFavorite;
        _commands[index].updatedAt = DateTime.now();
        await saveCommands();
        notifyListeners();
        
        log.i('SSHCommandController', 'toggleFavorite(): 命令收藏状态已切换为', _commands[index].isFavorite);
      } else {
        log.w('SSHCommandController', 'toggleFavorite(): 未找到指定ID的命令', id);
      }
    } catch (e) {
      log.e('SSHCommandController', '切换收藏状态出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 查找命令
  SSHCommandModel? getCommandById(String id) {
    try {
      return _commands.firstWhere((cmd) => cmd.id == id);
    } catch (e) {
      log.w('SSHCommandController', 'getCommandById(): 未找到指定ID的命令', id);
      return null;
    }
  }
  
  /// 根据关键词搜索命令
  List<SSHCommandModel> searchCommands(String keyword) {
    if (keyword.isEmpty) {
      return List.unmodifiable(_commands);
    }
    
    try {
      final lowercaseKeyword = keyword.toLowerCase();
      
      return List.unmodifiable(_commands.where((cmd) {
        // 检查名称、命令内容和描述
        final basicMatch = cmd.name.toLowerCase().contains(lowercaseKeyword) ||
            cmd.command.toLowerCase().contains(lowercaseKeyword) ||
            cmd.description.toLowerCase().contains(lowercaseKeyword);
            
        // 检查标签
        final tagMatch = cmd.tags.any((tag) => 
            tag.toLowerCase().contains(lowercaseKeyword));
            
        return basicMatch || tagMatch;
      }).toList());
    } catch (e) {
      log.e('SSHCommandController', '搜索命令出错', e);
      return [];
    }
  }
  
  /// 获取所有标签
  List<String> getAllTags() {
    final Set<String> allTags = {};
    
    for (final command in _commands) {
      allTags.addAll(command.tags);
    }
    
    return allTags.toList()..sort();
  }
  
  /// 按标签过滤命令
  List<SSHCommandModel> getCommandsByTag(String tag) {
    if (tag.isEmpty) {
      return List.unmodifiable(_commands);
    }
    
    try {
      return List.unmodifiable(
        _commands.where((cmd) => cmd.tags.contains(tag)).toList()
      );
    } catch (e) {
      log.e('SSHCommandController', '按标签过滤命令出错', e);
      return [];
    }
  }
} 