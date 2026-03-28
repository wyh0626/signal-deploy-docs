# 部署清单

English: [./en/deployment-checklists.md](./en/deployment-checklists.md)

这份文档把部署路线拆成两套：

- `省钱测试清单`
  目标是尽快验证本地后端、验证码链路、`Signal-Desktop` standalone、接口联调。
- `生产准备清单`
  目标是准备公网 beta 或后续正式服务，逐步替换本地假实现，接入真实云服务、推送、短信、监控和密钥管理。

先说结论：

- 只做本地联调和 demo，不要买 SGX，不要买 Bigtable，不要急着买短信量。
- 准备公网服务时，优先做“无 SGX 的 production-ready beta”。
- 真正接近官方完整能力时，再单独开 `SGX` 轨道处理 `Contact Discovery Service` 和 `SVR2`。

## 选哪条路线

| 目标 | 选哪套清单 | 现在先不要买什么 |
| --- | --- | --- |
| 本地调试 `Signal-Server` / `Signal-Desktop` | 省钱测试清单 | SGX、Bigtable、Pub/Sub、真实短信、真实 APNs/FCM |
| 小范围内测 / 公网 beta | 生产准备清单（先不带 SGX） | 先不要承诺完整私密通讯录发现和 PIN 恢复 |
| 接近完整产品能力 | 生产准备清单 + SGX 子清单 | 不要把 SGX 混进默认一键部署 |

## 省钱测试清单

### 适用目标

- 跑通本地 `Signal-Server`
- 跑通本地 `registration-service`
- 验证验证码会话和注册链路
- 让 `Signal-Desktop` 直连本地环境做 standalone 调试
- 为后续 Android / iOS 本地接入做准备

### 最低资源建议

- 本机开发机：
  - `8 vCPU`
  - `16 GB RAM`
  - `80 GB` 以上 SSD 可用空间
- 如果想给外部同事远程演示：
  - `1` 台 `4 vCPU / 8 GB RAM / 100 GB SSD` 的 Linux 云主机
  - `1` 个域名
  - 反向代理和 TLS 证书

### 需要准备的东西

- Docker 或 Docker Desktop
- `bash`、`git`、`python3`
- 能拉取上游 Signal 仓库的网络环境
- 可选：
  - 域名
  - 反向代理
  - 公开 HTTPS 入口

### 直接复用本仓库的本地替代件

| 官方依赖 | 测试环境替代件 | 当前仓库做法 |
| --- | --- | --- |
| `DynamoDB` | `DynamoDB Local` | 已内置 |
| `S3` / `GCS` | `MinIO` | 已内置 |
| 多套 `Redis Cluster` | 单节点 Redis Cluster | 已内置 |
| `Pub/Sub` | `noop` / emulator | 已内置 |
| `Firestore` / `Bigtable` | emulator / dummy config | 已内置 |
| 短信发送 | dev 模式验证码 | 已内置 |
| `APNs` / `FCM` | 关闭或空实现 | 已内置 |
| `CDS` / `SVR2` / `Key Transparency` | stub / dummy config | 已内置 |

### 这条路线先不要买

- `Apple Developer Program`
- `Google Play` 开发者账号
- `Twilio` / `MessageBird` 短信配额
- `Firebase Blaze` 计费项目
- `Bigtable`
- `Pub/Sub`
- `Azure SGX`
- 自建 `FoundationDB` 生产集群
- 托管 `Redis` 高可用集群

### 快速验收

1. 复制环境变量：

```bash
cp .env.example .env
```

2. 拉起本地栈：

```bash
./scripts/dev-up.sh
```

3. 跑最小后端链路验证：

```bash
./scripts/dev-up.sh --smoke-test
```

4. 如果要一起看桌面端：

```bash
./scripts/dev-up.sh --include-desktop
```

### 这条路线的完成标准

- `signal-server` 健康检查正常
- `registration-service` 能完成验证码会话
- 验证码规则可用：手机号后 6 位
- `Signal-Desktop` 能以 standalone 方式接入本地环境
- 你已经确认哪些能力只是 stub，而不是误以为已生产可用

## 生产准备清单

### 先讲边界

这个仓库当前提供的是“生产准备入口”和“低成本验证环境”，不是现成的官方生产部署。

真正准备对公网提供服务时，建议拆成两段：

- `阶段 A：production-ready beta`
  先把真实短信、真实推送、真实存储、真实监控跑稳，但先不承诺 SGX 能力。
- `阶段 B：full production track`
  再补 `CDS`、`SVR2`、可能的 `Key Transparency`，以及更严格的安全和合规要求。

### 必买服务清单

#### 云与平台账号

- `AWS`
  - `DynamoDB`
  - `S3`
  - `IAM`
  - 建议再配 `KMS`、日志与告警服务
- `GCP` / `Firebase`
  - `Firestore`
  - `Bigtable`
  - `Pub/Sub`
  - `FCM`
  - 需要可计费项目
- `Apple Developer Program`
  - iOS 构建、签名、`APNs`、App Store Connect
- `Google Play Console`
  - Android 分发、签名、店内配置
- 短信供应商
  - `Twilio Verify` 或 `MessageBird`
- 基础网络
  - 域名
  - DNS
  - TLS 证书
  - CDN / WAF

#### 基础服务节点建议

以下是适合“小规模公网 beta”的保守起步值，不是官方最低值：

| 组件 | 建议起步 |
| --- | --- |
| `Signal-Server` | `3` 台 `4 vCPU / 16 GB RAM` |
| `registration-service` | `2` 台 `2 vCPU / 8 GB RAM` |
| 反向代理 / API Gateway | `2` 台 `2 vCPU / 4 GB RAM` |
| `TURN` | `2` 台 `4 vCPU / 8 GB RAM` |
| `Redis` | `3` 节点，建议托管或至少 `4 vCPU / 16 GB RAM` 级别 |

