import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore para validar y reservar DNI
import 'package:recicla_tarapoto_1/app/data/provider/authprovider.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dniController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final userType = 'Casa'.obs; // Variable reactiva para el tipo de usuario
  final isLoading = false.obs; // Variable para manejar el loading

  final AuthProvider _authProvider =
      AuthProvider(); // Instancia de AuthProvider
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------
  // Helpers
  // ---------------------------
  String _normalizeDni(String raw) {
    // Solo dígitos y trim
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '').trim();
    return digits;
  }

  bool _validateFields({
    required String name,
    required String lastName,
    required String email,
    required String dni,
    required String phone,
    required String address,
    required String password,
  }) {
    if (name.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        dni.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        password.isEmpty) {
      Get.snackbar('Error', 'Por favor, completa todos los campos.');
      return false;
    }

    // Validación básica de email
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    if (!emailOk) {
      Get.snackbar('Correo inválido', 'Ingresa un correo electrónico válido.');
      return false;
    }

    // Perú: DNI de 8 dígitos (ajusta si fuera otro formato)
    if (dni.length != 8) {
      Get.snackbar('DNI inválido', 'El DNI debe tener 8 dígitos.');
      return false;
    }

    // Teléfono mínimo 9 dígitos (ajusta a tu regla)
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
      Get.snackbar(
          'Teléfono inválido', 'Ingresa un número de teléfono válido.');
      return false;
    }

    if (password.length < 6) {
      Get.snackbar('Contraseña débil',
          'La contraseña debe tener al menos 6 caracteres.');
      return false;
    }

    return true;
  }

  /// Verifica de forma rápida si existe ya un usuario con ese DNI
  Future<bool> _dniExistsQuick(String dni) async {
    final snap = await _db
        .collection('users')
        .where('dni', isEqualTo: dni)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Reserva atómicamente el DNI usando una transacción en la colección `dni_index`
  /// para evitar condiciones de carrera (dos registros simultáneos).
  /// Si el doc `dni_index/{dni}` ya existe, lanza error.
  Future<void> _reserveDniOrThrow(String dni) async {
    final ref = _db.collection('dni_index').doc(dni);
    await _db.runTransaction((txn) async {
      final doc = await txn.get(ref);
      if (doc.exists) {
        throw Exception('DNI ya registrado');
      }
      txn.set(ref, {
        'dni': dni,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// En caso de que falle el flujo de registro luego de reservar el DNI,
  /// liberamos la reserva para no dejar "bloqueado" el DNI.
  Future<void> _releaseDni(String dni) async {
    try {
      await _db.collection('dni_index').doc(dni).delete();
    } catch (_) {
      // Si no existe o falla, no es crítico.
    }
  }

  // ---------------------------
  // Registro
  // ---------------------------
  Future<void> registerUser() async {
    // Normalización y lecturas
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final dni = _normalizeDni(dniController.text);
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final password = passwordController.text;
    final selectedUserType = userType.value;

    // Validaciones
    if (!_validateFields(
      name: name,
      lastName: lastName,
      email: email,
      dni: dni,
      phone: phone,
      address: address,
      password: password,
    )) return;

    isLoading.value = true;

    // Datos del usuario a registrar
    final Map<String, dynamic> userData = {
      'name': name,
      'lastname': lastName,
      'email': email,
      'dni': dni,
      'phone_number': phone,
      'address': address,
      'type_user': [selectedUserType],
      'iscollector': false, // Por defecto GENERADOR
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // 1) Chequeo rápido (UX): evita hacer auth si ya existe
      final exists = await _dniExistsQuick(dni);
      if (exists) {
        Get.snackbar(
            'DNI ya registrado', 'Este DNI ya está vinculado a una cuenta.');
        return;
      }

      // 2) Reserva atómica (a prueba de carreras)
      await _reserveDniOrThrow(dni);

      // 3) Crear usuario (Auth + Firestore)
      final user =
          await _authProvider.registerWithEmail(email, password, userData);

      if (user != null) {
        Get.snackbar('Registro exitoso', 'Usuario registrado correctamente');
        // Navegar al LOGIN y limpiar el stack
        Get.offAllNamed(Routes.LOGIN);
      } else {
        // Si por alguna razón no retorna user, liberamos la reserva
        await _releaseDni(dni);
        Get.snackbar('Error', 'No se pudo registrar el usuario');
      }
    } catch (e) {
      // Si falla, liberar reserva del DNI
      await _releaseDni(dni);

      final msg = e.toString().contains('DNI ya registrado')
          ? 'El DNI ya está registrado.'
          : 'Hubo un problema al registrar el usuario.';
      Get.snackbar('Error', msg);

      // ignore: avoid_print
      print('Error en el registro: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
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
