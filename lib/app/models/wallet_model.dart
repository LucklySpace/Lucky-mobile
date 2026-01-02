/// 钱包信息模型
class WalletVo {
  final String address; // 钱包地址
  final String userId; // 用户ID
  final String balance; // 余额
  final String frozenBalance; // 冻结余额
  final int nonce; // 交易计数

  WalletVo({
    required this.address,
    required this.userId,
    required this.balance,
    required this.frozenBalance,
    required this.nonce,
  });

  factory WalletVo.fromJson(Map<String, dynamic> json) {
    return WalletVo(
      address: json['address']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.00000000',
      frozenBalance: json['frozenBalance']?.toString() ?? '0.00000000',
      nonce: json['nonce'] is int
          ? json['nonce']
          : int.tryParse(json['nonce']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'userId': userId,
      'balance': balance,
      'frozenBalance': frozenBalance,
      'nonce': nonce,
    };
  }
}

/// 交易记录模型
class TransactionVo {
  final String transactionId; // 交易ID
  final String senderAddress; // 发送方地址
  final String receiverAddress; // 接收方地址
  final String amount; // 金额
  final int timestamp; // 时间戳
  final int nonce; // 随机数
  final String fee; // 手续费
  final int orderType; // 订单类型
  final int status; // 状态
  final String? blockHash; // 区块哈希

  TransactionVo({
    required this.transactionId,
    required this.senderAddress,
    required this.receiverAddress,
    required this.amount,
    required this.timestamp,
    required this.nonce,
    required this.fee,
    required this.orderType,
    required this.status,
    this.blockHash,
  });

  TransactionStatus get statusEnum => TransactionStatus.fromValue(status);

  TransactionType get typeEnum => TransactionType.fromValue(orderType);

  factory TransactionVo.fromJson(Map<String, dynamic> json) {
    return TransactionVo(
      transactionId: json['transactionId']?.toString() ?? '',
      senderAddress: json['senderAddress']?.toString() ?? '',
      receiverAddress: json['receiverAddress']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00000000',
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      nonce: json['nonce'] is int
          ? json['nonce']
          : int.tryParse(json['nonce']?.toString() ?? '0') ?? 0,
      fee: json['fee']?.toString() ?? '0.00000000',
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      orderType: json['orderType'] is int
          ? json['orderType']
          : int.tryParse(json['orderType']?.toString() ?? '0') ?? 0,
      blockHash: json['blockHash']?.toString(),
    );
  }
}

/// 交易类型枚举
enum TransactionType {
  unknown(0, 'unknown', '未知类型'),
  transfer(1, 'transfer', '转账'),
  payment(2, 'payment', '支付'),
  fee(3, 'fee', '手续费'),
  reward(4, 'reward', '奖励');

  final int value;
  final String key;
  final String description;

  const TransactionType(this.value, this.key, this.description);

  static TransactionType fromValue(int value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.unknown,
    );
  }
}

/// 交易状态枚举
enum TransactionStatus {
  unknown(0, '未知状态'),
  awaitConfirm(1, '待确认'),
  pending(2, '确认中'),
  success(3, '交易成功'),
  failed(4, '交易失败'),
  returned(5, '已退回'),
  cancelled(6, '已取消'),
  expired(7, '已过期');

  final int value;
  final String description;

  const TransactionStatus(this.value, this.description);

  static TransactionStatus fromValue(int value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionStatus.unknown,
    );
  }
}

/// 转账请求模型
class TransferRequest {
  final String from;
  final String to;
  final String amount;
  final int timestamp;
  final int nonce;
  final String fee;
  final String signature;

  TransferRequest({
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.nonce,
    required this.fee,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'timestamp': timestamp,
      'nonce': nonce,
      'fee': fee,
      'signature': signature,
    };
  }
}

/// 手续费模式
enum FeeMode {
  fixed,
  percentage;

  static FeeMode fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'FIXED':
        return FeeMode.fixed;
      case 'PERCENTAGE':
        return FeeMode.percentage;
      default:
        return FeeMode.fixed;
    }
  }
}

/// 手续费对象
class FeeVo {
  final FeeMode feeMode;
  final String fee;

  FeeVo({
    required this.feeMode,
    required this.fee,
  });

  factory FeeVo.fromJson(Map<String, dynamic> json) {
    return FeeVo(
      feeMode: FeeMode.fromString(json['feeMode']?.toString()),
      fee: json['fee']?.toString() ?? '0.00000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeMode': feeMode.name.toUpperCase(),
      'fee': fee,
    };
  }
}
