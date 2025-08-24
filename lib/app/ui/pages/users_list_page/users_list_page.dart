import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/users_list_controller.dart';
import 'package:recicla_tarapoto_1/app/data/models/usermodel.dart';

class UsersListPage extends GetView<UsersListController> {
  const UsersListPage({Key? key}) : super(key: key);

  static const Color colorPrimaryDark = Color(0xFF31ADA0);
  static const Color colorPrimaryLight = Color(0xFF59D999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios registrados'),
        backgroundColor: colorPrimaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: controller.usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar usuarios: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          // Panel list con "single open" + animaciones
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _UsersPanelList(users: users),
          );
        },
      ),
    );
  }
}

class _UsersPanelList extends StatelessWidget {
  const _UsersPanelList({required this.users});
  final List<UserModel> users;

  static const Color colorPrimaryDark = Color(0xFF31ADA0);
  static const Color colorPrimaryLight = Color(0xFF59D999);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        materialGapSize: 8,
        animationDuration: const Duration(milliseconds: 220),
        children: users.map((u) {
          final title = [u.name, u.lastname]
              .where((s) => s.trim().isNotEmpty)
              .join(' ')
              .trim();
          final subtitle = 'DNI: ${u.dni.isNotEmpty ? u.dni : '—'}';

          return ExpansionPanelRadio(
            value: u.uid, // <- garantiza “solo uno abierto”
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              // Dispara carga de KPIs cuando está expandido (idempotente por tu caché)
              if (isExpanded) {
                final c = Get.find<UsersListController>();
                c.loadStatsFor(u.uid);
                c.expandedUid.value =
                    u.uid; // opcional, por si lo usas en otra parte
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: isExpanded
                      ? const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3))
                        ]
                      : const [],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorPrimaryLight.withOpacity(.2),
                      foregroundColor: colorPrimaryDark,
                      child: Text(
                        (u.name.isNotEmpty ? u.name[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title.isEmpty ? '—' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    // 👇 Eliminamos el icono manual para evitar duplicado.
                    // El ExpansionPanelList ya dibuja su chevron a la derecha.
                  ],
                ),
              );
            },
            body: _UserPanelBody(user: u),
          );
        }).toList(),
      ),
    );
  }
}

class _UserPanelBody extends StatelessWidget {
  const _UserPanelBody({required this.user});
  final UserModel user;

  static const Color colorPrimaryDark = Color(0xFF31ADA0);
  static const Color colorPrimaryLight = Color(0xFF59D999);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersListController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(),
          _row(Icons.phone_iphone, 'Teléfono', user.phoneNumber),
          _row(Icons.location_on_outlined, 'Dirección', user.address),
          _typeUserRow(user.typeUser),

          const SizedBox(height: 8),

          // KPIs (reactivo)
          Obx(() {
            final s = controller.getStats(user.uid);
            if (s == null || s.loading) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: const [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Cargando estadísticas...'),
                  ],
                ),
              );
            }
            if (s.error != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(s.error!,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );
            }

            final items = [
              _miniStat(Icons.scale, 'Residuos',
                  '${s.totalKg.toStringAsFixed(1)} kg'),
              _miniStat(
                  Icons.recycling, 'Recolecciones', '${s.totalRecolecciones}'),
              _miniStat(
                  Icons.card_giftcard, 'Incentivos', '${s.totalIncentivos}'),
            ];

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorPrimaryLight.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorPrimaryLight.withOpacity(.4)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final cardWidth = (constraints.maxWidth - spacing) / 2;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen del usuario',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: items
                            .map((w) => SizedBox(width: cardWidth, child: w))
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorPrimaryDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: value.isNotEmpty ? value : '—'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _typeUserRow(List<String> types) {
    final chips = (types.isNotEmpty ? types : const ['—']).map((t) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6, top: 6),
        decoration: BoxDecoration(
          color: colorPrimaryLight.withOpacity(.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorPrimaryLight),
        ),
        child: Text(t,
            style: const TextStyle(fontSize: 12, color: colorPrimaryDark)),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.group, color: colorPrimaryDark, size: 18),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('Tipo de usuario:',
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Wrap(children: chips)),
        ],
      ),
    );
  }

  static Widget _miniStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colorPrimaryLight.withOpacity(.6)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorPrimaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
