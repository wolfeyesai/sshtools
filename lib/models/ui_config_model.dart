// ignore_for_file: unnecessary_import, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI配置模型 - 管理UI相关配置
class UIConfigModel extends ChangeNotifier {
  // 页头下拉框配置
  Map<String, dynamic> _headerDropdownConfig = {
    //宽度
    'width': 100.0,
    //高度
    'height': 100.0,
    //背景色
    'backgroundColor': Colors.white,
    //字体颜色
    'textColor': Colors.black,
    //字体大小
    'fontSize': 16.0,
    //字体粗细
    'fontWeight': FontWeight.normal,
  };
  
  // 字体配置
  String _fontFamily = 'Roboto';
  bool _useGoogleFonts = true;
  List<String> _availableFonts = [
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Oswald',
    'Noto Sans',
    'Source Sans Pro',
    'Poppins',
  ];
  
  // Getters
  Map<String, dynamic> get headerDropdownConfig => _headerDropdownConfig;
  
  // 获取下拉框宽度
  double get dropdownWidth => _headerDropdownConfig['width'] as double;
  
  // 获取下拉框高度 
  double get dropdownHeight => _headerDropdownConfig['height'] as double;
  
  // 获取背景色
  Color get backgroundColor => _headerDropdownConfig['backgroundColor'] as Color;
  
  // 获取文字颜色
  Color get textColor => _headerDropdownConfig['textColor'] as Color;
  
  // 获取字体大小
  double get fontSize => _headerDropdownConfig['fontSize'] as double;
  
  // 获取字体粗细
  FontWeight get fontWeight => _headerDropdownConfig['fontWeight'] as FontWeight;
  
  // 字体相关 getters
  String get fontFamily => _fontFamily;
  bool get useGoogleFonts => _useGoogleFonts;
  List<String> get availableFonts => _availableFonts;
  
  // 获取当前文本主题样式
  TextStyle getTextStyle({TextStyle? baseStyle}) {
    if (_useGoogleFonts) {
      return GoogleFonts.getFont(
        _fontFamily,
        textStyle: baseStyle,
        fontSize: baseStyle?.fontSize ?? _headerDropdownConfig['fontSize'] as double,
        fontWeight: baseStyle?.fontWeight ?? _headerDropdownConfig['fontWeight'] as FontWeight,
        color: baseStyle?.color ?? _headerDropdownConfig['textColor'] as Color,
      );
    } else {
      return TextStyle(
        fontFamily: _fontFamily,
        fontSize: baseStyle?.fontSize ?? _headerDropdownConfig['fontSize'] as double,
        fontWeight: baseStyle?.fontWeight ?? _headerDropdownConfig['fontWeight'] as FontWeight,
        color: baseStyle?.color ?? _headerDropdownConfig['textColor'] as Color,
      );
    }
  }
  
  // 获取文本主题
  TextTheme getTextTheme(TextTheme baseTheme) {
    if (_useGoogleFonts) {
      return GoogleFonts.getTextTheme(_fontFamily, baseTheme);
    } else {
      return baseTheme;
    }
  }
  
  // 初始化 - 从持久化存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 这里可以从持久化存储加载自定义的UI配置
    // 由于UI配置包含复杂对象如Color、FontWeight等，需要特殊处理
    
    // 示例：只加载简单类型
    final width = prefs.getDouble('ui_dropdown_width');
    if (width != null) {
      _headerDropdownConfig['width'] = width;
    }
    
    final height = prefs.getDouble('ui_dropdown_height');
    if (height != null) {
      _headerDropdownConfig['height'] = height;
    }
    
    final fontSize = prefs.getDouble('ui_dropdown_font_size');
    if (fontSize != null) {
      _headerDropdownConfig['fontSize'] = fontSize;
    }
    
    // 加载字体配置
    final fontFamily = prefs.getString('ui_font_family');
    if (fontFamily != null && _availableFonts.contains(fontFamily)) {
      _fontFamily = fontFamily;
    }
    
    final useGoogleFonts = prefs.getBool('ui_use_google_fonts');
    if (useGoogleFonts != null) {
      _useGoogleFonts = useGoogleFonts;
    }
    
    notifyListeners();
  }
  
  // 更新下拉框宽度
  Future<void> updateDropdownWidth(double width) async {
    _headerDropdownConfig['width'] = width;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新下拉框高度
  Future<void> updateDropdownHeight(double height) async {
    _headerDropdownConfig['height'] = height;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新背景色
  Future<void> updateBackgroundColor(Color color) async {
    _headerDropdownConfig['backgroundColor'] = color;
    notifyListeners();
    // 注意：颜色对象无法直接保存到SharedPreferences，需要特殊处理
  }
  
  // 更新文本颜色
  Future<void> updateTextColor(Color color) async {
    _headerDropdownConfig['textColor'] = color;
    notifyListeners();
    // 注意：颜色对象无法直接保存到SharedPreferences，需要特殊处理
  }
  
  // 更新字体大小
  Future<void> updateFontSize(double size) async {
    _headerDropdownConfig['fontSize'] = size;
    await _saveSettings();
    notifyListeners();
  }
  
  // 更新字体粗细
  Future<void> updateFontWeight(FontWeight weight) async {
    _headerDropdownConfig['fontWeight'] = weight;
    notifyListeners();
    // 注意：FontWeight对象无法直接保存到SharedPreferences，需要特殊处理
  }
  
  // 更新字体
  Future<void> updateFontFamily(String fontFamily) async {
    if (_availableFonts.contains(fontFamily)) {
      _fontFamily = fontFamily;
      await _saveSettings();
      notifyListeners();
    }
  }
  
  // 切换是否使用Google字体
  Future<void> toggleGoogleFonts(bool useGoogleFonts) async {
    _useGoogleFonts = useGoogleFonts;
    await _saveSettings();
    notifyListeners();
  }
  
  // 保存设置到持久化存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存简单类型
    await prefs.setDouble('ui_dropdown_width', _headerDropdownConfig['width'] as double);
    await prefs.setDouble('ui_dropdown_height', _headerDropdownConfig['height'] as double);
    await prefs.setDouble('ui_dropdown_font_size', _headerDropdownConfig['fontSize'] as double);
    
    // 保存字体配置
    await prefs.setString('ui_font_family', _fontFamily);
    await prefs.setBool('ui_use_google_fonts', _useGoogleFonts);
    
    // 复杂类型如Color和FontWeight需要转换成可保存的格式
  }
} 