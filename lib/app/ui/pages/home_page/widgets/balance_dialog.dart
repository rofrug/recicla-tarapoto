import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';

import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class BalanceDialog extends StatefulWidget {
  const BalanceDialog({super.key});

  @override
  State<BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<BalanceDialog> {
  static const Color primaryGreen = Color(0xFF16A34A);

  // Audio simple
  late final AudioPlayer _player = AudioPlayer();
  bool _audioReady = false;
  bool _disposed = false;

  // Timer para disparar a los 700ms
  Timer? _t700;
  bool _timerArmed = false;
  bool _played = false;

  // Ruta del asset
  static const String _assetKey = 'lib/assets/sounds/coin.mp3';

  // Duración de tu animación
  static const Duration _countAnimDuration = Duration(milliseconds: 800);
  static const Duration _offset700 = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    // Traer saldo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<HomeController>().fetchTotalCoins();
    });

    _setupAudio();
  }

  Future<void> _setupAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      await _player.setLoopMode(LoopMode.off);
      await _player.setVolume(1.0);
      await _player.setAsset(_assetKey); // precarga
      _audioReady = true;
    } catch (_) {
      _audioReady = false;
    }
  }

  Future<void> _playOnce() async {
    if (_disposed) return;
    try {
      if (!_audioReady) {
        await _player.setAsset(_assetKey);
        _audioReady = true;
      }
      await _player.stop();
      await _player.setSpeed(1.0);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _t700?.cancel();
    _player.dispose();
    super.dispose();
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
            const Text(
              "Mis Monedas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryGreen,
              ),
            ),
            Obx(() {
              if (home.isLoadingCoins.value) {
                // Mientras carga, reseteamos banderas por si re-entra
                _t700?.cancel();
                _timerArmed = false;
                _played = false;

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

              return TweenAnimationBuilder<double>(
                key: ValueKey(coins),
                tween: Tween<double>(begin: 0, end: coins),
                duration: _countAnimDuration,
                // Respaldo: si por algún motivo no sonó a los 700ms, suena al terminar
                onEnd: () {
                  if (!_played) {
                    _t700?.cancel();
                    _played = true;
                    _playOnce();
                  }
                },
                builder: (_, value, __) {
                  // Armar el timer de 700ms en el primer build de esta animación
                  if (!_timerArmed) {
                    _timerArmed = true;
                    _t700?.cancel();
                    _t700 = Timer(_offset700, () {
                      if (!_disposed && !_played) {
                        _played = true;
                        _playOnce();
                      }
                    });
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.3),
                        width: 2,
                      ),
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
