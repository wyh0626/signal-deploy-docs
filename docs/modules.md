# 模块说明

## 核心应用模块

| 模块 | 来源 | 作用 | 本项目状态 |
| --- | --- | --- | --- |
| `Signal-Server` | `signalapp/Signal-Server` | 主后端，负责账号、消息、配置、附件、WebSocket、gRPC | 已接入 |
| `registration-service` | `signalapp/registration-service` | 验证码会话、手机号校验、注册前置流程 | 已接入 |
| `Signal-Desktop` | `signalapp/Signal-Desktop` | 桌面端本地调试 | 可选 |

## 基础设施模块

| 模块 | 本地替代 | 用途 | 说明 |
| --- | --- | --- | --- |
| DynamoDB | DynamoDB Local | 账号、消息、会话、配置等表 | 使用与 Signal-Server 测试夹具对齐的表结构 |
| S3 / GCS | MinIO | CDN、附件、动态配置、ASN 数据 | S3 兼容，适合本地调试 |
| Redis cacheCluster | 单节点 Redis Cluster | cache cluster | 通过 `CLUSTER ADDSLOTSRANGE` 做单节点集群 |
| Redis pushSchedulerCluster | 单节点 Redis Cluster | 推送调度 | 本地只验证依赖可启动 |
| Redis rateLimitersCluster | 单节点 Redis Cluster | 限流器 | registration-service 和 signal-server 都会用到 |
| Redis messageCache | 单节点 Redis Cluster | 消息缓存 | 本地验证启动链路 |
| Redis pubsub | Standalone Redis | Pub/Sub | 单独保留 standalone |
| Firestore / PubSub / Bigtable | GCloud emulators | registration-service 的本地替代依赖 | 不需要真实 GCP 项目 |

## 被 stub 或禁用的模块

| 模块 | 官方作用 | 本地处理方式 |
| --- | --- | --- |
| Contact Discovery Service | 通讯录发现 | 不部署，提供 dummy 密钥 |
| SVR2 / SVRB | PIN/备份恢复 | 不部署，提供 dummy 证书和 secret |
| Key Transparency | 公钥透明度 | 不部署，提供 dummy 证书和私钥 |
| APNs / FCM | 移动端推送 | 配置 dummy credentials，不做真实推送 |
| Stripe / Braintree | 订阅和支付 | 保留配置结构，但走本地空实现 |
| Google Play Billing / Apple App Store | 商店验证 | 用 dummy credential 保证服务可启动 |
| FoundationDB runtime | 官方部分存储链路依赖 | 本地不启动 FoundationDB，只在构建阶段预置或 stub `libfdb_c.so` |

## 对上游源码的最小补丁

### `Signal-Server`

- 新增 `registrationService.type=local`
  允许用明文 gRPC 对接本地 `registration-service`，不再要求 identity token。
- 新增 `pubSubPublisher.type=noop`
  替代依赖 Google Pub/Sub publisher 的功能块。

### `Signal-Desktop`

- `attachments.preload.ts`
  `fs-xattr` 原生模块缺失时不再让 preload 整体失败。
- `desktopCapturer.preload.ts`
  `@indutny/mac-screen-share` 缺失时提供 graceful fallback。
- `scripts/start-local-dev.sh`
  从本仓库生成的本地配置注入 `NODE_CONFIG`，指向本地 `signal-server`。