推断说明：

- `DynamoDB`、`S3`、`Firestore`、`Bigtable`、`Pub/Sub` 更适合直接买托管服务，而不是自己造等价物。
- 上面的主机规格更像“beta 的起步配置”，不是“大规模上线”的终态配置。

### 阶段 A：production-ready beta 清单

#### 应用与基础设施

- 把本地 `DynamoDB Local` 替换成真实 `DynamoDB`
- 把本地 `MinIO` 替换成真实 `S3`
- 把本地 dummy `GCP` 配置替换成真实 `Firestore`、`Bigtable`、`Pub/Sub`
- 把本地 `Redis` 单节点 cluster 替换成托管或多节点高可用 Redis
- 用正式域名和正式 TLS
- 把 secrets 从本地文件迁移到密钥管理系统

#### 账号与移动端能力

- 配置真实 `APNs` key
- 配置真实 `FCM` 项目
- 配置真实短信渠道
- 建好 iOS 与 Android 的签名和发布流水线
- 为 Desktop / Android / iOS 准备与环境对应的后端地址策略

#### 运维与安全

- 指标监控
- 应用日志与审计日志
- 告警值班
- 备份与恢复演练
- 漏洞扫描和依赖升级节奏
- 访问控制与最小权限
- 速率限制和 WAF
- 灰度与回滚机制

#### 放量前验收

- 真实短信验证码注册通过
- `APNs` / `FCM` 推送打通
- Android 主设备注册通过
- Desktop link-device 通过
- iOS 测试设备注册通过
- 压测、限流、告警和恢复流程跑过

### 阶段 B：full production track 清单

#### 需要额外补齐的能力

- `Contact Discovery Service`
- `SVR2` / `SVRB`
- 更完整的 `Key Transparency` 路线
- 远程度量、证明与信任硬件运维流程

#### SGX 服务器与部署提醒

当前公开云里最容易拿到的 `Intel SGX` 机型是 Azure 的 `DCsv3 / DCdsv3` 系列。Azure 官方目前仍把这两代作为 SGX 机型族群说明；`DCdsv3` 公开规格里可见：

- `Standard_DC4ds_v3`: `4 vCPU / 32 GB / 16 GiB EPC`
- `Standard_DC8ds_v3`: `8 vCPU / 64 GB / 32 GiB EPC`
- `Standard_DC16ds_v3`: `16 vCPU / 128 GB / 64 GiB EPC`
- `Standard_DC48ds_v3`: `48 vCPU / 384 GB / 256 GiB EPC`

这里有个重要限制：

- Azure 官方文档明确写到，`DCsv3` 和 `DCdsv3` 不兼容 Intel 的 attestation service。
- 这意味着你在决定上 Azure 跑 `CDS` / `SVR2` 前，必须先验证上游软件链路与 Azure attestation 的兼容性。

#### SGX 起步建议

这是工程上的保守建议，不是官方要求：

- `Contact Discovery Service`
  - 先从 `2 x Standard_DC4ds_v3` 开始
  - 更稳妥可以直接 `2 x Standard_DC8ds_v3`
- `SVR2`
  - 至少 `3 x Standard_DC8ds_v3`
  - 用户量上来再考虑 `3 x Standard_DC16ds_v3`

#### SGX 子清单

- 选定云厂商和地区
- 确认 attestation 路径
- 确认 EPC 容量和 enclave 尺寸
- 建立 enclave 构建、签名、发布流程
- 建立 enclave 升级和回滚流程
- 做故障演练和证明链校验

### 什么时候从测试切到生产准备

满足下面这些条件，再从“省钱测试”切到“生产准备”最合适：

- 本地 smoke test 已稳定
- Desktop standalone 已稳定
- 团队已经需要真实短信或真实推送
- 团队准备让外部用户接入
- 你已经接受“多云 + 多服务 + 合规与运维成本”这一现实

## 官方参考

- `registration-service` README：
  [signalapp/registration-service](https://github.com/signalapp/registration-service)
- `SecureValueRecovery2`：
  [signalapp/SecureValueRecovery2](https://github.com/signalapp/SecureValueRecovery2)
- Apple Developer Program 费用与权益：
  [Membership Details - Apple Developer Program](https://developer.apple.com/programs/whats-included/)
- APNs token 配置：
  [Communicate with APNs using authentication tokens](https://developer.apple.com/help/account/capabilities/communicate-with-apns-using-authentication-tokens/)
- Firebase 价格页：
  [Firebase Pricing](https://firebase.google.com/pricing)
- Firebase Blaze 计费计划：
  [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
- Bigtable 价格：
  [Bigtable pricing](https://cloud.google.com/bigtable/pricing)
- Pub/Sub 价格：
  [Pub/Sub pricing](https://cloud.google.com/pubsub/pricing)
- Firestore 价格：
  [Firestore](https://cloud.google.com/products/firestore)
- Twilio Verify 价格：
  [Verify Pricing](https://www.twilio.com/en-us/verify/pricing)
- Google Play 服务费说明：
  [Changes to Google Play's service fee in 2021](https://support.google.com/googleplay/android-developer/answer/10632485)
- Azure SGX VM 家族：
  [DC family VM size series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/dc-family)
- Azure SGX 证明说明：
  [Attestation for SGX enclaves](https://learn.microsoft.com/en-us/azure/confidential-computing/attestation)
- Azure `DCdsv3` 规格表：
  [DCdsv3 系列大小](https://learn.microsoft.com/zh-tw/azure/virtual-machines/sizes/general-purpose/dcdsv3-series)
