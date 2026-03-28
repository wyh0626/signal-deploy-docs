# 本地跑不全的官方依赖

English: [./en/non-local-services.md](./en/non-local-services.md)

这份文档回答两个问题：

- 哪些官方依赖当前没有在这个仓库里完整复现
- 它们在整个 Signal 系统里到底负责什么

## 依赖清单

| 模块 | 官方作用 | 当前状态 | 为什么没完整接入 | 生产化需要什么 |
| --- | --- | --- | --- | --- |
| Contact Discovery Service | 通讯录匹配，让客户端私密地判断联系人是否也在 Signal | 未部署 | 依赖 SGX 和独立服务链路 | SGX 硬件、远程证明、专门服务部署 |
| SVR2 / SVRB | PIN、密钥材料、备份恢复相关能力 | 未部署 | 依赖 SGX 和专门运维体系 | SGX 硬件、恢复服务、证明链与密钥管理 |
| Key Transparency | 公钥透明度、防止服务端悄悄替换用户公钥 | 未部署 | 当前本地 demo 不覆盖这条链路 | 独立服务、日志结构、客户端集成验证 |
| APNs | iOS 推送 | dummy 配置 | 需要 Apple 开发者账号和推送证书/密钥 | Apple Developer Program、APNs key/cert |
| FCM | Android 推送 | dummy 配置 | 需要 Google/Firebase 项目和服务账号 | Firebase 项目、FCM sender、服务账号 |
| Stripe / Braintree | 支付、订阅、捐赠 | no-op / dummy | 本地 demo 不验证支付 | 商户账号、Webhook、安全合规 |
| Google Play Billing | Google Play 订阅与购买校验 | dummy 配置 | 需要真实 Play Console 凭证与商品配置 | Play Console、service account、商品管理 |
| Apple App Store | App Store 收据和订阅校验 | dummy 配置 | 需要真实 App Store Connect 密钥和根证书链 | Apple Developer、App Store Connect、密钥轮换 |
| FoundationDB 集群 | 官方部分数据链路依赖的分布式存储运行时 | 未部署集群 | 本地 dev stack 当前不依赖完整 FDB 集群行为 | FoundationDB 集群、备份、监控、滚动升级 |
| 多节点 Redis 集群 | 缓存、限流、调度、消息缓存 | 单节点 cluster 替代 | 本地只验证接口和启动逻辑 | 至少三节点集群、持久化、容灾 |
| 真实短信供应商 | 发送验证码短信和语音 | `dev` 模式替代 | 本地调试不需要真实发送 | Twilio/MessageBird 等账号和模板 |

## 对本地调试的影响

当前这个仓库适合验证：

- `signal-server` 是否能完整启动
- `registration-service` 注册会话和验证码流程
- `Signal-Desktop` 是否能直连本地后端
- 基础 WebSocket 和对象存储加载

当前这个仓库不适合验证：

- 真实推送可达性
- 通讯录发现隐私链路
- PIN 备份恢复
- 商店支付和订阅
- 真实多节点分布式运维行为

## 推荐理解方式

可以把这些未完整接入的依赖分成三类：

- 账号与通信主链路之外的增强能力
  例如推送、支付、商店验证
- 依赖可信硬件的隐私能力
  例如 CDS、SVR2
- 真正进入生产才需要的高可用基础设施
  例如多节点 Redis、FoundationDB 集群
