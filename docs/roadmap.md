# 路线图

English: [./en/roadmap.md](./en/roadmap.md)

这份路线图不是“全部都要今天做完”，而是给后续维护一个清晰顺序。

## Phase 1: 稳定本地后端

目标：

- `./scripts/dev-up.sh` 一键拉起后端
- `./scripts/dev-up.sh --smoke-test` 一键验证关键链路
- 分支、补丁、文档和版本清单对齐

这是当前仓库已经具备的基础。

## Phase 2: 桌面端 demo

目标：

- `Signal-Desktop` 能通过 `Standalone Device` 接到本地后端
- README 和 `docs/desktop-local.md` 给出明确操作步骤
- 明确哪些桌面能力只是 fallback，不作为演示重点

为什么值得做：

- 上手快
- 适合给外部读者演示“这套本地环境真的活着”
- 能把服务端注册链路和前端调试串起来

## Phase 3: Android 主设备

目标：

- 准备一个直连本地服务的 Android 版
- 让它能做主设备注册
- 后续为 Desktop `Link Device` 提供真实主设备来源

这是扫码链路成立的关键一步。

## Phase 4: iOS 开发准备

目标：

- 跑通 iOS 本地构建
- 梳理签名、证书、Provisioning Profile、APNs 等先决条件
- 明确“能本地安装调试”和“能对外发布 TestFlight/App Store”是两件不同的事

现实前提：

- 需要 Apple Developer Program
- 需要设备签名和能力配置
- 后续如果要真实推送，还需要 APNs 配置

## Phase 5: 更像生产的基础设施

目标：

- 多节点 Redis
- 真实 FoundationDB
- 可观测性、备份、持久化和故障演练

注意：

- 这一步和当前本地开发文档是不同层级的工作
- 建议单独做 prod-like 文档，不要直接塞进默认 `docker-compose.yml`

## Phase 6: 面向发布的移动端准备

Android 方向：

- Firebase/FCM 凭证
- Play Console
- 应用签名、版本号、测试轨道

iOS 方向：

- Apple Developer Program
- Bundle ID、Capabilities、Provisioning
- App Store Connect
- APNs key/cert
- TestFlight / App Store 发布流程

## 最推荐的推进顺序

1. 持续维护本地后端文档
2. 把 Desktop standalone demo 做稳
3. 增加 Android 主设备本地接入
4. 再考虑 iOS 开发接入
5. 最后再拆出生产化和 SGX 专题
