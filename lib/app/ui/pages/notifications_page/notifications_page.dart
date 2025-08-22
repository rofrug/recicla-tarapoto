import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/notifications_controller.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsController controller = Get.put(NotificationsController());

  // Paleta consistente con la app
  static const Color kPrimary = Color(0xFF31ADA0);
  static const Color kPrimary2 = Color(0xFF59D999);
  static const Color kInk = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Header / Hero ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimary2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.campaign, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de Comunicaciones',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: .2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Envía comunicados y gestiona el contenido del carrusel informativo.',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ---------- Sección: Enviar Comunicado ----------
            _SectionTitle(icon: Icons.send, title: 'Enviar Comunicado'),
            const SizedBox(height: 10),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Obx(() {
                    final tc = controller.titleController.value;
                    return _LabeledField(
                      label: 'Título',
                      hint: 'Escribe un título breve y claro',
                      icon: Icons.title,
                      controller: tc,
                      maxLines: 1,
                      // Contador reactivo
                      footerBuilder: () => Text(
                        '${tc.text.characters.length}/120',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (v) {
                        // si quieres limitar, puedes recortar:
                        if (v.length > 120) {
                          tc.text = v.substring(0, 120);
                          tc.selection = TextSelection.fromPosition(
                              TextPosition(offset: tc.text.length));
                        }
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 12),

                  // Contenido
                  Obx(() {
                    final cc = controller.contentController.value;
                    return _LabeledField(
                      label: 'Contenido',
                      hint: 'Redacta el mensaje del comunicado',
                      icon: Icons.description_outlined,
                      controller: cc,
                      maxLines: 3,
                      footerBuilder: () => Text(
                        '${cc.text.characters.length}/300',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (v) {
                        if (v.length > 300) {
                          cc.text = v.substring(0, 300);
                          cc.selection = TextSelection.fromPosition(
                              TextPosition(offset: cc.text.length));
                        }
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 16),

                  // Botón enviar
                  Obx(() {
                    final isSending = controller.isSendingAnnouncement.value;
                    final disabled = isSending;
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: disabled
                            ? null
                            : () => controller.sendAnnouncement(context),
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          isSending ? 'Enviando...' : 'Enviar comunicado',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ---------- Sección: Subir al Carrusel ----------
            _SectionTitle(
                icon: Icons.slideshow, title: 'Subir Contenido al Carrusel'),
            const SizedBox(height: 10),
            _buildCard(
              child: Obx(() {
                final isLoading = controller.isLoading.value;
                final reason = controller.reason.value;
                final hasImage = controller.selectedImage.value != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Motivo chips
                    const Text(
                      'Motivo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoicePill(
                          label: 'Participacion',
                          selected: reason == 'participacion',
                          onSelected: (sel) =>
                              controller.setReason(sel ? 'participacion' : ''),
                        ),
                        _ChoicePill(
                          label: 'Premio',
                          selected: reason == 'premio',
                          onSelected: (sel) =>
                              controller.setReason(sel ? 'premio' : ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Imagen: placeholder o preview
                    if (!hasImage)
                      _ImagePlaceholder(
                        onTap: isLoading ? null : controller.pickImage,
                      )
                    else
                      _ImagePreview(
                        file: controller.selectedImage.value!,
                        onChange: isLoading ? null : controller.pickImage,
                      ),

                    const SizedBox(height: 16),

                    // Indicador de progreso (upload)
                    if (isLoading)
                      Column(
                        children: const [
                          LinearProgressIndicator(
                            color: kPrimary,
                            minHeight: 5,
                          ),
                          SizedBox(height: 10),
                        ],
                      ),

                    // Botón enviar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => controller.uploadCarouselImage(context),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          isLoading ? 'Subiendo...' : 'Enviar al carrusel',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Card con sombra suave ----------
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      shadowColor: kPrimary.withOpacity(.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

// ================== Widgets de apoyo estilizados ==================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  static const Color kPrimary = _NotificationsPageState.kPrimary;
  static const Color kInk = _NotificationsPageState.kInk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x1A31ADA0),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.check, color: kPrimary, size: 18),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: kPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
    this.footerBuilder,
    this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;
  final Widget Function()? footerBuilder;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _NotificationsPageState.kInk),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: _NotificationsPageState.kPrimary),
            filled: true,
            fillColor: const Color(0xFFF7FBFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2F0EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2F0EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _NotificationsPageState.kPrimary),
            ),
          ),
        ),
        if (footerBuilder != null) ...[
          const SizedBox(height: 6),
          footerBuilder!(),
        ],
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : _NotificationsPageState.kPrimary,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: _NotificationsPageState.kPrimary,
      backgroundColor: const Color(0x1431ADA0),
      side: BorderSide(
        color: selected
            ? _NotificationsPageState.kPrimary
            : const Color(0x2231ADA0),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2F0EC)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image_outlined,
                  color: _NotificationsPageState.kPrimary, size: 28),
              SizedBox(height: 6),
              Text(
                'Toca para seleccionar una imagen',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, required this.onChange});
  final dynamic file; // dinámico para no requerir import de dart:io aquí
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ElevatedButton.icon(
            onPressed: onChange,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Cambiar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
