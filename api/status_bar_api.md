# 状态栏系统API

本文档描述状态栏系统的WebSocket API请求和响应格式。

## 重要说明

1. 状态栏查询操作不会更新数据库，只是读取当前服务器状态并返回。
2. 状态栏中的所有状态指示器只有两种状态：正常（绿色）和异常（红色）。

## 请求和响应格式

系统使用以下主要操作：
- `status_bar_query`: 查询状态栏信息（重连按钮触发）
- `connection_status_query`: 查询连接状态
- `service_health_query`: 查询服务健康状态

### 查询状态栏信息 (status_bar_query)

**说明**：当用户点击重连按钮时触发，用于获取服务器当前状态信息。此操作不会更新数据库，只是读取当前状态并显示为红色或绿色指示灯。

**客户端请求**：

```json
{
  "action": "status_bar_query",
  "token": "认证令牌"
}
```

**服务器响应**：

```json
{
  "action": "status_bar_response",
  "status": "success",
  "data": {
    "dbStatus": "connected",        // connected（绿色）或 error（红色）
    "inferenceStatus": "running",   // running（绿色）或 error（红色）
    "cardKeyStatus": "valid",       // valid（绿色）或 invalid/expired（红色）
    "keyMouseStatus": "ready",      // ready（绿色）或 error（红色）
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

### 查询连接状态 (connection_status_query)

**说明**：查询当前客户端与服务器的连接详细状态，用于诊断网络问题。不更新数据库。

**客户端请求**：

```json
{
  "action": "connection_status_query",
  "content": {
    "username": "用户名",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "connection_status_response",
  "status": "success",
  "data": {
    "connected": true,              // true（绿色）或 false（红色）
    "connectionType": "websocket", 
    "ip": "192.168.1.1",
    "connectionTime": "2023-06-01T11:30:00Z",
    "lastHeartbeat": "2023-06-01T12:00:00Z",
    "pingLatency": 25,              // 小于100ms（绿色）或 大于100ms（红色）
    "updatedAt": "2023-06-01T12:00:01Z"
  }
}
```

### 查询服务健康状态 (service_health_query)

**说明**：查询服务器各组件的健康状态，用于系统监控。不更新数据库。

**客户端请求**：

```json
{
  "action": "service_health_query",
  "content": {
    "username": "用户名",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "service_health_response",
  "status": "success",
  "data": {
    "services": [
      {
        "name": "database",
        "status": "healthy",        // healthy（绿色）或 error（红色）
        "uptime": 86400,
        "lastCheck": "2023-06-01T12:00:00Z"
      },
      {
        "name": "inference",
        "status": "healthy",        // healthy（绿色）或 error（红色）
        "uptime": 43200,
        "lastCheck": "2023-06-01T12:00:00Z"
      },
      {
        "name": "keyMouse",
        "status": "healthy",        // healthy（绿色）或 error（红色）
        "uptime": 3600,
        "lastCheck": "2023-06-01T12:00:00Z"
      },
      {
        "name": "licensing",
        "status": "healthy",        // healthy（绿色）或 error（红色）
        "uptime": 86400,
        "lastCheck": "2023-06-01T12:00:00Z"
      }
    ],
    "overallStatus": "healthy",     // healthy（绿色）或 error（红色）
    "updatedAt": "2023-06-01T12:00:01Z"
  }
}
```

## 参数说明

### 状态栏参数

**重要说明**：所有状态指示器只有两种显示状态：正常（绿色）和异常（红色）。

| 参数名称 | 类型 | 描述 | 显示状态 |
|---------|------|------|---------|
| dbStatus | string | 数据库连接状态 | connected（绿色）, error（红色） |
| inferenceStatus | string | 推理服务状态 | running（绿色）, error（红色） |
| cardKeyStatus | string | 卡密状态 | valid（绿色）, invalid/expired（红色） |
| keyMouseStatus | string | 键鼠状态 | ready（绿色）, error（红色） |

以下参数仅用于详细信息显示，不影响状态指示灯：

| 参数名称 | 类型 | 描述 | 示例值 |
|---------|------|------|--------|
| cpuUsage | number | CPU使用率(%) | 0-100 |
| memoryUsage | number | 内存使用率(%) | 0-100 |
| networkLatency | number | 网络延迟(ms) | 0-1000+ |
| clientVersion | string | 客户端版本 | "1.5.2" |
| serverVersion | string | 服务器版本 | "2.3.0" |

### 连接状态参数

| 参数名称 | 类型 | 描述 | 显示状态 |
|---------|------|------|---------|
| connected | boolean | 是否已连接 | true（绿色）, false（红色） |
| pingLatency | number | Ping延迟(ms) | <100ms（绿色）, >100ms（红色） |

以下参数仅用于详细信息显示：

| 参数名称 | 类型 | 描述 | 示例值 |
|---------|------|------|--------|
| connectionType | string | 连接类型 | websocket, http, tcp |
| ip | string | 客户端IP地址 | "192.168.1.1" |
| connectionTime | string | 连接建立时间 | ISO8601格式时间字符串 |
| lastHeartbeat | string | 最后心跳时间 | ISO8601格式时间字符串 |

### 服务健康状态参数

| 参数名称 | 类型 | 描述 | 显示状态 |
|---------|------|------|---------|
| status | string | 服务状态 | healthy（绿色）, error（红色） |
| overallStatus | string | 整体状态 | healthy（绿色）, error（红色） |

以下参数仅用于详细信息显示：

| 参数名称 | 类型 | 描述 | 示例值 |
|---------|------|------|--------|
| name | string | 服务名称 | database, inference, keyMouse, licensing |
| uptime | number | 服务运行时间(秒) | 0+ |
| lastCheck | string | 最后检查时间 | ISO8601格式时间字符串 | 