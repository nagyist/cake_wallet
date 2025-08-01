import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:convert/convert.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_bitcoin/psbt.dart';

class PSBTTransactionBuild {
  final PsbtV2 psbt = PsbtV2();

  PSBTTransactionBuild(
      {required List<PSBTReadyUtxoWithAddress> inputs, required List<BitcoinBaseOutput> outputs, required List<OutputInfo> cwOutputs, bool enableRBF = true}) {
    psbt.setGlobalTxVersion(2);
    psbt.setGlobalInputCount(inputs.length);
    psbt.setGlobalOutputCount(outputs.length);

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];

      printV(input.utxo.isP2tr());
      printV(input.utxo.isSegwit());
      printV(input.utxo.isP2shSegwit());

      psbt.setInputPreviousTxId(i, Uint8List.fromList(hex.decode(input.utxo.txHash).reversed.toList()));
      psbt.setInputOutputIndex(i, input.utxo.vout);
      psbt.setInputSequence(i, enableRBF ? 0x1 : 0xffffffff);
      

      if (input.utxo.isSegwit()) {
        setInputSegwit(i, input);
      } else if (input.utxo.isP2shSegwit()) {
        setInputP2shSegwit(i, input);
      } else if (input.utxo.isP2tr()) {
        // ToDo: (Konsti) Handle Taproot Inputs
      } else {
        setInputP2pkh(i, input);
      }
    }

    for (var i = 0; i < outputs.length; i++) {
      final output = outputs[i];

      if (output is BitcoinOutput) {
        psbt.setOutputScript(i, Uint8List.fromList(output.address.toScriptPubKey().toBytes()));
        psbt.setOutputAmount(i, output.value.toInt());
        if (cwOutputs.isNotEmpty) {
          try {
            final cwOutput = cwOutputs
            .where((e) => [e.address, e.extractedAddress]
              .map((e) => e?.toLowerCase())
              .contains(output.address.toAddress().toLowerCase()))
            .firstOrNull;
            if (cwOutput != null) {
              final bip353Name = utf8.encode(cwOutput.extra['bip353_name'] as String);
              final bip353Proof = base64.decode(cwOutput.extra['bip353_proof'] as String);

              if (bip353Name.length > 255) {
                printV('BIP353 name is too long, skipping');
                continue;
              }
              final proof = Uint8List.fromList([
                bip353Name.length,
                ...bip353Name,
                ...bip353Proof,
              ]);

              psbt.setOutputDNSSECProof(i, proof);
            }
          } catch (e) {
            printV('Error setting DNSSEC proof: $e');
          }
        }
      }
    }
  }

  void setInputP2pkh(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(
        i,
        Uint8List.fromList(hex.decode(input.ownerPublicKey)),
        input.ownerMasterFingerprint,
        BIPPath.fromString(input.ownerDerivationPath).toPathArray());
  }

  void setInputSegwit(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(
        i,
        Uint8List.fromList(hex.decode(input.ownerPublicKey)),
        input.ownerMasterFingerprint,
        BIPPath.fromString(input.ownerDerivationPath).toPathArray());

    psbt.setInputWitnessUtxo(i, Uint8List.fromList(bigIntToUint64LE(input.utxo.value)),
        Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()));
  }

  void setInputP2shSegwit(int i, PSBTReadyUtxoWithAddress input) {
    psbt.setInputNonWitnessUtxo(i, Uint8List.fromList(hex.decode(input.rawTx)));
    psbt.setInputBip32Derivation(i, Uint8List.fromList(hex.decode(input.ownerPublicKey)),
        input.ownerMasterFingerprint, BIPPath.fromString(input.ownerDerivationPath).toPathArray());

    psbt.setInputRedeemScript(
        i, Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()));
    psbt.setInputWitnessUtxo(i, Uint8List.fromList(bigIntToUint64LE(input.utxo.value)),
        Uint8List.fromList(input.ownerDetails.address.toScriptPubKey().toBytes()));
  }
}

class PSBTReadyUtxoWithAddress extends UtxoWithAddress {
  final String rawTx;
  final String ownerDerivationPath;
  final Uint8List ownerMasterFingerprint;
  final String ownerPublicKey;

  PSBTReadyUtxoWithAddress({
    required super.utxo,
    required this.rawTx,
    required super.ownerDetails,
    required this.ownerDerivationPath,
    required this.ownerMasterFingerprint,
    required this.ownerPublicKey,
  });
}
