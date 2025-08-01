import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/open_crypto_pay/models.dart';
import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/evm_transaction_error_fees_handler.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'send_view_model.g.dart';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    currencies = wallet.balance.keys.toList();
    selectedCryptoCurrency = wallet.currency;
    hasMultipleTokens = isEVMCompatibleChain(wallet.type) ||
        wallet.type == WalletType.solana ||
        wallet.type == WalletType.tron ||
        wallet.type == WalletType.zano;
  }

  UnspentCoinsListViewModel unspentCoinsListViewModel;

  SendViewModelBase(
    AppStore appStore,
    this.sendTemplateViewModel,
    this._fiatConversationStore,
    this.balanceViewModel,
    this.contactListViewModel,
    this.transactionDescriptionBox,
    this.ledgerViewModel,
    this.unspentCoinsListViewModel,
    this.feesViewModel, {
    this.coinTypeToSpendFrom = UnspentCoinType.nonMweb,
  })  : state = InitialExecutionState(),
        currencies = appStore.wallet!.balance.keys.toList(),
        selectedCryptoCurrency = appStore.wallet!.currency,
        hasMultipleTokens = isEVMCompatibleChain(appStore.wallet!.type) ||
            appStore.wallet!.type == WalletType.solana ||
            appStore.wallet!.type == WalletType.tron ||
            appStore.wallet!.type == WalletType.zano,
        outputs = ObservableList<Output>(),
        _settingsStore = appStore.settingsStore,
        fiatFromSettings = appStore.settingsStore.fiatCurrency,
        super(appStore: appStore) {
    outputs
        .add(Output(wallet, _settingsStore, _fiatConversationStore, () => selectedCryptoCurrency));

    unspentCoinsListViewModel.initialSetup().then((_) {
      unspentCoinsListViewModel.resetUnspentCoinsInfoSelections();
    });
  }

  @observable
  ExecutionState state;

  ObservableList<Output> outputs;

  @observable
  UnspentCoinType coinTypeToSpendFrom;

  bool get showAddressBookPopup => _settingsStore.showAddressBookPopupEnabled;

  @action
  void setShowAddressBookPopup(bool value) {
    _settingsStore.showAddressBookPopupEnabled = value;
  }

  @action
  void addOutput() {
    outputs
        .add(Output(wallet, _settingsStore, _fiatConversationStore, () => selectedCryptoCurrency));
  }

  @action
  void removeOutput(Output output) {
    if (isBatchSending) {
      outputs.remove(output);
    }
  }

  @action
  void clearOutputs() {
    outputs.clear();
    addOutput();
  }

  @action
  void setAllowMwebCoins(bool allow) {
    if (wallet.type == WalletType.litecoin) {
      coinTypeToSpendFrom = allow ? UnspentCoinType.any : UnspentCoinType.nonMweb;
    }
  }

  @computed
  bool get isBatchSending => outputs.length > 1;

  bool get shouldDisplaySendALL {
    if (walletType == WalletType.solana) return false;

    // if (walletType == WalletType.ethereum && selectedCryptoCurrency == CryptoCurrency.eth)
    // return false;

    // if (walletType == WalletType.polygon && selectedCryptoCurrency == CryptoCurrency.maticpoly)
    // return false;

    return true;
  }

  @computed
  String get pendingTransactionFiatAmount {
    if (pendingTransaction == null) {
      return '0.00';
    }

    try {
      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[selectedCryptoCurrency]!,
          cryptoAmount: pendingTransaction!.amountFormatted);
      return fiat;
    } catch (_) {
      return '0.00';
    }
  }

  @computed
  String get pendingTransactionFeeFiatAmount {
    try {
      if (pendingTransaction != null) {
        final currency = pendingTransactionFeeCurrency(walletType);
        final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[currency]!,
          cryptoAmount: pendingTransaction!.feeFormattedValue,
        );
        return fiat;
      } else {
        return '0.00';
      }
    } catch (_) {
      return '0.00';
    }
  }

  CryptoCurrency pendingTransactionFeeCurrency(WalletType type) {
    switch (type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.tron:
      case WalletType.solana:
        return wallet.currency;
      default:
        return selectedCryptoCurrency;
    }
  }

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  CryptoCurrency get currency => wallet.currency;

  Validator<String> amountValidator(Output output) => AmountValidator(
        currency: walletTypeToCryptoCurrency(wallet.type),
        minValue: isSendToSilentPayments(output)
            ?
            //  TODO: get from server
            // bitcoin!.silentPaymentsMinAmount
            '0.00001'
            : null,
      );

  Validator<String> get allAmountValidator => AllAmountValidator();

  Validator<String> get addressValidator =>
      AddressValidator(type: selectedCryptoCurrency, isTestnet: wallet.isTestnet);

  Validator<String> get textValidator => TextValidator();

  final FiatCurrency fiatFromSettings;

  @observable
  PendingTransaction? pendingTransaction;

  @computed
  String get balance {
    if (walletType == WalletType.litecoin && coinTypeToSpendFrom == UnspentCoinType.mweb) {
      return balanceViewModel.balances.values.first.secondAvailableBalance;
    } else if (walletType == WalletType.litecoin &&
        coinTypeToSpendFrom == UnspentCoinType.nonMweb) {
      return balanceViewModel.balances.values.first.availableBalance;
    }
    return wallet.balance[selectedCryptoCurrency]!.formattedFullAvailableBalance;
  }

  @action
  Future<void> updateSendingBalance() async {
    // force the sendingBalance to recompute since unspent coins aren't observable
    // or at least mobx can't detect the changes

    final currentType = coinTypeToSpendFrom;

    if (currentType == UnspentCoinType.any) {
      coinTypeToSpendFrom = UnspentCoinType.nonMweb;
    } else if (currentType == UnspentCoinType.nonMweb) {
      coinTypeToSpendFrom = UnspentCoinType.any;
    } else if (currentType == UnspentCoinType.mweb) {
      coinTypeToSpendFrom = UnspentCoinType.nonMweb;
    }

    // set it back to the original value:
    coinTypeToSpendFrom = currentType;
  }

  @computed
  Future<String> get sendingBalance async {
    // only for electrum, monero, wownero, decred wallets atm:
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.decred:
        return wallet.formatCryptoAmount(
            (await unspentCoinsListViewModel.getSendingBalance(coinTypeToSpendFrom)).toString());
      default:
        return balance;
    }
  }

  @computed
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  @computed
  String get pendingTransactionFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFiatAmount + ' ' + fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFeeFiatAmount + ' ' + fiat.title;

  @computed
  bool get isReadyForSend =>
      wallet.syncStatus is SyncedSyncStatus ||
      // If silent payments scanning, can still send payments
      (wallet.type == WalletType.bitcoin && wallet.syncStatus is SyncingSyncStatus);

  bool isSendToSilentPayments(Output output) =>
      wallet.type == WalletType.bitcoin &&
      (RegExp(AddressValidator.silentPaymentAddressPatternMainnet).hasMatch(output.address) ||
          RegExp(AddressValidator.silentPaymentAddressPatternMainnet)
              .hasMatch(output.extractedAddress) ||
          (output.parsedAddress.addresses.isNotEmpty &&
              RegExp(AddressValidator.silentPaymentAddressPatternMainnet)
                  .hasMatch(output.parsedAddress.addresses[0])));

  @computed
  List<Template> get templates => sendTemplateViewModel.templates
      .where((template) => _isEqualCurrency(template.cryptoCurrency))
      .toList();

  @computed
  bool get hasCoinControl => [
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.monero,
        WalletType.wownero,
        WalletType.decred,
        WalletType.bitcoinCash
      ].contains(wallet.type);

  @computed
  bool get isElectrumWallet =>
      [WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash].contains(wallet.type);

  @observable
  CryptoCurrency selectedCryptoCurrency;

  List<CryptoCurrency> currencies;

  bool get hasYat => outputs
      .any((out) => out.isParsedAddress && out.parsedAddress.parseFrom == ParseFrom.yatRecord);

  WalletType get walletType => wallet.type;

  String? get walletCurrencyName => wallet.currency.fullName?.toLowerCase() ?? wallet.currency.name;

  bool get hasCurrecyChanger => walletType == WalletType.haven;

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  final SettingsStore _settingsStore;
  final SendTemplateViewModel sendTemplateViewModel;
  final BalanceViewModel balanceViewModel;
  final ContactListViewModel contactListViewModel;
  final LedgerViewModel? ledgerViewModel;
  final FeesViewModel feesViewModel;
  final FiatConversionStore _fiatConversationStore;
  final Box<TransactionDescription> transactionDescriptionBox;

  @observable
  bool hasMultipleTokens;

  @computed
  List<ContactRecord> get contactsToShow => contactListViewModel.contacts
      .where((element) => element.type == selectedCryptoCurrency)
      .toList();

  @computed
  List<WalletContact> get walletContactsToShow => contactListViewModel.walletContacts
      .where((element) => element.type == selectedCryptoCurrency)
      .toList();

  @action
  bool checkIfAddressIsAContact(String address) {
    final contactList = contactsToShow.where((element) => element.address == address).toList();

    return contactList.isNotEmpty;
  }

  @action
  bool checkIfWalletIsAnInternalWallet(String address) {
    final walletContactList =
        walletContactsToShow.where((element) => element.address == address).toList();

    return walletContactList.isNotEmpty;
  }

  @computed
  bool get shouldDisplayTOTP2FAForContact => _settingsStore.shouldRequireTOTP2FAForSendsToContact;

  @computed
  bool get shouldDisplayTOTP2FAForNonContact =>
      _settingsStore.shouldRequireTOTP2FAForSendsToNonContact;

  @computed
  bool get shouldDisplayTOTP2FAForSendsToInternalWallet =>
      _settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets;

  //* Still open to further optimize these checks
  //* It works but can be made better
  @action
  bool checkThroughChecksToDisplayTOTP(String address) {
    final isContact = checkIfAddressIsAContact(address);
    final isInternalWallet = checkIfWalletIsAnInternalWallet(address);

    if (isContact) {
      return shouldDisplayTOTP2FAForContact;
    } else if (isInternalWallet) {
      return shouldDisplayTOTP2FAForSendsToInternalWallet;
    } else {
      return shouldDisplayTOTP2FAForNonContact;
    }
  }

  bool shouldDisplayTotp() {
    List<bool> conditionsList = [];

    for (var output in outputs) {
      final show = checkThroughChecksToDisplayTOTP(output.extractedAddress);
      conditionsList.add(show);
    }

    return conditionsList.contains(true);
  }

  final _ocpService = OpenCryptoPayService();

  @observable
  OpenCryptoPayRequest? ocpRequest;

  @action
  Future<void> dismissTransaction() async {
    state = InitialExecutionState();
    if (ocpRequest != null) {
      clearOutputs();
      _ocpService.cancelOpenCryptoPayRequest(ocpRequest!);
      ocpRequest = null;
    }
  }

  @action
  Future<PendingTransaction?> createOpenCryptoPayTransaction(String uri) async {
    state = IsExecutingState();

    try {
      final originalOCPRequest = await _ocpService.getOpenCryptoPayInvoice(uri.toString());
      final paymentUri = await _ocpService.getOpenCryptoPayAddress(
        originalOCPRequest,
        selectedCryptoCurrency,
      );

      ocpRequest = originalOCPRequest;

      final paymentRequest = PaymentRequest.fromUri(paymentUri);
      clearOutputs();

      outputs.first.address = paymentRequest.address;
      outputs.first.parsedAddress =
          ParsedAddress(addresses: [paymentRequest.address], name: ocpRequest!.receiverName);
      outputs.first.setCryptoAmount(paymentRequest.amount);
      outputs.first.note = ocpRequest!.receiverName;

      return createTransaction();
    } catch (e) {
      printV(e);
      state = FailureState(translateErrorMessage(e, walletType, currency));
      return null;
    }
  }

  Timer? _ledgerTxStateTimer;

  @action
  Future<PendingTransaction?> createTransaction({ExchangeProvider? provider}) async {
    try {
      if (!(state is IsExecutingState)) state = IsExecutingState();

      if (wallet.isHardwareWallet) {
        state = IsAwaitingDeviceResponseState();
        if (walletType == WalletType.monero)
          _ledgerTxStateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            if (monero!.getLastLedgerCommand() == "INS_CLSAG") {
              timer.cancel();
              state = IsDeviceSigningResponseState();
            }
          });
      }

      pendingTransaction = await wallet.createTransaction(_credentials(provider));

      if (provider is ThorChainExchangeProvider) {
        final outputCount = pendingTransaction?.outputCount ?? 0;
        if (outputCount > 10) {
          throw Exception("THORChain does not support more than 10 outputs");
        }

        if (_hasTaprootInput(pendingTransaction)) {
          throw Exception("THORChain does not support Taproot addresses");
        }
      }

      if (wallet.type == WalletType.bitcoin) {
        final updatedOutputs = bitcoin!.updateOutputs(pendingTransaction!, outputs);

        if (outputs.length == updatedOutputs.length) {
          outputs.replaceRange(0, outputs.length, updatedOutputs);
        }
      }

      state = ExecutedSuccessfullyState();
      return pendingTransaction;
    } catch (e) {
      _ledgerTxStateTimer?.cancel();
      // if (e is LedgerException) {
      //   final errorCode = e.errorCode.toRadixString(16);
      //   final fallbackMsg =
      //       e.message.isNotEmpty ? e.message : "Unexpected Ledger Error Code: $errorCode";
      //   final errorMsg = ledgerViewModel!.interpretErrorCode(errorCode) ?? fallbackMsg;
      //
      //   state = FailureState(errorMsg);
      // } else {
      state = FailureState(translateErrorMessage(e, wallet.type, wallet.currency));
      // }
    }
    return null;
  }

  @action
  Future<void> replaceByFee(TransactionInfo tx, String newFee) async {
    state = IsExecutingState();

    try {
      final isSufficient = await bitcoin!.isChangeSufficientForFee(wallet, tx.id, newFee);

      if (!isSufficient) {
        state = AwaitingConfirmationState(
            title: S.current.confirm_fee_deduction,
            message: S.current.confirm_fee_deduction_content,
            onConfirm: () async => await _executeReplaceByFee(tx, newFee),
            onCancel: () => state = FailureState('Insufficient change for fee'));
      } else {
        await _executeReplaceByFee(tx, newFee);
      }
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> _executeReplaceByFee(TransactionInfo tx, String newFee) async {
    clearOutputs();
    final output = outputs.first;
    output.address = tx.outputAddresses?.first ?? '';

    try {
      pendingTransaction = await bitcoin!.replaceByFee(wallet, tx.id, newFee);
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitTransaction(BuildContext context) async {
    if (pendingTransaction == null) {
      throw Exception("Pending transaction doesn't exist. It should not be happened.");
    }

    if (ocpRequest != null) {
      state = TransactionCommitting();
      if (OpenCryptoPayService.requiresClientCommit(selectedCryptoCurrency)) {
        await pendingTransaction!.commit();
      }

      await _ocpService.commitOpenCryptoPayRequest(
        pendingTransaction!.hex,
        txId: pendingTransaction!.id,
        request: ocpRequest!,
        asset: selectedCryptoCurrency,
      );

      state = TransactionCommitted();

      return;
    }

    String address = outputs.fold('', (acc, value) {
      return value.isParsedAddress
          ? '$acc${value.address}\n${value.extractedAddress}\n\n'
          : '$acc${value.address}\n\n';
    });

    address = address.trim();

    String note = outputs.fold('', (acc, value) => '$acc${value.note}\n');

    note = note.trim();

    try {
      state = TransactionCommitting();

      if (pendingTransaction!.shouldCommitUR()) {
        final urstr = await pendingTransaction!.commitUR();
        final result =
            await Navigator.of(context).pushNamed(Routes.urqrAnimatedPage, arguments: urstr);
        if (result == null) {
          state = FailureState("Canceled by user");
          return;
        }
      } else {
        await pendingTransaction!.commit();
      }

      if (walletType == WalletType.nano) {
        nano!.updateTransactions(wallet);
      }

      if (pendingTransaction!.id.isNotEmpty) {
        TransactionInfo? tx;
        if (walletType == WalletType.monero) {
          await Future.delayed(Duration(milliseconds: 450));
          await wallet.fetchTransactions();
          final txhistory = monero!.getTransactionHistory(wallet);
          tx = txhistory.transactions.values.last;
        }
        final descriptionKey = '${pendingTransaction!.id}_${wallet.walletAddresses.primaryAddress}';
        _settingsStore.shouldSaveRecipientAddress
            ? await transactionDescriptionBox.add(TransactionDescription(
                id: descriptionKey,
                recipientAddress: address,
                transactionNote: note,
                transactionKey: tx?.additionalInfo["key"] as String?,
              ))
            : await transactionDescriptionBox.add(TransactionDescription(
                id: descriptionKey,
                transactionNote: note,
                transactionKey: tx?.additionalInfo["key"] as String?,
              ));
      }
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(PreferencesKey.backgroundSyncLastTrigger(wallet.name),
          DateTime.now().add(Duration(minutes: 1)).toIso8601String());
      state = TransactionCommitted();
    } catch (e) {
      state = FailureState(translateErrorMessage(e, wallet.type, wallet.currency));
    }
  }

  Object _credentials([ExchangeProvider? provider]) {
    final priority = _settingsStore.priority[wallet.type];

    if (priority == null &&
        wallet.type != WalletType.nano &&
        wallet.type != WalletType.banano &&
        wallet.type != WalletType.solana &&
        wallet.type != WalletType.tron) {
      throw Exception('Priority is null for wallet type: ${wallet.type}');
    }

    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return bitcoin!.createBitcoinTransactionCredentials(
          outputs,
          priority: priority!,
          feeRate: feesViewModel.customBitcoinFeeRate,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
          payjoinUri: _settingsStore.usePayjoin ? payjoinUri : null,
        );
      case WalletType.litecoin:
        return bitcoin!.createBitcoinTransactionCredentials(
          outputs,
          priority: priority!,
          feeRate: feesViewModel.customBitcoinFeeRate,
          // if it's an exchange flow then disable sending from mweb coins
          coinTypeToSpendFrom: provider != null ? UnspentCoinType.nonMweb : coinTypeToSpendFrom,
        );

      case WalletType.monero:
        return monero!
            .createMoneroTransactionCreationCredentials(outputs: outputs, priority: priority!);

      case WalletType.wownero:
        return wownero!
            .createWowneroTransactionCreationCredentials(outputs: outputs, priority: priority!);

      case WalletType.ethereum:
        return ethereum!.createEthereumTransactionCredentials(outputs,
            priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.nano:
        return nano!.createNanoTransactionCredentials(outputs);
      case WalletType.polygon:
        return polygon!.createPolygonTransactionCredentials(outputs,
            priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.solana:
        return solana!
            .createSolanaTransactionCredentials(outputs, currency: selectedCryptoCurrency);
      case WalletType.tron:
        return tron!.createTronTransactionCredentials(outputs, currency: selectedCryptoCurrency);
      case WalletType.zano:
        return zano!.createZanoTransactionCredentials(
            outputs: outputs, priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.decred:
        this.coinTypeToSpendFrom = UnspentCoinType.any;
        return decred!.createDecredTransactionCredentials(outputs, priority!);
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }

  bool _isEqualCurrency(String currency) =>
      wallet.balance.keys.any((e) => currency.toLowerCase() == e.title.toLowerCase());

  void onClose() => _settingsStore.fiatCurrency = fiatFromSettings;

  @action
  void setFiatCurrency(FiatCurrency fiat) => _settingsStore.fiatCurrency = fiat;

  @action
  void setSelectedCryptoCurrency(String cryptoCurrency) {
    try {
      selectedCryptoCurrency = wallet.balance.keys
          .firstWhere((e) => cryptoCurrency.toLowerCase() == e.title.toLowerCase());
    } catch (e) {
      selectedCryptoCurrency = wallet.currency;
    }
  }

  ContactRecord? newContactAddress() {
    final Set<String> contactAddresses =
        Set.from(contactListViewModel.contacts.map((contact) => contact.address))
          ..addAll(contactListViewModel.walletContacts.map((contact) => contact.address));

    for (var output in outputs) {
      String address;
      if (output.isParsedAddress) {
        address = output.parsedAddress.addresses.first;
      } else {
        address = output.address;
      }

      if (address.isNotEmpty &&
          !contactAddresses.contains(address) &&
          selectedCryptoCurrency.raw != -1) {
        return ContactRecord(
            contactListViewModel.contactSource,
            Contact(
              name: '',
              address: address,
              type: selectedCryptoCurrency,
            ));
      }
    }
    return null;
  }

  String translateErrorMessage(
    Object error,
    WalletType walletType,
    CryptoCurrency currency,
  ) {
    String errorMessage = error.toString();

    if (walletType == WalletType.solana) {
      if (errorMessage.contains('insufficient lamports')) {
        double solValueNeeded = 0.0;

        // Regular expression to match the number after "need". This shows the exact lamports the user needs to perform the transaction.
        RegExp regExp = RegExp(r'need (\d+)');

        // Find the match
        Match? match = regExp.firstMatch(errorMessage);

        if (match != null) {
          String neededAmount = match.group(1)!;
          final lamportsNeeded = int.tryParse(neededAmount);

          // 5000 lamport used here is the constant for sending a transaction on solana
          int lamportsPerSol = 1000000000;

          solValueNeeded =
              lamportsNeeded != null ? ((lamportsNeeded + 5000) / lamportsPerSol) : 0.0;
          return S.current.insufficient_lamports(solValueNeeded.toString());
        } else {
          return S.current.insufficient_lamport_for_tx;
        }
      }

      if (error is SignNativeTokenTransactionRentException) {
        return S.current.solana_sign_native_transaction_rent_exception;
      }

      if (error is CreateAssociatedTokenAccountException) {
        return "${S.current.solana_create_associated_token_account_exception} ${S.current.added_message_for_ata_error}\n\n${error.errorMessage}";
      }

      if (error is SignSPLTokenTransactionRentException) {
        return S.current.solana_sign_spl_token_transaction_rent_exception;
      }

      if (error is NoAssociatedTokenAccountException) {
        return S.current.solana_no_associated_token_account_exception;
      }

      if (errorMessage.contains('insufficient funds for rent') &&
          errorMessage.contains('Transaction simulation failed') &&
          errorMessage.contains('account_index')) {
        final accountIndexMatch = RegExp(r'account_index: (\d+)').firstMatch(errorMessage);
        if (accountIndexMatch != null) {
          return int.parse(accountIndexMatch.group(1)!) == 0
              ? S.current.insufficientFundsForRentError
              : S.current.insufficientFundsForRentErrorReceiver;
        }
      }

      return errorMessage;
    }
    if (walletType == WalletType.ethereum ||
        walletType == WalletType.polygon ||
        walletType == WalletType.haven) {
      if (errorMessage.contains('gas required exceeds allowance')) {
        return S.current.gas_exceeds_allowance;
      }

      if (errorMessage.contains('insufficient funds')) {
        final parsedErrorMessageResult =
            EVMTransactionErrorFeesHandler.parseEthereumFeesErrorMessage(
          errorMessage,
          _fiatConversationStore.prices[currency] ?? 0.0,
        );

        if (parsedErrorMessageResult.error != null) {
          return S.current.insufficient_funds_for_tx;
        }

        return '''${S.current.insufficient_funds_for_tx} \n\n'''
            '''${S.current.balance}: ${parsedErrorMessageResult.balanceEth} ${walletType == WalletType.polygon ? "POL" : "ETH"} (${parsedErrorMessageResult.balanceUsd} ${fiatFromSettings.name})\n\n'''
            '''${S.current.transaction_cost}: ${parsedErrorMessageResult.txCostEth} ${walletType == WalletType.polygon ? "POL" : "ETH"} (${parsedErrorMessageResult.txCostUsd} ${fiatFromSettings.name})\n\n'''
            '''${S.current.overshot}: ${parsedErrorMessageResult.overshotEth} ${walletType == WalletType.polygon ? "POL" : "ETH"} (${parsedErrorMessageResult.overshotUsd} ${fiatFromSettings.name})''';
      }

      return errorMessage;
    }

    if (walletType == WalletType.tron) {
      if (errorMessage.contains('balance is not sufficient')) {
        return S.current.do_not_have_enough_gas_asset(currency.toString());
      }

      if (errorMessage.contains('Transaction expired')) {
        return 'An error occurred while processing the transaction. Please retry the transaction';
      }
    }

    if (error is TransactionWrongBalanceException) {
      if (error.amount != null)
        return S.current
            .tx_wrong_balance_with_amount_exception(currency.toString(), error.amount.toString());

      return S.current.tx_wrong_balance_exception(currency.toString());
    }
    if (error is TransactionNoInputsException) {
      return S.current.tx_not_enough_inputs_exception;
    }
    if (error is TransactionNoFeeException) {
      return S.current.tx_zero_fee_exception;
    }
    if (error is TransactionNoDustException) {
      return S.current.tx_no_dust_exception;
    }
    if (error is TransactionCommitFailed) {
      if (error.errorMessage != null && error.errorMessage!.contains("no peers replied")) {
        return S.current.tx_commit_failed_no_peers;
      }
      return "${S.current.tx_commit_failed}\nsupport@cakewallet.com${error.errorMessage != null ? "\n\n${error.errorMessage}" : ""}";
    }
    if (error is TransactionCommitFailedDustChange) {
      return S.current.tx_rejected_dust_change;
    }
    if (error is TransactionCommitFailedDustOutput) {
      return S.current.tx_rejected_dust_output;
    }
    if (error is TransactionCommitFailedDustOutputSendAll) {
      return S.current.tx_rejected_dust_output_send_all;
    }
    if (error is TransactionCommitFailedVoutNegative) {
      return S.current.tx_rejected_vout_negative;
    }
    if (error is TransactionCommitFailedBIP68Final) {
      return S.current.tx_rejected_bip68_final;
    }
    if (error is TransactionCommitFailedLessThanMin) {
      return S.current.fee_less_than_min;
    }
    if (error is TransactionNoDustOnChangeException) {
      return S.current.tx_commit_exception_no_dust_on_change(error.min, error.max);
    }
    if (error is TransactionInputNotSupported) {
      return S.current.tx_invalid_input;
    }

    return errorMessage;
  }

  bool _hasTaprootInput(PendingTransaction? pendingTransaction) {
    if (walletType == WalletType.bitcoin && pendingTransaction != null) {
      return bitcoin!.hasTaprootInput(pendingTransaction);
    }

    return false;
  }

  @computed
  bool get usePayjoin => _settingsStore.usePayjoin;

  @observable
  String? payjoinUri;
}
