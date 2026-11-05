import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/i18n/strings.g.dart';

Future<void> pumpWithTranslations(
  WidgetTester tester, {
  required Widget child,
  AppLocale locale = AppLocale.en,
}) async {
  await LocaleSettings.setLocale(locale);
  await tester.pumpWidget(TranslationProvider(child: MaterialApp(home: child)));
}

Future<void> pumpTemplateApp(
  WidgetTester tester, {
  required Widget app,
  AppLocale locale = AppLocale.en,
}) async {
  await LocaleSettings.setLocale(locale);
  await tester.pumpWidget(TranslationProvider(child: app));
}
