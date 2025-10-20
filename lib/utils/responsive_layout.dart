/// \file responsive_layout.dart
/// \brief Narzędzia do obsługi responsywnego layoutu
/// 
/// Pomocnicze metody do dostosowywania UI do różnych rozmiarów ekranów.

import 'package:flutter/material.dart';

/// \class ResponsiveLayout
/// \brief Klasa pomocnicza do obsługi responsywnego layoutu
class ResponsiveLayout {
  /// \brief Sprawdza czy ekran jest mobilny (< 768px)
  /// \param context Kontekst buildera
  /// \return true jeśli ekran mobilny
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  /// \brief Sprawdza czy ekran jest tabletowy (768px - 1200px)
  /// \param context Kontekst buildera
  /// \return true jeśli ekran tabletowy
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;

  /// \brief Sprawdza czy ekran jest desktopowy (>= 1200px)
  /// \param context Kontekst buildera
  /// \return true jeśli ekran desktopowy
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// \brief Sprawdza czy ekran jest odpowiedni dla web (>= 768px)
  /// \param context Kontekst buildera
  /// \return true jeśli ekran web
  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;

  /// \brief Zwraca optymalną szerokość treści dla ekranu
  /// \param context Kontekst buildera
  /// \return Szerokość w pikselach
  static double getContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 1200;
    if (width >= 1200) return 1000;
    if (width >= 768) return width * 0.85;
    return width;
  }

  /// \brief Zwraca odpowiednie wypełnienie strony dla rozmiaru ekranu
  /// \param context Kontekst buildera
  /// \return EdgeInsets z odpowiednim paddingiem
  static EdgeInsets getPagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }

  /// \brief Zwraca liczbę kolumn dla grid w zależności od rozmiaru ekranu
  /// \param context Kontekst buildera
  /// \param mobile Liczba kolumn dla mobile (domyślnie 1)
  /// \param tablet Liczba kolumn dla tablet (domyślnie 2)
  /// \param desktop Liczba kolumn dla desktop (domyślnie 3)
  /// \return Liczba kolumn
  static int getGridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
