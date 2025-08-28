import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 para SystemNavigator.pop()
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/widgets/custom_input_field.dart';

import '../../../controllers/login_controller.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart'; // 👈 usar Routes.REGISTER

class LoginPage extends GetView<LoginController> {
  LoginPage({super.key});

  // Estado local solo para la vista (mostrar/ocultar contraseña)
  final ValueNotifier<bool> _showPassword = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // bloquea el back por defecto
      // 👇 reemplazo correcto en 3.22+: incluye didPop y result
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return; // si ya hizo pop, no hacemos nada
        SystemNavigator.pop(); // salir de la app desde Login
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // Fondo con gradiente
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF59D999), Color(0xFF31AD9B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Contenido
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),

                              // Centro del formulario
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 420),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // EMAIL
                                        CustomInputField(
                                          hintText: 'Ingresar email',
                                          icon: Icons.email,
                                          width: double.infinity,
                                          height: 48,
                                          textStyle: const TextStyle(
                                              color: Colors.white),
                                          controller:
                                              controller.emailController,
                                          onChanged: (value) =>
                                              controller.email.value = value,
                                        ),

                                        const SizedBox(height: 12),

                                        const Text(
                                          'Contraseña',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // PASSWORD + Toggle Ver/Ocultar
                                        ValueListenableBuilder<bool>(
                                          valueListenable: _showPassword,
                                          builder: (context, visible, _) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                CustomInputField(
                                                  hintText:
                                                      'Ingresar Contraseña',
                                                  icon: Icons.lock_outline,
                                                  obscureText: !visible,
                                                  width: double.infinity,
                                                  height: 48,
                                                  textStyle: const TextStyle(
                                                      color: Colors.white),
                                                  controller: controller
                                                      .passwordController,
                                                  onChanged: (value) =>
                                                      controller.password
                                                          .value = value,
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton.icon(
                                                    onPressed: () =>
                                                        _showPassword.value =
                                                            !visible,
                                                    icon: Icon(
                                                      visible
                                                          ? Icons.visibility_off
                                                          : Icons.visibility,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    label: Text(
                                                      visible
                                                          ? 'Ocultar contraseña'
                                                          : 'Ver contraseña',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 24),

                                        // BOTÓN / LOADING
                                        Center(
                                          child: Obx(() {
                                            return controller.isLoading.value
                                                ? const SizedBox(
                                                    width: 276,
                                                    height: 48,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.6,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  )
                                                : SizedBox(
                                                    width: 276,
                                                    height: 48,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        controller.login();
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'INGRESAR',
                                                        style: TextStyle(
                                                          color: Color.fromRGBO(
                                                              50, 174, 161, 1),
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Footer: registro
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 36.0, top: 12),
                                child: Center(
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text: '¿No tienes una cuenta? ',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 16),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'REGÍSTRATE',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Get.toNamed(Routes.REGISTER);
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
