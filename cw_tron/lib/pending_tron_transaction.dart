

import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';

class PendingTronTransaction with PendingTransaction {
  final Function sendTransaction;
  final List<int> signedTransaction;
  final String fee;
  final String amount;

  PendingTronTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.amount,
  });

  @override
  String get amountFormatted => amount;

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted => "$feeFormattedValue TRX";

  @override
  String get feeFormattedValue => fee;

  @override
  String get hex => bytesToHex(signedTransaction);

  @override
  String get id => '';
  
  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
