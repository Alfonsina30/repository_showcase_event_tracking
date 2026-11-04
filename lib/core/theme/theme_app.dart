import 'package:flutter/material.dart';
import 'package:focushabit/core/cores_files.dart' show ColorsApp, TextThemeApp;

class ThemeApp {
  //
  final bool state;
  ThemeApp({required this.state});

  static const double secondIconSize = 22.0;

  static const _iconTheme = IconThemeData(
    color: ColorsApp.primaryColor,
    size: 19,
  );

  static const _listTileTheme = ListTileThemeData(
      style: ListTileStyle.drawer, iconColor: ColorsApp.primaryColor);

  static final _inputDecorationTheme = InputDecorationTheme(
      prefixIconColor: ColorsApp.primaryColor,
      suffixIconColor: ColorsApp.primaryColor,
      errorStyle:
          TextThemeApp.bodyText.copyWith(color: ColorsApp.errorTextColor));

  static const _iconButtonTheme = IconButtonThemeData(
      style: ButtonStyle(
    iconSize: WidgetStatePropertyAll(30),
    iconColor: WidgetStatePropertyAll(ColorsApp.primaryColor),
  ));

  static final _textButtonTheme = TextButtonThemeData(
      style: ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(ColorsApp.primaryColor),
    textStyle: WidgetStatePropertyAll(
        TextThemeApp.titleSmall.copyWith(fontWeight: FontWeight.bold)),
    minimumSize: WidgetStatePropertyAll(Size(120, 35)),
    iconSize: WidgetStatePropertyAll(25),
  ));
  //

  static final _filledButtonTheme = FilledButtonThemeData(
      style: ButtonStyle(
          iconColor: WidgetStatePropertyAll(ColorsApp.colorWhite),
          iconSize: WidgetStatePropertyAll(25),
          foregroundColor: WidgetStatePropertyAll(ColorsApp.colorWhite),
          textStyle: WidgetStatePropertyAll(
              TextThemeApp.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          backgroundColor: WidgetStatePropertyAll(ColorsApp.primaryColor),
          minimumSize: WidgetStatePropertyAll(Size(120, 35))));

  static const _badgeTheme = BadgeThemeData(
      largeSize: 18,
      textStyle: TextStyle(fontSize: 15),
      textColor: ColorsApp.colorBlack,
      backgroundColor: ColorsApp.primaryColor);

  ThemeData theme() {
    //
    if (state) {
//*******************************************************     DARK THEME        ************************************* */
//! THEME DARK
      return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: ColorsApp.scaffoldDark,
          appBarTheme: AppBarTheme(backgroundColor: ColorsApp.scaffoldDark),
          colorScheme: ColorScheme.dark(
              primary: ColorsApp.primaryColor, onSurface: ColorsApp.colorWhite),
          dividerColor: ColorsApp.primaryColor,
//***badget */
          badgeTheme: _badgeTheme,
//***icon theme */
          iconTheme: _iconTheme,
//***TEXT */
          textTheme: TextThemeApp.textDarkTheme,

//*** bottomSheetTheme */
          bottomSheetTheme:
              BottomSheetThemeData(backgroundColor: ColorsApp.scaffoldDark),

//**List Tile */
          listTileTheme: _listTileTheme,
//**Input Decoration */
          inputDecorationTheme: _inputDecorationTheme,
//*** textButton */
          textButtonTheme: _textButtonTheme,
//**Icon Button */
          iconButtonTheme: _iconButtonTheme,
//**** OutLine button */
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(ColorsApp.colorWhite),
                  textStyle: WidgetStatePropertyAll(TextThemeApp.bodyText
                      .copyWith(color: ColorsApp.colorWhite)),
                  minimumSize: WidgetStatePropertyAll(Size(120, 35)),
                  iconSize: WidgetStatePropertyAll(25),
                  iconColor: WidgetStatePropertyAll(ColorsApp.colorWhite))),
//**filled button */
          filledButtonTheme: _filledButtonTheme,
          //************bottom navigation bar  */
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(color: ColorsApp.primaryColor),
              selectedItemColor: ColorsApp.primaryColor,
              backgroundColor: Colors.transparent));
    }
//*********************************************THEME LIGHT********************************************* */
    //! THEME LIGHT
    else {
      return ThemeData.light().copyWith(
          scaffoldBackgroundColor: ColorsApp.scaffoldLight,
          appBarTheme: AppBarTheme(backgroundColor: ColorsApp.scaffoldLight),
          colorScheme: ColorScheme.light(
              primary: ColorsApp.primaryColor, onSurface: ColorsApp.colorBlack),

//***badget */
          badgeTheme: _badgeTheme,
//***icon theme */
          iconTheme: _iconTheme,
//***TEXT */
          textTheme: TextThemeApp.textLightTheme,
//*** bottomSheetTheme */
          bottomSheetTheme:
              BottomSheetThemeData(backgroundColor: ColorsApp.scaffoldDark),
//**List Tile */
          listTileTheme: _listTileTheme,
//**Input Decoration */
          inputDecorationTheme: _inputDecorationTheme,
//**Icon Button */
          iconButtonTheme: _iconButtonTheme,
//**** textButton */
          textButtonTheme: _textButtonTheme,
//**** OutLine button */
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                 foregroundColor: WidgetStatePropertyAll(ColorsApp.colorBlack),
                  textStyle: WidgetStatePropertyAll(TextThemeApp.bodyText
                      .copyWith(color: ColorsApp.colorBlack)),
                  minimumSize: WidgetStatePropertyAll(Size(120, 35)),
                  iconSize: WidgetStatePropertyAll(25),
                  iconColor: WidgetStatePropertyAll(ColorsApp.colorBlack))),
//**filled button */
          filledButtonTheme: _filledButtonTheme,
//************bottom navigation bar  */
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(color: ColorsApp.primaryColor),
              selectedItemColor: ColorsApp.primaryColor,
              backgroundColor: Colors.white));
    }
  }
}
