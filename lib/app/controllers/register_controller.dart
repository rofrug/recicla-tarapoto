import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/data/provider/authprovider.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  var nameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var dniController = TextEditingController();
  var phoneController = TextEditingController();
  var addressController = TextEditingController();
  var passwordController = TextEditingController();
  var userType = 'Casa'.obs; // Variable reactiva para el tipo de usuario

  var isLoading = false.obs; // Variable para manejar el loading

  final AuthProvider _authProvider =
      AuthProvider(); // Instancia de AuthProvider

  // Lógica para registrar el usuario
  Future<void> registerUser() async {
    String name = nameController.text;
    String lastName = lastNameController.text;
    String email = emailController.text;
    String dni = dniController.text;
    String phone = phoneController.text;
    String address = addressController.text;
    String password = passwordController.text;
    String selectedUserType = userType.value;

    // Validaciones básicas
    if (name.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        dni.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        password.isEmpty) {
      Get.snackbar('Error', 'Por favor, completa todos los campos.');
      return;
    }

    // Mostrar el loading
    isLoading.value = true;

    // Datos del usuario a registrar (todo backend, no visible en UI)
    final Map<String, dynamic> userData = {
      'name': name,
      'lastname': lastName,
      'email': email,
      'dni': dni,
      'phone_number': phone,
      'address': address,
      'type_user': [selectedUserType],
      // ✅ por defecto, todo registro es GENERADOR
      'iscollector': false,
    };

    try {
      // Registrar el usuario en Firebase Authentication y guardar en Firestore
      final user =
          await _authProvider.registerWithEmail(email, password, userData);

      if (user != null) {
        Get.snackbar('Registro exitoso', 'Usuario registrado correctamente');
        // Redirigir al LOGIN y limpiar el stack para que no pueda volver al registro
        Get.offAllNamed(Routes.LOGIN);
      } else {
        Get.snackbar('Error', 'No se pudo registrar el usuario');
      }
    } catch (e) {
      Get.snackbar('Error', 'Hubo un problema al registrar el usuario');
      // ignore: avoid_print
      print('Error en el registro: $e');
    } finally {
      // Ocultar el loading
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Liberar los TextEditingControllers
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    dniController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
