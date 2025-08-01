import 'dart:convert';

import 'package:cw_evm/evm_chain_client.dart';
import 'package:cw_evm/.secrets.g.dart' as secrets;
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

class PolygonClient extends EVMChainClient {
  @override
  Transaction createTransaction({
    required EthereumAddress from,
    required EthereumAddress to,
    required EtherAmount amount,
    EtherAmount? maxPriorityFeePerGas,
    Uint8List? data,
    int? maxGas,
    EtherAmount? gasPrice,
    EtherAmount? maxFeePerGas,
  }) {
    EtherAmount? finalGasPrice = gasPrice;

    if (gasPrice == null && maxFeePerGas != null) {
      // If we have EIP-1559 parameters but no legacy gasPrice, then use maxFeePerGas as gasPrice
      finalGasPrice = maxFeePerGas;
    }
    
    return Transaction(
      from: from,
      to: to,
      value: amount,
      data: data,
      maxGas: maxGas,
      gasPrice: finalGasPrice,
      // maxFeePerGas: maxFeePerGas,
      // maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  @override
  int get chainId => 137;

  @override
  Future<List<EVMChainTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await client.get(Uri.https("api.etherscan.io", "/v2/api", {
        "chainid": "$chainId",
        "module": "account",
        "action": contractAddress != null ? "tokentx" : "txlist",
        if (contractAddress != null) "contractaddress": contractAddress,
        "address": address,
        "apikey": secrets.etherScanApiKey,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        return (jsonResponse['result'] as List)
            .map(
              (e) => EVMChainTransactionModel.fromJson(e as Map<String, dynamic>, 'MATIC'),
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<EVMChainTransactionModel>> fetchInternalTransactions(String address) async {
    try {
      final response = await client.get(Uri.https("api.etherscan.io", "/v2/api", {
        "chainid": "$chainId",
        "module": "account",
        "action": "txlistinternal",
        "address": address,
        "apikey": secrets.etherScanApiKey,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        return (jsonResponse['result'] as List)
            .map((e) => EVMChainTransactionModel.fromJson(e as Map<String, dynamic>, 'MATIC'))
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }
}
