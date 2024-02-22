import 'dart:async';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnConnectDevice = void Function(BuildContext, LedgerDevice);

class ConnectDevicePageParams {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;

  ConnectDevicePageParams({required this.walletType, required this.onConnectDevice});
}

class ConnectDevicePage extends BasePage {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;

  ConnectDevicePage(ConnectDevicePageParams params)
      : walletType = params.walletType,
        onConnectDevice = params.onConnectDevice;

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  Widget body(BuildContext context) => ConnectDevicePageBody(walletType, onConnectDevice);
}

class ConnectDevicePageBody extends StatefulWidget {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;

  const ConnectDevicePageBody(this.walletType, this.onConnectDevice);

  @override
  ConnectDevicePageBodyState createState() => ConnectDevicePageBodyState();
}

class ConnectDevicePageBodyState extends State<ConnectDevicePageBody> {
  final imageLedger = 'assets/images/ledger_nano.png';

  final ledger = Ledger(
    options: LedgerOptions(
      scanMode: ScanMode.balanced,
      maxScanDuration: const Duration(minutes: 5),
    ),
    onPermissionRequest: (_) async {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      return statuses.values.where((status) => status.isDenied).isEmpty;
    },
  );

  var bleDevices = <LedgerDevice>[];
  var usbDevices = <LedgerDevice>[];

  late Timer _usbRefreshTimer;
  late StreamSubscription<LedgerDevice> _bleRefresh;

  @override
  void initState() {
    super.initState();
    _usbRefreshTimer = Timer.periodic(Duration(seconds: 1), (_) => _refreshUsbDevices());
    _bleRefresh = ledger.scan().listen((device) => setState(() => bleDevices.add(device)));
  }

  @override
  void dispose() {
    super.dispose();
    _usbRefreshTimer.cancel();
    _bleRefresh.cancel();
    ledger.close(ConnectionType.ble);
    ledger.close(ConnectionType.usb);
  }

  Future<void> _refreshUsbDevices() async {
    final dev = await ledger.listUsbDevices();
    if (usbDevices.length != dev.length) setState(() => usbDevices = dev);
  }

  void _connectToDevice(LedgerDevice device) => widget.onConnectDevice(context, device);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
        height: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Text(
                  S.of(context).connect_your_hardware_wallet,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                  textAlign: TextAlign.center,
                ),
              ),
              if (bleDevices.length > 0) ...[
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      "Bluetooth",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                    ),
                  ),
                ),
                ...bleDevices
                    .map(
                      (device) => Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: DeviceTile(
                          onPressed: () => _connectToDevice(device),
                          title: device.name,
                          leading: imageLedger,
                          connectionType: device.connectionType,
                        ),
                      ),
                    )
                    .toList()
              ],
              if (usbDevices.length > 0) ...[
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      "USB",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                    ),
                  ),
                ),
                ...usbDevices
                    .map(
                      (device) => Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: DeviceTile(
                          onPressed: () => _connectToDevice(device),
                          title: device.name,
                          leading: imageLedger,
                          connectionType: device.connectionType,
                        ),
                      ),
                    )
                    .toList(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
