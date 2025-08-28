import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart';

class SplashController extends GetxController {
  var opacity = 0.0.obs;

  // Usa el mismo nombre que inicializaste en main.dart
  final GetStorage _storage = GetStorage('GlobalStorage');

  @override
  void onInit() {
    super.onInit();
    startSplashSequence();
  }

  void startSplashSequence() {
    // Anima opacidad a 1 después de 500ms
    Timer(const Duration(milliseconds: 500), () {
      opacity.value = 1.0;
    });

    // Mantén visible hasta 4s
    Timer(const Duration(seconds: 4), () {
      opacity.value = 0.0;

      // Tras 1s adicional (fade out), decide navegación
      Timer(const Duration(milliseconds: 1000), () {
        final bool isLoggedIn = _storage.read('loggedIn') ?? false;

        if (isLoggedIn) {
          Get.offAllNamed(Routes.HOME);
        } else {
          Get.offAllNamed(Routes.LOGIN);
        }
      });
    });
  }
}
