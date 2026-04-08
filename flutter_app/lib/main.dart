import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/data/local_storage_repository.dart';
import 'src/state/hospital_app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = HospitalAppState(
    repository: LocalStorageRepository(),
  );
  await state.initialize();

  runApp(
    ChangeNotifierProvider<HospitalAppState>.value(
      value: state,
      child: const HospitalApp(),
    ),
  );
}
