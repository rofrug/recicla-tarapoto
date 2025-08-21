// lib/app/data/provider/wasteCollectionsProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/waste_collection.dart';

class WasteCollectionsProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recolecciones PENDIENTES (isRecycled = false)
  Stream<List<WasteCollectionModel>> getPendingWasteCollections() {
    return _firestore
        .collection('wasteCollections')
        .where('isRecycled', isEqualTo: false)
        .snapshots()
        .map((qs) => qs.docs
            .map((doc) => WasteCollectionModel.fromFirestore(doc))
            .toList());
  }

  /// Recolecciones COMPLETADAS (historial) SIN orderBy para evitar índice compuesto.
  /// El orden por fecha desc se aplica en HomecollectorController.
  Stream<List<WasteCollectionModel>> getCompletedWasteCollections(
      {int limit = 100}) {
    return _firestore
        .collection('wasteCollections')
        .where('isRecycled', isEqualTo: true)
        .limit(limit) // opcional
        .snapshots()
        .map((qs) => qs.docs
            .map((doc) => WasteCollectionModel.fromFirestore(doc))
            .toList());
  }

  /// Actualiza un documento de la colección a partir de su ID
  Future<void> updateWasteCollection(
      String docId, WasteCollectionModel updatedModel) async {
    try {
      // Validación básica
      if (updatedModel.totalKg <= 0) {
        Get.snackbar(
          'Datos inválidos',
          'El total de Kg debe ser mayor a 0.',
          snackPosition: SnackPosition.TOP,
        );
        throw ArgumentError('totalKg debe ser > 0 en updateWasteCollection');
      }

      await _firestore
          .collection('wasteCollections')
          .doc(docId)
          .update(updatedModel.toFirestore());
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la recolección');
      rethrow;
    }
  }

  /// Agrega una nueva recolección
  Future<DocumentReference> addWasteCollection(
      WasteCollectionModel wasteCollection) async {
    try {
      if (wasteCollection.totalKg <= 0) {
        Get.snackbar(
          'Datos inválidos',
          'El total de Kg debe ser mayor a 0.',
          snackPosition: SnackPosition.TOP,
        );
        throw ArgumentError('totalKg debe ser > 0 en addWasteCollection');
      }

      return await _firestore
          .collection('wasteCollections')
          .add(wasteCollection.toFirestore());
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo agregar la recolección',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Elimina físicamente una recolección
  Future<void> deleteWasteCollection(String docId) async {
    try {
      await _firestore.collection('wasteCollections').doc(docId).delete();
      Get.snackbar(
        'Completo',
        'La recolección ha sido eliminada correctamente',
        backgroundColor: Colors.greenAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar la recolección',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Obtiene una recolección por ID
  Future<WasteCollectionModel?> getWasteCollectionById(String docId) async {
    try {
      final doc =
          await _firestore.collection('wasteCollections').doc(docId).get();
      if (doc.exists) {
        return WasteCollectionModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error al obtener la recolección: $e');
      return null;
    }
  }
}
