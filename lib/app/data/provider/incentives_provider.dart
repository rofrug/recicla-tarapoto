// lib/app/providers/incentives_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/data/models/incentive.dart';

class IncentivesProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de incentivos (incluye 'stock' si existe en documentos)
  Stream<List<Incentive>> getIncentives() {
    return _firestore
        .collection('incentives')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        return Incentive.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Agrega un nuevo incentivo a la colección 'incentives'.
  Future<DocumentReference<Map<String, dynamic>>> addIncentive(
      Incentive incentive) async {
    try {
      return await _firestore
          .collection('incentives')
          .add(incentive.toFirestore());
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo agregar el incentivo',
        backgroundColor: Colors.redAccent,
      );
      rethrow;
    }
  }

  /// Actualiza un incentivo existente en la colección 'incentives'.
  Future<void> updateIncentive(String docId, Incentive incentive) async {
    try {
      await _firestore
          .collection('incentives')
          .doc(docId)
          .update(incentive.toFirestore());

      Get.snackbar(
        'Éxito',
        'El incentivo ha sido actualizado correctamente.',
        backgroundColor: Colors.greenAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar el incentivo',
        backgroundColor: Colors.redAccent,
      );
      rethrow;
    }
  }

  /// Elimina (físicamente) un incentivo de la colección 'incentives'.
  Future<void> deleteIncentive(String docId) async {
    try {
      await _firestore.collection('incentives').doc(docId).delete();
      Get.snackbar(
        'Completo',
        'El incentivo ha sido eliminado correctamente',
        backgroundColor: Colors.greenAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el incentivo',
        backgroundColor: Colors.redAccent,
      );
      rethrow;
    }
  }

  /// Obtiene un incentivo por su ID de documento.
  Future<Incentive?> getIncentiveById(String incentiveId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('incentives').doc(incentiveId).get();

      if (doc.exists) {
        final Map<String, dynamic>? data = doc.data();
        if (data == null) return null;
        return Incentive.fromFirestore(data, doc.id);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error al obtener el incentivo: $e');
      return null;
    }
  }

  /// Canje transaccional con soporte de idempotencia.
  ///
  /// - Decrementa stock atómicamente (nunca queda negativo).
  /// - Crea el documento en users/{userId}/redeemedIncentives.
  /// - Si [idempotencyKey] viene y ya existe un doc con ese ID, no duplica el canje.
  ///
  /// Lanza FirebaseException con codes:
  /// - 'incentive-not-found'
  /// - 'out-of-stock'
  Future<void> redeemIncentiveTransactional({
    required String userId,
    required Incentive incentive,
    int qty = 1,
    String? idempotencyKey,
  }) async {
    final DocumentReference<Map<String, dynamic>> incentivesRef =
        _firestore.collection('incentives').doc(incentive.id);
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);

    // Si llega idempotencyKey, usamos ese como ID del doc de canje
    final DocumentReference<Map<String, dynamic>> redeemedRef =
        (idempotencyKey != null && idempotencyKey.isNotEmpty)
            ? userRef.collection('redeemedIncentives').doc(idempotencyKey)
            : userRef.collection('redeemedIncentives').doc();

    await _firestore.runTransaction((t) async {
      // Idempotencia: si el doc ya existe, no hacer nada
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        final DocumentSnapshot<Map<String, dynamic>> idemSnap =
            await t.get(redeemedRef);
        if (idemSnap.exists) {
          // Ya procesado anteriormente
          return;
        }
      }

      // 1) Leer incentivo y validar stock
      final DocumentSnapshot<Map<String, dynamic>> incSnap =
          await t.get(incentivesRef);
      if (!incSnap.exists) {
        throw FirebaseException(
          plugin: 'IncentivesProvider',
          code: 'incentive-not-found',
        );
      }

      final Map<String, dynamic> data = incSnap.data() ?? {};
      final int currentStock = ((data['stock'] ?? 0) as num).toInt();

      if (currentStock < qty) {
        throw FirebaseException(
          plugin: 'IncentivesProvider',
          code: 'out-of-stock',
        );
      }

      // 2) Decrementar stock
      t.update(incentivesRef, {
        'stock': FieldValue.increment(-qty),
      });

      // 3) Registrar canje
      t.set(redeemedRef, {
        'incentiveId': incentive.id,
        'name': incentive.name,
        'description': incentive.description,
        'price': incentive.price,
        'image': incentive.image,
        'qty': qty,
        'redeemedCoins': incentive.price * qty,
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
        'incentiveRef': incentivesRef,
        'userRef': userRef,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      });
    });
  }
}
