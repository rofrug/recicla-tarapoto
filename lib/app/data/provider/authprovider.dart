// lib/app/data/provider/authprovider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

import '../models/usermodel.dart';

class AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instancia del storage (usa el mismo nombre que inicializaste en main: 'GlobalStorage')
  final GetStorage _box = GetStorage('GlobalStorage');

  // Iniciar sesión con correo y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = result.user;

      if (user != null) {
        final uid = user.uid;
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final userModel =
              UserModel.fromFirestore(userDoc.data() as Map<String, dynamic>);

          _box.write('loggedIn', true);
          _box.write('iscollector', userModel.iscollector);
          _box.write('userData', userModel.toFirestore());
        } else {
          print('Usuario no encontrado en Firestore.');
        }
      }
      return user;
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return null;
    }
  }

  // Registrar un nuevo usuario con correo y contraseña
  Future<User?> registerWithEmail(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      // Crear nuevo usuario en Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = result.user;

      if (user != null) {
        final uid = user.uid;

        // ✅ Escribir en Firestore forzando iscollector=false (defensa en profundidad)
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': userData['name'] ?? '',
          'lastname': userData['lastname'] ?? '',
          'email': userData['email'] ?? '', // opcional pero útil
          'dni': userData['dni'] ?? '',
          'phone_number': userData['phone_number'] ?? '',
          'address': userData['address'] ?? '',
          'type_user': userData['type_user'] ?? [],
          'iscollector': userData['iscollector'] ?? false, // <- clave aquí
          'created_at': FieldValue.serverTimestamp(), // opcional
        });

        // Traer y guardar localmente
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userModel =
              UserModel.fromFirestore(userDoc.data() as Map<String, dynamic>);
          _box.write('loggedIn', true);
          _box.write('iscollector', userModel.iscollector);
          _box.write('userData', userModel.toFirestore());
        }
      }

      return user;
    } catch (e) {
      print("Error al registrar: $e");
      return null;
    }
  }

  // Restablecer contraseña
  Future<void> changePassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Correo de restablecimiento de contraseña enviado a $email.');
    } catch (e) {
      print("Error al enviar correo de restablecimiento de contraseña: $e");
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _box.write('loggedIn', false);
      _box.remove('userData');
      print("Sesión cerrada y Storage limpiado.");
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }
}
