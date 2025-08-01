import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/wallet_restore_from_qr_code.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

class RestoreOptionsPage extends BasePage {
  RestoreOptionsPage({required this.isNewInstall});

  @override
  String get title => S.current.restore_restore_wallet;

  final bool isNewInstall;

  @override
  Widget body(BuildContext context) {
    return _RestoreOptionsBody(isNewInstall: isNewInstall, themeType: currentTheme.type);
  }
}

class _RestoreOptionsBody extends StatefulWidget {
  const _RestoreOptionsBody({required this.isNewInstall, required this.themeType});

  final bool isNewInstall;
  final ThemeType themeType;

  @override
  _RestoreOptionsBodyState createState() => _RestoreOptionsBodyState();
}

class _RestoreOptionsBodyState extends State<_RestoreOptionsBody> {
  bool isRestoring = false;

  bool get _doesSupportHardwareWallets {
    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(WalletType.monero, Platform.isIOS)
          .isNotEmpty;
    }

    return true;
  }

  String get imageRestoreHWPath =>
      widget.themeType == ThemeType.dark
          ? 'assets/images/restore_hw_dark.png'
          : 'assets/images/restore_hw.png';

  String get imageRestoreCupcakePath =>
      widget.themeType == ThemeType.dark
          ? 'assets/images/restore_cupcake_dark.png'
          : 'assets/images/restore_cupcake.png';

  String get imageRestoreQRPath =>
      widget.themeType == ThemeType.dark
          ? 'assets/images/restore_qr_dark.png'
          : 'assets/images/restore_qr.png';


  String get imageRestoreHotWalletPath =>
      widget.themeType == ThemeType.dark
          ? 'assets/images/restore_hot_wallet_dark.png'
          : 'assets/images/restore_hot_wallet.png';


  String get imageRestoreBackupPath =>
      widget.themeType == ThemeType.dark
          ? 'assets/images/restore_backup_dark.png'
          : 'assets/images/restore_backup.png';

  @override
  Widget build(BuildContext context) {
    final imageRestoreHW = Image.asset(imageRestoreHWPath, width: 55);
    final imageRestoreCupcake = Image.asset(imageRestoreCupcakePath, width: 55);
    final imageRestoreQR = Image.asset(imageRestoreQRPath, width: 55);
    final imageSeedKeys = Image.asset(imageRestoreHotWalletPath, width: 55);
    final imageRestoreBackup = Image.asset(imageRestoreBackupPath, width: 55);

    return Center(
      child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                OptionTile(
                  key: ValueKey('restore_options_from_seeds_or_keys_button_key'),
                  onPressed: () => Navigator.pushNamed(context, Routes.restoreWalletFromSeedKeys),
                  image: imageSeedKeys,
                  title: S.of(context).restore_title_from_seed_keys,
                  description: S.of(context).restore_description_from_seed_keys,
                ),
                if (FeatureFlag.hasBitcoinViewOnly && DeviceInfo.instance.isMobile)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      key: ValueKey('restore_options_from_cupcake_button_key'),
                      onPressed: () => _onScanQRCode(context),
                      image: imageRestoreCupcake,
                      title: S.of(context).restore_title_from_cupcake,
                      description: S.of(context).restore_description_from_cupcake,
                      tag: S.of(context).new_tag,
                    ),
                  ),
                if (_doesSupportHardwareWallets)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      key: ValueKey('restore_options_from_hardware_wallet_button_key'),
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.restoreWalletFromHardwareWallet),
                      image: imageRestoreHW,
                      title: S.of(context).restore_title_from_hardware_wallet,
                      description: S.of(context).restore_description_from_hardware_wallet,
                    ),
                  ),
                if (widget.isNewInstall)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      key: ValueKey('restore_options_from_backup_button_key'),
                      onPressed: () => Navigator.pushNamed(context, Routes.restoreFromBackup),
                      image: imageRestoreBackup,
                      title: S.of(context).restore_title_from_backup,
                      description: S.of(context).restore_description_from_backup,
                    ),
                  ),
                if (DeviceInfo.instance.isMobile)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                        key: ValueKey('restore_options_from_qr_button_key'),
                        onPressed: () => _onScanQRCode(context),
                        image: imageRestoreQR,
                        title: S.of(context).scan_qr_code,
                        description: S.of(context).cold_or_recover_wallet,
                    ),
                  ),
              ],
            ),
          )),
    );
  }

  void _showQRScanError(BuildContext context, String error) {
    setState(() => isRestoring = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.current.error,
                alertContent: error,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    });
  }

  Future<void> _onScanQRCode(BuildContext context) async {
    final isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);

    if (!isCameraPermissionGranted) return;
    try {
      if (isRestoring) return;

      setState(() => isRestoring = true);

      final restoredWallet = await WalletRestoreFromQRCode.scanQRCodeForRestoring(context);

      final params = {'walletType': restoredWallet.type, 'restoredWallet': restoredWallet};

      Navigator.pushNamed(context, Routes.restoreWallet, arguments: params).then((_) {
        if (mounted) setState(() => isRestoring = false);
      });
    } catch (e) {
      _showQRScanError(context, e.toString());
    }
  }
}
