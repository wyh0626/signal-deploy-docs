# SGX 说明

English: [./en/sgx.md](./en/sgx.md)

## SGX 是什么

SGX 是 Intel 提供的一种 TEE（Trusted Execution Environment，可信执行环境）技术。

可以把它理解成：

- 在 CPU 里开辟一个受保护的 enclave
- enclave 内部的数据和代码，对宿主机上普通进程、root 用户甚至部分运维人员都不可见
- enclave 可以通过远程证明告诉外部：“我运行的是某个特定、可验证的程序”

常见关键词：

- enclave
  受保护执行区域
- remote attestation
  远程证明，用来验证远端 enclave 的身份和测量值
- sealing
  把 enclave 内的数据安全地持久化

## Signal 在这里为什么需要 SGX

Signal 并不是把所有服务都放进 SGX，而是把“特别依赖最小信任面”的那类能力放进去。

典型原因有两个：

- Contact Discovery
  希望通讯录匹配尽量不暴露原始联系人数据给服务运营方
- Secure Value Recovery
  希望 PIN/恢复材料的处理尽量不暴露给普通服务端环境

换句话说，SGX 在这里不是为了“跑得更快”，而是为了“让服务运营者也更难看到敏感内容”。

## 这个仓库里 SGX 相关能力现在怎么处理

当前 dev stack 的处理方式是：

- 不部署 SGX 服务
- 对必须存在的配置做 stub 或 dummy
- 把本地验证重点放在账号注册、配置加载、对象存储、Desktop 联通性上

这也是为什么当前仓库适合做：

- 本地开发
- 调试桌面端
- 学习 Signal 服务端结构

但不适合直接宣称“已接近官方生产环境”。

## 如果未来要部署 SGX，大致要补什么

典型前提包括：

- 支持 SGX 的 Intel 硬件
- BIOS 里启用 SGX
- 对应的宿主机驱动、运行时和 quote provider
- 远程证明链路
- 针对 enclave 镜像和密钥的部署体系
- 对应服务自己的运维手册、监控和密钥轮换策略

这通常已经不是“Docker Compose 补几个容器”的量级，而是：

- 专门的裸机或严格控制的宿主机集群
- 明确的硬件型号与固件策略
- 独立的安全与运维流程

## 学习建议

建议按这个顺序学习：

1. 先理解 TEE、enclave、远程证明、密钥封存这些基本概念
2. 再看 Signal 为什么把 CDS / SVR2 这类能力放进可信硬件
3. 最后再看具体部署链路，包括驱动、quote、PCCS、镜像构建和远程证明接入

比较适合作为学习入口的资料方向：

- Intel SGX 基础概念与架构资料
- SGX/DCAP 远程证明相关资料
- `signalapp/ContactDiscoveryService`
- `signalapp/SecureValueRecovery2`
- 可信执行环境相关容器化/编排实践

## 对这个仓库的建议

至少在当前阶段，不建议把 SGX 服务硬塞进默认一键部署里。更合理的做法是：

- 当前仓库继续保持“无 SGX 的本地开发栈”
- 后续单独开 `docs/sgx-deployment.md` 或新分支，专门记录 SGX 实验与生产化方案
- 把“本地可开发”和“可信硬件生产部署”明确分层
