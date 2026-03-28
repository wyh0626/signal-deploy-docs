# Dev 部署替代件

## 替代原则

这个项目的策略是：

- 优先保留 Signal 上游代码路径
- 只在“本地无法获得的云能力”上做替代
- 能 stub 的 stub，不能 stub 的就明确标注边界

## 替代表

| 官方依赖 | 本地替代 | 是否已接入 | 备注 |
| --- | --- | --- | --- |
| AWS DynamoDB | DynamoDB Local | 是 | 表结构对齐 `DynamoDbExtensionSchema` |
| AWS S3 | MinIO | 是 | 用于 CDN / dynamic config / ASN / prekeys |
| Google Cloud Storage | MinIO | 是 | 本地统一走 S3 兼容层 |
| Redis 多集群 | Redis 单节点 cluster + standalone | 是 | 4 个 cluster + 1 个 standalone |
| Firestore | Firestore emulator | 是 | registration-service 依赖 |
| Pub/Sub | Pub/Sub emulator / no-op publisher | 是 | server 侧用 no-op publisher 补洞 |
| Bigtable | Bigtable emulator | 是 | registration-service 依赖 |
| Twilio / MessageBird | `dev` 模式验证码 | 是 | 验证码 = 手机号后 6 位 |
| APNs | dummy config | 是 | 服务可启动，但不能真实推送 |
| FCM | dummy config | 是 | 服务可启动，但不能真实推送 |
| Stripe / Braintree | dummy config + noop | 是 | 本地不做真实支付 |
| Google Play Billing | dummy service account | 是 | 只保证启动不崩 |
| Apple App Store | dummy key + root cert | 是 | 只保证启动不崩 |
| Contact Discovery Service | stub | 否 | 无 SGX，本地不复现 |
| SVR2 / SVRB | stub | 否 | 无 SGX，本地不复现 |
| Key Transparency | stub | 否 | 无 SGX，本地不复现 |
| FoundationDB 集群 | 不启动，仅处理构建时库文件 | 否 | 当前 dev stack 不依赖真实 FDB 集群 |

## 哪些功能能测

可以测：

- 服务端启动
- 注册会话创建
- 本地验证码验证
- 桌面端 standalone 注册链路
- 基础 WebSocket 连接
- 本地对象存储与动态配置加载

不能按生产方式完整测：

- SGX 相关能力
- 真实短信发送
- 真正的移动推送
- 真正的商店支付 / 订阅校验
- 真实多节点 Redis / FoundationDB 运维行为
