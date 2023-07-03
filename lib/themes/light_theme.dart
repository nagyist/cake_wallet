import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/themes/extensions/pin_code_theme.dart';
import 'package:cake_wallet/themes/extensions/support_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class LightTheme extends ThemeBase {
  LightTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.light_theme;
  @override
  ThemeType get type => ThemeType.light;
  @override
  Brightness get brightness => Brightness.light;
  @override
  Color get backgroundColor => Colors.white;
  @override
  Color get primaryColor => Palette.protectiveBlue;
  @override
  Color get primaryTextColor => Palette.darkBlueCraiola;
  @override
  Color get containerColor => Palette.blueAlice;
  @override
  Color get dialogBackgroundColor => Colors.white;

  @override
  CakeScrollbarTheme get scrollbarTheme => CakeScrollbarTheme(
      thumbColor: Palette.moderatePurpleBlue,
      trackColor: Palette.periwinkleCraiola);

  @override
  SyncIndicatorTheme get syncIndicatorStyle => SyncIndicatorTheme(
      textColor: Palette.darkBlueCraiola,
      syncedBackgroundColor: Palette.blueAlice,
      notSyncedIconColor: Palette.shineOrange,
      notSyncedBackgroundColor: Palette.blueAlice.withOpacity(0.75));

  @override
  KeyboardTheme get keyboardTheme =>
      KeyboardTheme(keyboardBarColor: Palette.dullGray);

  @override
  PinCodeTheme get pinCodeTheme => PinCodeTheme(
      indicatorsColor: Palette.darkGray,
      switchColor: Palette.darkGray);

  @override
  SupportPageTheme get supportPageTheme =>
      SupportPageTheme(iconColor: Colors.black);

  @override
  ExchangePageTheme get exchangePageTheme => ExchangePageTheme(
      hintTextColor: Colors.white.withOpacity(0.4),
      dividerCodeColor: Palette.wildPeriwinkle,
      qrCodeColor: primaryTextColor,
      buttonBackgroundColor: containerColor,
      textFieldButtonColor: Colors.white.withOpacity(0.2),
      textFieldBorderBottomPanelColor: Colors.white.withOpacity(0.5),
      textFieldBorderTopPanelColor: Colors.white.withOpacity(0.5),
      secondGradientBottomPanelColor: Palette.blueGreyCraiola.withOpacity(0.7),
      firstGradientBottomPanelColor: Palette.blueCraiola.withOpacity(0.7),
      secondGradientTopPanelColor: Palette.blueGreyCraiola,
      firstGradientTopPanelColor: Palette.blueCraiola,
      receiveAmountColor: Palette.niagara);

  @override
  NewWalletTheme get newWalletTheme => NewWalletTheme(
      hintTextColor: Palette.darkGray,
      underlineColor: Palette.periwinkleCraiola);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      indicatorColor:
          PaletteDark.darkCyanBlue.withOpacity(0.67), // page indicator
      hoverColor: Palette.darkBlueCraiola, // amount hint text (receive page)
      dividerColor: Palette.paleBlue,
      hintColor: Palette.gray,
      disabledColor: Palette.darkGray,
      dialogTheme: super
          .themeData
          .dialogTheme
          .copyWith(backgroundColor: Colors.white),
      textTheme: TextTheme(
          bodySmall: TextStyle(
            decorationColor: PaletteDark.wildBlue, // filter icon
          ),
          labelSmall: TextStyle(
              color: Palette.blueAlice, // filter button
              backgroundColor: PaletteDark.darkCyanBlue, // date section row
              decorationColor:
                  Palette.blueAlice // icons (transaction and trade rows)
              ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
            color: Palette.blueAlice, // address button border
            decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
          ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: Colors.white, // qr code
            decorationColor: Palette.darkBlueCraiola, // bottom border of amount (receive page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
            color: PaletteDark.lightBlueGrey, // icons color (receive page)
            decorationColor: Palette.moderateLavender, // icons background (receive page)
          ),
          // display2 -> headldisplaySmalline3
          displaySmall: TextStyle(
              color:
                  Palette.darkBlueCraiola, // text color of tiles (receive page)
              decorationColor:
                  Palette.blueAlice // background of tiles (receive page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Colors.white, // text color of current tile (receive page),
              //decorationColor: Palette.blueCraiola // background of current tile (receive page)
              decorationColor: Palette
                  .blueCraiola // background of current tile (receive page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Palette.violetBlue, // text color of tiles (account list)
              decorationColor:
                  Colors.white // background of tiles (account list)
              ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
            color: Palette.moderateLavender, // menu header
            decorationColor: Colors.white, // menu background
          )
      ),
      primaryTextTheme: TextTheme(
          // title -> titleLarge
          titleLarge: TextStyle(
              color: Palette.darkBlueCraiola, // title color
              backgroundColor: Palette.wildPeriwinkle // textfield underline
              ),
          bodySmall: TextStyle(
              color: PaletteDark.pigeonBlue, // secondary text
              decorationColor: Palette.wildLavender // menu divider
              ),
          labelSmall: TextStyle(
            color: Palette.darkGray, // transaction/trade details titles
            decorationColor: PaletteDark.darkCyanBlue, // placeholder
          ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
              color: Palette.blueCraiola, // first gradient color (send page)
              decorationColor:
                  Palette.blueGreyCraiola // second gradient color (send page)
              ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: Colors.white
                .withOpacity(0.5), // text field border color (send page)
            decorationColor: Colors.white
                .withOpacity(0.5), // text field hint color (send page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
              color: Colors.white
                  .withOpacity(0.2), // text field button color (send page)
              decorationColor:
                  Colors.white // text field button icon color (send page)
              ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color: Colors.white.withOpacity(0.5), // estimated fee (send page)
              backgroundColor: PaletteDark.darkCyanBlue
                  .withOpacity(0.67), // dot color for indicator on send page
              decorationColor:
                  Palette.moderateLavender // template dotted border (send page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              backgroundColor: PaletteDark
                  .darkNightBlue, // active dot color for indicator on send page
              decorationColor:
                  Palette.blueAlice // template background color (send page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Palette.darkBlueCraiola, // template title (send page)
              backgroundColor:
                  Colors.black, // icon color on order row (moonpay)
              ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
              backgroundColor: Palette.brightOrange // alert left button text
          )
      ),
      accentTextTheme: TextTheme(
        // title -> headlititleLargene6
        titleLarge: TextStyle(
            backgroundColor: Palette.periwinkleCraiola, // picker divider
            ),
        bodySmall: TextStyle(
          decorationColor: Palette.darkBlueCraiola, // text color (information page)
        ),
        // subtitle -> titleSmall
        titleSmall: TextStyle(
            decorationColor: Palette
                .protectiveBlue // crete new wallet button background (wallet list page)
            ),
        // headline -> headlineSmall
        headlineSmall: TextStyle(
            color: Palette
                .moderateLavender, // first gradient color of wallet action buttons (wallet list page)
            decorationColor: Colors
                .white // restore wallet button text color (wallet list page)
            ),
        // subhead -> titleMedium
        titleMedium: TextStyle(
            color: Palette.darkGray, // titles color (filter widget)
            backgroundColor: Palette.periwinkle, // divider color (filter widget)
            decorationColor: Colors.white // checkbox background (filter widget)
            ),
        labelSmall: TextStyle(
          color: Palette.wildPeriwinkle, // checkbox bounds (filter widget)
          decorationColor: Colors.white, // menu subname
        ),
        // display1 -> headlineMedium
        headlineMedium: TextStyle(
            color: Palette.blueCraiola, // first gradient color (menu header)
            decorationColor: Palette.blueGreyCraiola, // second gradient color(menu header)
            backgroundColor: PaletteDark.darkNightBlue // active dot color
            ),
        // display2 -> displaySmall
        displaySmall: TextStyle(
            color:
                Palette.shadowWhite, // action button color (address text field)
            decorationColor: Palette.darkGray, // hint text (seed widget)
            backgroundColor: Palette.darkBlueCraiola
                .withOpacity(0.67) // text on balance page
            ),
      ),
      );
}
