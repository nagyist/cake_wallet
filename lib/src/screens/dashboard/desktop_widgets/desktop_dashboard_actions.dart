import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/main_actions.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DesktopDashboardActions extends StatelessWidget {
  final DashboardViewModel dashboardViewModel;

  const DesktopDashboardActions(this.dashboardViewModel, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Observer(
        builder: (_) {
          return Column(
            children: [
              const SizedBox(height: 16),
              DesktopActionButton(
                title: MainActions.showWalletsAction.name(context),
                image: MainActions.showWalletsAction.image,
                canShow: MainActions.showWalletsAction.canShow?.call(dashboardViewModel),
                isEnabled: MainActions.showWalletsAction.isEnabled?.call(dashboardViewModel),
                onTap: () async =>
                    await MainActions.showWalletsAction.onTap(context, dashboardViewModel),
              ),
              DesktopActionButton(
                title: MainActions.swapAction.name(context),
                image: MainActions.swapAction.image,
                canShow: MainActions.swapAction.canShow?.call(dashboardViewModel),
                isEnabled: MainActions.swapAction.isEnabled?.call(dashboardViewModel),
                onTap: () async => await MainActions.swapAction.onTap(context, dashboardViewModel),
              ),
              Row(
                children: [
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.receiveAction.name(context),
                      image: MainActions.receiveAction.image,
                      canShow: MainActions.receiveAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.receiveAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async =>
                          await MainActions.receiveAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.sendAction.name(context),
                      image: MainActions.sendAction.image,
                      canShow: MainActions.sendAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.sendAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async => await MainActions.sendAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: DesktopActionButton(
                      title: MainActions.tradeAction.name(context),
                      image: MainActions.tradeAction.image,
                      canShow: MainActions.tradeAction.canShow?.call(dashboardViewModel),
                      isEnabled: MainActions.tradeAction.isEnabled?.call(dashboardViewModel),
                      onTap: () async => await MainActions.tradeAction.onTap(context, dashboardViewModel),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: CakeFeaturesPage(
                dashboardViewModel: dashboardViewModel,
                cakeFeaturesViewModel: getIt.get<CakeFeaturesViewModel>(),
              ),
            ),
            ],
          );
        }
      ),
    );
  }
}
