import 'package:cake_wallet/src/screens/yat/widgets/yat_bar.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_page_indicator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ThirdIntroduction extends StatelessWidget {
  ThirdIntroduction({required this.onGet, required this.onConnect, this.onClose});

  final VoidCallback? onClose;
  final VoidCallback onGet;
  final VoidCallback onConnect;
  final animation = Lottie.asset('assets/animation/anim3.json');

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight,
      width: screenWidth,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(top: 40, bottom: 40),
        content: Column(
          children: [
            Container(
                height: 90,
                padding: EdgeInsets.only(left: 24, right: 24),
                child: YatBar(onClose: onClose)),
            animation,
            Padding(
                padding: EdgeInsets.only(top: 40, left: 30, right: 30),
                child: Column(children: [
                  Text(S.of(context).third_intro_title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                         
                        color: Theme.of(context).colorScheme.onSurface,
                        decoration: TextDecoration.none,
                      )),
                  Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(S.of(context).third_intro_content,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                             
                            color: Theme.of(context).colorScheme.onSurface,
                            decoration: TextDecoration.none,
                          )))
                ])),
          ],
        ),
        bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        bottomSection: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PrimaryIconButton(
              text: S.of(context).get_your_yat,
              textColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.primary,
              borderColor: Theme.of(context).colorScheme.primary,
              iconColor: Theme.of(context).colorScheme.onPrimary,
              iconBackgroundColor: Colors.transparent,
              iconData: CupertinoIcons.arrow_up_right_square,
              mainAxisAlignment: MainAxisAlignment.end,
              onPressed: onGet,
            ),
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: PrimaryIconButton(
                text: S.of(context).connect_an_existing_yat,
                textColor: Theme.of(context).colorScheme.onPrimary,
                color: Theme.of(context).colorScheme.primary,
                borderColor: Theme.of(context).colorScheme.primary,
                iconColor: Theme.of(context).colorScheme.onPrimary,
                iconBackgroundColor: Colors.transparent,
                iconData: CupertinoIcons.arrow_up_right_square,
                mainAxisAlignment: MainAxisAlignment.end,
                onPressed: onConnect,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: YatPageIndicator(filled: 2),
            )
          ],
        ),
      ),
    );
  }
}
