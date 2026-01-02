# IM Wallet 接口文档

> 基于 Spring Boot 3.2 与 WebFlux 的钱包与支付服务。默认端口：`9600`
>
> Knife4j 文档入口：`/doc.html`，swagger-ui：`/swagger-ui/index.html`

## 基本信息

- 基础路径：`/api` 或带版本前缀的 `/api/{version}`
- 响应格式：`application/json`
- 时间单位：毫秒时间戳（`Long`）
- 货币精度：`BigDecimal`，精度 `scale=8`

---

## 钱包 Wallet

- 创建钱包
  - `POST /api/wallet/create`
  - 返回：`WalletVo`

- 获取钱包信息（按地址）
  - `GET /api/wallet/{address}`
  - 路径参数：`address`（40位16进制）
  - 返回：`WalletVo`

- 为用户创建钱包（单用户唯一）
  - `POST /api/wallet/user/{userId}/create`
  - 路径参数：`userId`（非空）
  - 返回：`WalletVo`

- 获取钱包信息（按用户）
  - `GET /api/wallet/user/{userId}`
  - 路径参数：`userId`（非空）
  - 返回：`WalletVo`

- 获取交易历史（按地址）
  - `GET /api/wallet/{address}/history?page=0&size=20`
  - 路径参数：`address`（40位16进制）
  - 查询参数：`page`、`size`
  - 返回：`TransactionVo[]`

- 获取交易历史（按用户）
  - `GET /api/wallet/user/{userId}/history?page=0&size=20`
  - 路径参数：`userId`（非空）
  - 查询参数：`page`、`size`
  - 返回：`TransactionVo[]`

---

## 支付 Payment

请求体模型 `TransferRequest`：
```
{
  "from": "40位16进制地址",
  "to": "40位16进制地址",
  "amount": "12.50000000",
  "timestamp": 1735555555555,
  "nonce": 123,
  "fee": "0.01000000",
  "signature": "签名字符串"
}
```

- 直接付款（无需确认，立即入账）
  - `POST /api/payment/pay`
  - Body：`TransferRequest`
  - 返回：`TransactionVo`

- 发起转账（生成待确认交易）
  - `POST /api/payment/transfer`
  - Body：`TransferRequest`
  - 返回：`TransactionVo`

- 确认收款（接收方）
  - `POST /api/payment/confirm?txId={txId}&receiverAddress={addr}`
  - 查询参数：`txId`（交易ID64位16进制）、`receiverAddress`（40位16进制）
  - 返回：`TransactionVo`

- 退回转账（接收方拒收）
  - `POST /api/payment/return?txId={txId}&receiverAddress={addr}`
  - 查询参数：同上
  - 返回：`TransactionVo`

- 取消转账（发送方撤销）
  - `POST /api/payment/cancel?txId={txId}&senderAddress={addr}`
  - 查询参数：`txId`、`senderAddress`（40位16进制）
  - 返回：`TransactionVo`

---
---

## 数据模型摘要

- `WalletVo`：`address`、`userId`、`balance`、`frozenBalance`、`nonce` 等
- `TransactionVo`：`transactionId`、`senderAddress`、`receiverAddress`、`amount`、`timestamp`、`nonce`、`fee`、`status`、`blockHash`
- `BlockVo`：`hash`、`previousHash`、`height`、`timestamp`、`nonce`、`validator`、`merkleRoot`
- `ReceivedTotalVo`：按当日统计维度的汇总字段

---

## 约束与规则

- 地址格式：`^[0-9a-f]{40}$`（允许大小写，服务端统一规范化）
- 交易ID格式：`^[0-9a-f]{64}$`
- 交易哈希生成：`sha256(from + to + amount + fee + nonce + timestamp + signature)`
- PoW 难度：哈希前缀 4 个 `0`（联盟链模式不强制）
- Merkle 根重算时排除系统奖励交易

---

## 示例

直接付款：
```
POST /api/payment/pay
Content-Type: application/json

{
  "from": "0000000000000000000000000000000000000001",
  "to":   "0000000000000000000000000000000000000002",
  "amount": "10.00000000",
  "timestamp": 1735555555555,
  "nonce": 1,
  "fee": "0.01000000",
  "signature": "BASE64_ECDSA_SIGNATURE"
}
```

