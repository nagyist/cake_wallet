import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';

bool get isMoneroOnly {
    return availableWalletTypes.length == 1
     	&& availableWalletTypes.first == WalletType.monero;
}


bool get isSingleCoin {
     return availableWalletTypes.length == 1;
}

bool get hasMonero {
    return availableWalletTypes.contains(WalletType.monero);
}

String get approximatedAppName {
    if (isMoneroOnly) {
        return 'Monero.com';   
    }
     
    return 'Cake Wallet';
}
