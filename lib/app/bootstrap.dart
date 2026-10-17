import 'package:acendra/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = EnvConfig.readForStartup();
  if (config != null) {
    await Supabase.initialize(
      url: config.url,
      anonKey: config.key, // ignore: deprecated_member_use
    );
  }

  runApp(const ProviderScope(child: AcendraApp()));
}
