import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/profilecollector_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/collector_stats_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/collector_history_controller.dart';
import 'package:get_storage/get_storage.dart';

class ProfilecollectorPage extends GetView<ProfilecollectorController> {
  ProfilecollectorPage({Key? key}) : super(key: key);

  // Controlador de estadísticas del recolector
  final CollectorStatsController stats = Get.put(CollectorStatsController());
  final CollectorHistoryController history =
      Get.put(CollectorHistoryController());

  // Helpers
  String _safeName() {
    try {
      final uc = Get.find<UserController>();
      final m = uc.userModel.value;
      // Ajusta estos campos a tu modelo real (name / displayName / email)
      final name = (m?.name ?? 'Recolector').toString();
      return name.isNotEmpty ? name : 'Recolector';
    } catch (_) {
      return 'Recolector';
    }
  }

  String _initialsFrom(String fullName) {
    if (fullName.trim().isEmpty) return 'R';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first.characters.first : 'R';
    return first.toUpperCase();
  }

  void _logout() {
    try {
      final uc = Get.find<UserController>();
      uc.logout();
    } catch (e) {
      // Fallback por si no está registrado el UserController
      Get.snackbar('Sesión', 'No se pudo cerrar sesión. Reintenta.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Map<String, String> _collectorInfo() {
    // Intenta desde UserController
    try {
      final uc = Get.find<UserController>();
      final m = uc.userModel.value;
      final nombre = (m?.name ?? '').toString();
      final apellido = (m?.lastname ?? '').toString();
      final fullName =
          [nombre, apellido].where((s) => s.trim().isNotEmpty).join(' ').trim();
      return {
        'nombre':
            fullName.isNotEmpty ? fullName : (nombre.isNotEmpty ? nombre : '—'),
        'dni': (m?.dni ?? '—').toString(),
        'telefono': (m?.phoneNumber ?? '—').toString(),
        'direccion': (m?.address ?? '—').toString(),
      };
    } catch (_) {
      // Fallback a GetStorage
      final box = GetStorage('GlobalStorage');
      final data = box.read('userData') as Map?;
      final nombre = (data?['name'] ?? '').toString();
      final apellido = (data?['lastname'] ?? '').toString();
      final fullName =
          [nombre, apellido].where((s) => s.trim().isNotEmpty).join(' ').trim();
      return {
        'nombre':
            fullName.isNotEmpty ? fullName : (nombre.isNotEmpty ? nombre : '—'),
        'dni': (data?['dni'] ?? '—').toString(),
        'telefono': (data?['phone_number'] ?? '—').toString(),
        'direccion': (data?['address'] ?? '—').toString(),
      };
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF31ADA0), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _myInfoCard() {
    final info = _collectorInfo();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'Nombre', info['nombre'] ?? '—'),
          const Divider(height: 9),
          _infoRow(Icons.credit_card, 'DNI', info['dni'] ?? '—'),
          const Divider(height: 9),
          _infoRow(Icons.phone, 'Teléfono', info['telefono'] ?? '—'),
          const Divider(height: 9),
          _infoRow(Icons.location_on_outlined, 'Dirección',
              info['direccion'] ?? '—'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF59D999), Color(0xFF31ADA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final name = _safeName();
    final initial = _initialsFrom(name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con inicial
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF59D999), Color(0xFF31ADA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Nombre + rol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 4),
                const Text(
                  'Recolector',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Botón cerrar sesión pequeñito
          TextButton.icon(
            onPressed: _logout,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              foregroundColor: const Color(0xFF31ADA0),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Obx(() {
        // Mostramos carga general si aún está trayendo datos
        final loading = stats.isLoading.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(context),
              const SizedBox(height: 15),
              const Text(
                'Mi Información',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _myInfoCard(),
              const SizedBox(height: 15),
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ))
              else
                Column(
                  children: [
                    // Card grande: Residuos Totales (Kg)
                    _buildStatCard(
                      'Total de residuos recolectados',
                      '${stats.totalKgRecolectado.value.toStringAsFixed(1)} Kg',
                      double.infinity,
                    ),
                    const SizedBox(height: 10),

                    // Dos cards: Incentivos y Recolección
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Incent. reclamados',
                            '${stats.totalIncentivosEntregados.value}',
                            screenWidth * .45,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _buildStatCard(
                            'Recolec. realizadas',
                            '${stats.totalRecolecciones.value}',
                            screenWidth * .45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              const Text(
                'Historial de recolecciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              Obx(() {
                if (history.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (history.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sin recolecciones registradas.'),
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: history.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final it = history.items[i];
                    final fecha = history.formatDate(it.date);
                    final titulo = '${it.userName} • $fecha';
                    final subtitulo = it.address.isNotEmpty ? it.address : '—';
                    final trailing = '${it.kg.toStringAsFixed(1)} Kg';
                    return _historyItem(
                      title: titulo,
                      subtitle: subtitulo,
                      trailing: trailing,
                    );
                  },
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _historyItem({
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF59D999), Color(0xFF31ADA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.recycling, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
