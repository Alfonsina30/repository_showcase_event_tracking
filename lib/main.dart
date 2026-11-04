import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focushabit/app/app_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/cores_files.dart';
import 'package:focushabit/app/injection_container.dart' as di;


void main() async {
  //-- 1.
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.initEnvironment();

  //2---> firebase Auth
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await configEmulator();

  final SharedPreferences sharedPreference =
      await SharedPreferences.getInstance();

  //-- GetIt initialize
  await di.init(sharedPreference);
//---await all di are ready

  try {
    log('ISSawait di.init();');
    await di.sl.allReady(timeout: const Duration(seconds: 3));
  } catch (e) {
    log('❌ ERROR DE TIMEOUT EN GETIT: Un objeto se quedó congelado.');
  }
//

  Bloc.observer = CustomBlocObserver();

  final initialMode =
      await di.sl<SharedPreferenceServiceImpl>().read() ?? false;

  runApp(MyApp(
    themeModeStorage: initialMode,
  ));
}
