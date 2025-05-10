# 侧边栏配置系统API

本文档描述侧边栏配置系统的WebSocket API请求和响应格式。

## 页面切换请求操作

当通过侧边栏切换页面时，会根据不同的页面ID发起对应的API请求，以加载相应页面的数据：

| 页面ID | 请求操作 | 描述 |
|-------|--------|------|
| home | home_read | 请求首页配置数据 |
| function | function_read | 请求功能设置数据 |
| pid | pid_read | 请求PID设置数据 |
| fov | fov_read | 请求视野设置数据 |
| aim | aim_read | 请求瞄准设置数据 |
| fire | fire_read | 请求射击设置数据 |
| data_collection | data_collection_read | 请求数据收集数据 |

## 刷新操作

点击侧边栏上的刷新按钮时，系统会依次发送上述**所有页面**的读取请求，以便刷新应用中的所有数据。请求会以100毫秒间隔依次发送，以避免请求过于集中，确保服务器能够顺利处理。

## 通用请求格式

以下是所有页面切换请求的通用格式：

```json
{
  "action": "[页面ID]_read",
  "content": {
    "username": "用户名",
    "gameName": "游戏名称",
    "cardKey": "卡密",
    "updatedAt": "2023-06-01T12:00:00Z"
  }
}
```

## 通用响应格式

服务器响应的通用格式为：

```json
{
  "action": "[页面ID]_read_response",
  "status": "ok",
  "data": {
    // 页面特定的数据
    "username": "用户名",
    "gameName": "游戏名称",
    // 其他页面特有的数据字段...
    "createdAt": "2023-06-01T12:00:00Z",
    "updatedAt": "2023-06-01T13:30:00Z"
  }
}
```

## 参数说明

| 参数名称 | 类型 | 描述 | 可选值 |
|---------|------|------|-------|
| username | string | 用户名 | 任意字符串 |
| gameName | string | 游戏名称 | apex, cf, cfhd, csgo2, pubg, sjz, ssjj2, wwqy |
| cardKey | string | 用户卡密 | 任意字符串 |
| updatedAt | string | 更新时间戳 | ISO8601格式的时间字符串 |

## 页面特有的参数

每个页面的API将返回该页面特有的参数，具体可参考相应页面的API文档：

- [首页配置API](home_api.md)
- [功能设置API](fun_api.md)
- [PID设置API](pid_api.md)
- [视野设置API](fov_api.md)
- [瞄准设置API](aim_api.md)
- [射击设置API](fire_api.md)
- [数据收集API](data_collection_api.md) 