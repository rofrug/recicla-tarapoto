// lib/app/ui/pages/profilecollector_page/profilecollector_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/profilecollector_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/collector_stats_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_stats_controller.dart';
import 'package:recicla_tarapoto_1/app/routes/app_pages.dart';

class ProfilecollectorPage extends GetView<ProfilecollectorController> {
  ProfilecollectorPage({Key? key}) : super(key: key);

  final CollectorStatsController stats = Get.put(CollectorStatsController());
  final UserStatsController userStats = Get.put(UserStatsController());

  // Helpers
  String _safeName() {
    try {
      final uc = Get.find<UserController>();
      final m = uc.userModel.value;
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
      Get.snackbar('Sesión', 'No se pudo cerrar sesión. Reintenta.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Map<String, String> _collectorInfo() {
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

  Widget _buildCompactCard(String title, String value, {VoidCallback? onTap}) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF59D999), Color(0xFF31ADA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1, // ✅
            overflow: TextOverflow.ellipsis, // ✅
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // lo dejaste en 18 para no generar scroll
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        onTap: onTap,
        child: card,
      ),
    );
  }

  void _showStatDetails(String title, String value, String note) {
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF31ADA0),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ evita overflow
          children: [
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2, // ✅ por si el número es largo
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'Cerrar',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF31ADA0),
      radius: 10,
      barrierDismissible: true,
      onConfirm: Get.back, // ✅ botón Cerrar funcional
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
              name.isNotEmpty ? _initialsFrom(name) : 'R',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
    return Scaffold(
      body: Obx(() {
        final loading = stats.isLoading.value || userStats.isLoading.value;

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
              const SizedBox(height: 10),
              const Text(
                'Resumen de totales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ))
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 27,
                  mainAxisSpacing: 6,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  children: [
                    _buildCompactCard(
                      'Residuos',
                      '${stats.totalKgRecolectado.value.toStringAsFixed(1)} Kg',
                      onTap: () => _showStatDetails(
                        'Total de residuos recolectados',
                        '${stats.totalKgRecolectado.value.toStringAsFixed(1)} Kg',
                        'Este valor corresponde a la suma de kg de todos los usuarios registrados.',
                      ),
                    ),
                    _buildCompactCard(
                      'Usuarios',
                      '${userStats.totalUsuariosRegistrados.value}',
                      onTap: () => Get.toNamed(Routes.USERS_LIST),
                    ),
                    _buildCompactCard(
                      'Recolecciones',
                      '${stats.totalRecolecciones.value}',
                      onTap: () => _showStatDetails(
                        'Recolecciones realizadas',
                        '${stats.totalRecolecciones.value}',
                        'Número total de recolecciones que se están realizando hasta la fecha.',
                      ),
                    ),
                    _buildCompactCard(
                      'Incentivos',
                      '${stats.totalIncentivosEntregados.value}',
                      onTap: () => _showStatDetails(
                        'Incentivos reclamados',
                        '${stats.totalIncentivosEntregados.value}',
                        'Cantidad de incentivos totales que han sido entregados a los usuarios.',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }
}
