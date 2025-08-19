import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/widgets/custom_input_field.dart';
import '../../../controllers/register_controller.dart';

class RegisterPage extends GetView<RegisterController> {
  RegisterPage({super.key});

  final TextEditingController codeController = TextEditingController();
  final ValueNotifier<bool> _showPassword = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                        'Registrarse',
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 25),

                                      // Nombres y apellidos
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'Nombres',
                                              icon: Icons.person,
                                              controller:
                                                  controller.nameController,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'Apellidos',
                                              icon: Icons
                                                  .person_add_alt_1_outlined,
                                              controller:
                                                  controller.lastNameController,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      _buildInputField(
                                        label: 'Correo Electrónico',
                                        icon: Icons.email_outlined,
                                        controller: controller.emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'DNI',
                                              icon: Icons.badge,
                                              controller:
                                                  controller.dniController,
                                              keyboardType: TextInputType
                                                  .number, // teclado numérico
                                              maxLength: 8,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    8),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'Teléfono',
                                              icon: Icons.phone,
                                              controller:
                                                  controller.phoneController,
                                              keyboardType: TextInputType
                                                  .phone, // teclado de teléfono
                                              maxLength: 9,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    9),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      _buildInputField(
                                        label: 'Dirección',
                                        icon: Icons.location_on_outlined,
                                        controller:
                                            controller.addressController,
                                        inputFormatters: [
                                          TextInputFormatter.withFunction(
                                            (oldValue, newValue) =>
                                                TextEditingValue(
                                              text: newValue.text.toUpperCase(),
                                              selection: newValue.selection,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Contraseña con toggle (ojito dentro del campo)
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Contraseña",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _showPassword,
                                        builder: (context, visible, _) {
                                          return CustomInputField(
                                            hintText: '',
                                            icon: Icons.lock,
                                            controller:
                                                controller.passwordController,
                                            obscureText: !visible,
                                            // Altura flexible: NO pasamos height
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                visible
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.white,
                                              ),
                                              onPressed: () => _showPassword
                                                  .value = !visible,
                                            ),
                                          );
                                        },
                                      ),

                                      // Código de verificación
                                      const SizedBox(height: 10),
                                      _buildInputField(
                                        label: 'Código de Verificación',
                                        icon: Icons.verified,
                                        controller: codeController,
                                      ),

                                      const SizedBox(height: 20),
                                      const Text(
                                        'Tipo de Usuario',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            _buildRadioOption(
                                              label: 'Casa',
                                              value: 'Casa',
                                              groupValue:
                                                  controller.userType.value,
                                              onChanged: (value) => controller
                                                  .userType.value = value!,
                                            ),
                                            _buildRadioOption(
                                              label: 'Institución',
                                              value: 'Institución',
                                              groupValue:
                                                  controller.userType.value,
                                              onChanged: (value) => controller
                                                  .userType.value = value!,
                                            ),
                                            _buildRadioOption(
                                              label: 'Negocio',
                                              value: 'Negocio',
                                              groupValue:
                                                  controller.userType.value,
                                              onChanged: (value) => controller
                                                  .userType.value = value!,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Botón registrar
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
                                                      if (controller
                                                              .dniController
                                                              .text
                                                              .trim()
                                                              .length !=
                                                          8) {
                                                        _showError(
                                                            "El DNI debe tener 8 dígitos");
                                                        return;
                                                      }
                                                      if (controller
                                                              .phoneController
                                                              .text
                                                              .trim()
                                                              .length !=
                                                          9) {
                                                        _showError(
                                                            "El teléfono debe tener 9 dígitos");
                                                        return;
                                                      }
                                                      if (codeController.text
                                                              .trim() !=
                                                          "R3T6T9") {
                                                        _showError(
                                                            "Código de verificación incorrecto");
                                                        return;
                                                      }
                                                      controller.registerUser();
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
                                                      'REGISTRARSE',
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

                            // Footer: login
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 36.0, top: 12),
                              child: Center(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: '¿Ya tienes una cuenta? ',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'Inicia Sesión',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Get.toNamed('/login');
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
    );
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.7),
      colorText: Colors.white,
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        CustomInputField(
          hintText: '',
          icon: icon,
          controller: controller,
          obscureText: obscureText,
          // Altura flexible: NO pasamos height
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
