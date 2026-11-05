import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const editorialFallback = <String>[
    'Georgia',
    'Songti SC',
    'Noto Serif CJK SC',
    'serif',
  ];

  static const display = TextStyle(
    fontFamily: 'Lora',
    fontFamilyFallback: editorialFallback,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -1,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const editorial = TextStyle(
    fontFamily: 'Lora',
    fontFamilyFallback: editorialFallback,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.18,
    letterSpacing: -0.8,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const wordmark = TextStyle(
    fontFamily: 'Lora',
    fontFamilyFallback: editorialFallback,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.3,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const pageTitle = TextStyle(
    fontFamily: 'Lora',
    fontFamilyFallback: editorialFallback,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.22,
    letterSpacing: -0.4,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Lora',
    fontFamilyFallback: editorialFallback,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.2,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const bodyLarge = TextStyle(fontSize: 16, height: 1.5);

  static const body = TextStyle(fontSize: 15, height: 1.53);

  static const bodySmall = TextStyle(fontSize: 13, height: 1.55);

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const nav = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const eyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.6,
  );
}
