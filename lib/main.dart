import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/security/encryption_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intl defaults to en_US unless set explicitly. DateFormat also needs its
  // locale data loaded, and falls back to en_US for unsupported locales.
  await initializeDateFormatting();
  final locale = PlatformDispatcher.instance.locale;
  final candidate = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
  Intl.defaultLocale = Intl.verifiedLocale(
    candidate,
    DateFormat.localeExists,
    onFailure: (_) => 'en_US',
  );

  final encryption = EncryptionService();
  await encryption.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(FieldbookApp(
    database: AppDatabase(),
    encryption: encryption,
    prefs: prefs,
  ));
}
