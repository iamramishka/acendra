import 'package:acendra/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (EnvConfig.supabaseUrl.isNotEmpty &&
      EnvConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey, // ignore: deprecated_member_use
    );
  }

  runApp(const ProviderScope(child: AcendraApp()));
}
