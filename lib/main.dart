import 'package:flutter/material.dart';
import 'package:hvac_admin/app/hvac_admin_app.dart';
import 'package:hvac_admin/core/config/production_boot_guard.dart';
import 'package:hvac_admin/data/datasources/hvac_supabase.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabase = await HvacSupabase.initialize();
  final bundle = RepositoryWiring.create(client: supabase);
  ProductionBootGuard.validate(bundle: bundle, supabaseConnected: true);
  runApp(HvacAdminApp(supabase: supabase));
}
