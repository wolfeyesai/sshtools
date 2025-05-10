// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// 认证服务 - 处理登录、注册等认证相关请求
class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // 登录
  Future<Map<String, dynamic>> login({
    required String serverAddress,
    required String serverPort,
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 构建登录请求模型
      final loginModel = {
        'action': 'login',
        'content': {
          'username': username,
          'password': password,
        }
      };
      
      // 发送登录请求
      final uri = Uri.parse('http://$serverAddress:$serverPort/api/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginModel),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          _setLoading(false);
          return {
            'success': true,
            'token': responseData['token'],
            'username': username,
          };
        } else {
          _setError(responseData['message'] ?? '登录失败');
          return {'success': false};
        }
      } else {
        _setError('服务器错误: ${response.statusCode}');
        return {'success': false};
      }
    } catch (e) {
      _setError('连接服务器失败: $e');
      return {'success': false};
    } finally {
      _setLoading(false);
    }
  }
  
  // 注册
  Future<Map<String, dynamic>> register({
    required String serverAddress,
    required String serverPort,
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 构建注册请求模型
      final registerModel = {
        'action': 'register',
        'content': {
          'username': username,
          'password': password,
          'gameList': [
            'apex',
            'cf', 
            'cfhd',
            'csgo2',
            'sj2',
            'ssjj2',
            'wwqy'
          ],
          'defaultGame': 'csgo2',
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送注册请求
      final uri = Uri.parse('http://$serverAddress:$serverPort/api/auth/register');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerModel),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          _setLoading(false);
          return {
            'success': true,
            'message': responseData['message'] ?? '注册成功',
          };
        } else {
          _setError(responseData['message'] ?? '注册失败');
          return {'success': false};
        }
      } else {
        _setError('服务器错误: ${response.statusCode}');
        return {'success': false};
      }
    } catch (e) {
      _setError('连接服务器失败: $e');
      return {'success': false};
    } finally {
      _setLoading(false);
    }
  }
  
  // 退出登录
  Future<void> logout({
    required String serverAddress,
    required String serverPort,
    required String token,
  }) async {
    _setLoading(true);
    
    try {
      // 构建退出登录请求模型
      final logoutModel = {
        'action': 'logout',
        'token': token,
      };
      
      // 发送退出登录请求
      final uri = Uri.parse('http://$serverAddress:$serverPort/api/auth/logout');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(logoutModel),
      ).timeout(const Duration(seconds: 5));
      
      // 不管服务器响应如何，都视为退出成功
    } catch (e) {
      debugPrint('退出登录请求失败: $e');
      // 即使请求失败，也视为已退出
    } finally {
      _setLoading(false);
    }
  }
  
  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // 清除错误信息
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
} 