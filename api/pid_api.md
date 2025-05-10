# 近端瞄准控制系统API

本文档描述近端瞄准控制系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用两种主要操作：
- `pid_read`: 读取近端瞄准参数
- `pid_modify`: 修改近端瞄准参数

### 读取近端瞄准参数 (pid_read)

**客户端请求**：

```json
{
  "action": "pid_read",
  "content": {
    "username": "用户名",
    "token": "认证令牌",
    "gameName": "游戏名称"
  }
}
```

**服务器响应**：

```json
{
  "action": "pid_read_response",
  "status": "success",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "nearMoveFactor": 1.0,    // 近端移动速度
    "nearStabilizer": 0.5,    // 近端跟踪速度
    "nearResponseRate": 0.3,  // 近端抖动力度
    "nearAssistZone": 3.0,    // 近端死区大小
    "nearResponseDelay": 1.0,   // 近端回弹速度
    "nearMaxAdjustment": 2.0, // 近端积分限制
    "farFactor": 1.0,         // 远端系数
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

### 修改近端瞄准参数 (pid_modify)

**客户端请求**：

```json
{
  "action": "pid_modify",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "nearMoveFactor": 1.0,    // 近端移动速度
    "nearStabilizer": 0.5,    // 近端跟踪速度
    "nearResponseRate": 0.3,  // 近端抖动力度
    "nearAssistZone": 3.0,    // 近端死区大小
    "nearResponseDelay": 1.0,   // 近端回弹速度
    "nearMaxAdjustment": 2.0, // 近端积分限制
    "farFactor": 1.0,         // 远端系数
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "pid_modify_response",
  "status": "success",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "nearMoveFactor": 1.0,    // 近端移动速度
    "nearStabilizer": 0.5,    // 近端跟踪速度
    "nearResponseRate": 0.3,  // 近端抖动力度
    "nearAssistZone": 3.0,    // 近端死区大小
    "nearResponseDelay": 1.0,   // 近端回弹速度
    "nearMaxAdjustment": 2.0, // 近端积分限制
    "farFactor": 1.0,         // 远端系数
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 默认值 | 范围 |
|---------|------|------|-------|------|
| nearMoveFactor | double | 近端移动速度 | 1.0 | 0.0-2.0 |
| nearStabilizer | double | 近端跟踪速度 | 0.5 | 0.0-5.0 |
| nearResponseRate | double | 近端抖动力度 | 0.3 | 0.0-5.0 |
| nearAssistZone | double | 近端死区大小 | 3.0 | 0.0-10.0 |
| nearResponseDelay | double | 近端回弹速度 | 1.0 | 0.0-2.0 |
| nearMaxAdjustment | double | 近端积分限制 | 2.0 | 0.0-5.0 |
| farFactor | double | 远端系数 | 1.0 | 0.0-2.0 |
