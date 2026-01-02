import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../utils/Ndef.dart';

class PaymentIntent {
  final String address;
  final String? amount;

  PaymentIntent({required this.address, this.amount});
}

class NfcService extends GetxService {
  static NfcService get to => Get.find();

  final RxBool scanning = false.obs;

  Future<NfcService> init() async {
    return this;
  }

  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    scanning.value = false;
  }

  Future<void> startPaymentSession(
      Future<void> Function(PaymentIntent) onFound) async {
    if (scanning.value) return;
    final available = await isAvailable();
    if (!available) {
      Get.snackbar('提示', '设备不支持或未开启NFC', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    scanning.value = true;
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        final intent = await _parsePaymentIntent(tag);
        if (intent != null) {
          await onFound(intent);
        } else {
          Get.snackbar('提示', '未识别到有效支付信息', snackPosition: SnackPosition.BOTTOM);
        }
        await stopSession();
      },
    );
  }

  Future<PaymentIntent?> _parsePaymentIntent(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null || !ndef.isWritable) return null;
    try {
      final message = await ndef.read();
      if (message == null) return null;
      for (final record in message.records) {
        final text = _decodeRecord(record);
        final intent = _tryParseText(text);
        if (intent != null) return intent;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _decodeRecord(NdefRecord record) {
    try {
      final typeStr = String.fromCharCodes(record.type);
      final payload = record.payload;
      if (typeStr == 'T' && payload.isNotEmpty) {
        final status = payload[0];
        final langLen = status & 0x3F;
        final textBytes = payload.sublist(1 + langLen);
        return utf8.decode(textBytes);
      }
      return utf8.decode(payload);
    } catch (_) {
      try {
        return utf8.decode(record.payload);
      } catch (_) {
        return '';
      }
    }
  }

  PaymentIntent? _tryParseText(String text) {
    if (text.isEmpty) return null;
    try {
      final map = jsonDecode(text);
      if (map is Map) {
        final address = (map['address'] ?? map['to'] ?? '').toString();
        final amount = map['amount']?.toString();
        if (address.isNotEmpty) {
          return PaymentIntent(address: address, amount: amount);
        }
      }
    } catch (_) {}
    final addressMatch = RegExp(r'(0x[a-fA-F0-9]{40})').firstMatch(text);
    final amountMatch =
        RegExp(r'amount[:=]\s*([0-9]+(?:\.[0-9]+)?)').firstMatch(text);
    if (addressMatch != null) {
      final addr = addressMatch.group(1)!;
      final amt = amountMatch?.group(1);
      return PaymentIntent(address: addr, amount: amt);
    }
    return null;
  }

  Future<void> startWriteSession(String address, String? amount) async {
    if (scanning.value) return;
    final available = await isAvailable();
    if (!available) {
      Get.snackbar('提示', '设备不支持或未开启NFC', snackPosition: SnackPosition.TOP);
      return;
    }
    scanning.value = true;

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso18092},
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          Get.snackbar('错误', '不支持NDEF标签', snackPosition: SnackPosition.TOP);
          await stopSession();
          return;
        }
        if (!ndef.isWritable) {
          Get.snackbar('错误', '标签不可写', snackPosition: SnackPosition.TOP);
          await stopSession();
          return;
        }
        Map<String, dynamic> data = {'address': address};
        if (amount != null && amount.isNotEmpty) data['amount'] = amount;

        final record = NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown, // 类型名称格式为已知类型
          type: ascii.encode('U'), // 类型名称为 'U'
          identifier: Uint8List(0), // 标识符为空
          payload: Uint8List.fromList([
            // 负载数据
            0x03, // 二进制数据
            ...utf8.encode(jsonEncode(data)), // UTF-8 编码的字符串 'example.com'
          ]),
        );

        final message = NdefMessage(records: [record]);
        try {
          await ndef.write(message: message);
          Get.snackbar('成功', '支付信息已写入标签', snackPosition: SnackPosition.TOP);
        } catch (e) {
          Get.snackbar('错误', '写入失败: $e', snackPosition: SnackPosition.TOP);
        } finally {
          await stopSession();
        }
      },
    );
  }
}
