import 'package:cake_wallet/utils/list_item.dart';

class WalletAddressListItem extends ListItem {
  const WalletAddressListItem({
    required this.address,
    required this.isPrimary,
    this.id,
    this.name,
    this.txCount,
    this.balance,
    this.isChange = false,
    // Address that is only ever used once, shouldn't be used to receive funds, copy and paste, share etc
    this.isOneTimeReceiveAddress = false,
  }) : super();

  final int? id;
  final bool isPrimary;
  final String address;
  final String? name;
  final int? txCount;
  final String? balance;
  final bool isChange;
  final bool? isOneTimeReceiveAddress;

  @override
  String toString() => name ?? address;
}
