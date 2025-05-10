# 视野设置系统API

本文档描述视野设置系统的WebSocket API请求和响应格式。

## 请求和响应格式

系统使用三种主要操作：
- `fov_read`: 读取视野设置
- `fov_modify`: 修改视野设置
- `fov_measurement_start`: 开始FOV测量

### 读取视野设置 (fov_read)

**客户端请求**：

```json
{
  "action": "fov_read",
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
  "action": "fov_read_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "fov": 0.7,
    "fovTime": 500,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

### 修改视野设置 (fov_modify)

**客户端请求**：

```json
{
  "action": "fov_modify",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "fov": 0.7,
    "fovTime": 500,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

**服务器响应**：

```json
{
  "action": "fov_modify_response",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "fov": 0.7,
    "fovTime": 500,
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T14:00:00Z"
  }
}
```

### 开始FOV测量 (fov_measurement_start)

**客户端请求**：

```json
{
  "action": "fov_measurement_start",
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
  "action": "fov_measurement_start",
  "status": "ok",
  "data": {
    "username": "用户名",
    "gameName": "游戏名称",
    "fov": 0.7,
    "fovTime": 500,
    "message": "FOV测量已开始"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 可选值/范围 |
|---------|------|------|-------|
| fov | double | 视野范围值 | 0.0 - 180.0 |
| fovTime | int | 视野变化过渡时间(毫秒) | 0 - 1000 | 