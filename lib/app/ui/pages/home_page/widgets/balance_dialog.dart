import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';

class BalanceDialog extends StatefulWidget {
  const BalanceDialog({super.key});

  @override
  State<BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<BalanceDialog> {
  static const Color primaryGreen = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    // Antes: Get.find<HomeController>().fetchTotalCoins();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<HomeController>().fetchTotalCoins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 0),

            // Título
            const Text(
              "Mis Monedas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 0),

            // Saldo (reactivo)
            Obx(() {
              if (home.isLoadingCoins.value) {
                return Container(
                  height: 125,
                  width: 125,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              final coins = home.totalCoins.value;

              // Animación de conteo al valor actual
              return TweenAnimationBuilder<double>(
                key: ValueKey(coins), // fuerza nueva animación al cambiar saldo
                tween: Tween<double>(begin: 0, end: coins),
                duration: const Duration(milliseconds: 800),
                builder: (_, value, __) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: primaryGreen.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Text(
                      "${value.toInt()} 🪙",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: 6),

            const Text(
              "¿Cómo conseguir más?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              "Mira cuánto vale cada kilo de residuo que entregues. Si los separas por tipo, te llevas unas monedas extra 😉",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 6),

            // Equivalencias
            _buildEquivalenceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEquivalenceList() {
    final data = [
      ["Papel / Cartón", "50", Icons.description],
      ["Plástico", "100", Icons.local_drink],
      ["Metales", "50", Icons.bolt],
    ];

    return Column(
      children: data.map((item) {
        final label = item[0] as String;
        final value = item[1] as String;
        final icon = item[2] as IconData;

        return Card(
          color: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: primaryGreen, width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryGreen.withOpacity(0.1),
              child: Icon(icon, color: primaryGreen),
            ),
            title: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              "$value monedas",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget (antes _buildItemRow) que muestra el título, la fecha y la cantidad de puntos.
class _ItemRowWidget extends StatelessWidget {
  final String title;
  final String date;
  final String points;

  const _ItemRowWidget({
    Key? key,
    required this.title,
    required this.date,
    required this.points,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF59D999),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "$points\$",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
