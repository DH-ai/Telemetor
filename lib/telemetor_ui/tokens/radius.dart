import 'package:flutter/widgets.dart';

/// Corner-radius scale for the Telemetor Design Language.
///
/// Telemetor leans on sharp, technical surfaces, so the scale stays tight.
class TDLRadius {
  const TDLRadius._();

  static const double none = 0;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
  static const double xl = 14;
  static const double pill = 999;

  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));
}
