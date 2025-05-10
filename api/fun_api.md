# 功能配置系统API

本文档描述功能配置系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用两种主要操作：
- `function_read`: 读取功能配置
- `function_modify`: 修改功能配置

### 读取功能配置 (function_read)

**客户端请求**：

```json
{
  "action": "function_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "function_read_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "configs": [
      {
        "presetName": "配置1",
        "hotkey": "右键",
        "aiMode": "FOV",
        "lockPosition": "头部",
        "triggerSwitch": true,
        "enabled": true
      },
      {
        "presetName": "配置2",
        "hotkey": "右键",
        "aiMode": "FOV",
        "lockPosition": "颈部",
        "triggerSwitch": false,
        "enabled": false
      }
    ],
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

### 修改功能配置 (function_modify)

**客户端请求**：

```json
{
  "action": "function_modify",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "configs": [
      {
        "presetName": "配置1",
        "hotkey": "右键",
        "aiMode": "FOV",
        "lockPosition": "头部",
        "triggerSwitch": true,
        "enabled": true
      },
      {
        "presetName": "配置2",
        "hotkey": "左键",
        "aiMode": "PID",
        "lockPosition": "胸部",
        "triggerSwitch": false,
        "enabled": true
      }
    ],
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "function_modify_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "configs": [
      {
        "presetName": "配置1",
        "hotkey": "右键",
        "aiMode": "FOV",
        "lockPosition": "头部",
        "triggerSwitch": true,
        "enabled": true
      },
      {
        "presetName": "配置2",
        "hotkey": "左键",
        "aiMode": "PID",
        "lockPosition": "胸部",
        "triggerSwitch": false,
        "enabled": true
      }
    ],
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 可选值 |
|---------|------|------|-------|
| presetName | string | 配置预设名称 | 任意字符串 |
| hotkey | string | 热键设置 | 左键、右键、中键、前侧、后侧 |
| aiMode | string | AI模式 | PID、FOV、FOVPID |
| lockPosition | string | 锁定位置 | 头部、颈部、胸部 |
| triggerSwitch | boolean | 触发开关 | true/false |
| enabled | boolean | 是否启用 | true/false |
