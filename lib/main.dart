import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init('GlobalStorage');
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.SPLASH, // ✅ Mantén solo esto
      theme: ThemeData(),
      defaultTransition: Transition.fade,
      // home: SplashPage(),         // ❌ QUITAR esta línea
      getPages: AppPages.pages,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final double currentScale = mq.textScaler.scale(1.0);
        final double clamped = currentScale.clamp(1.0, 1.1);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
          child: child!,
        );
      },
    ),
  );
}
