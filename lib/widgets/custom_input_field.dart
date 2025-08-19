import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final double? width;

  /// Deja null para altura automática (recomendado).
  final double? height;
  final TextStyle? textStyle;
  final Function(String)? onChanged;

  // Nuevos parámetros
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon; // ← para el ojito u otros botones

  const CustomInputField({
    Key? key,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.width,
    this.height,
    this.textStyle,
    this.onChanged,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.suffixIcon,
  }) : super(key: key);

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late FocusNode _focusNode;

  /// Controla si el ícono a la izquierda se ve o no.
  bool showIcon = true;

  /// Listener del controlador.
  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    // Listener de foco
    _focusNode.addListener(() {
      setState(() {
        if (_focusNode.hasFocus) {
          // Al hacer foco, ocultamos el ícono
          showIcon = false;
        } else {
          // Al perder foco, mostramos el ícono si el campo está vacío
          showIcon = widget.controller?.text.isEmpty ?? true;
        }
      });
    });

    // Listener de texto
    _controllerListener = () {
      if (!_focusNode.hasFocus) {
        setState(() {
          showIcon = widget.controller?.text.isEmpty ?? true;
        });
      }
    };

    widget.controller?.addListener(_controllerListener!);
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      widget.controller?.removeListener(_controllerListener!);
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construimos los inputFormatters finales.
    // Si el teclado es numérico/phone, aplicamos digitsOnly automáticamente.
    List<TextInputFormatter>? finalFormatters = widget.inputFormatters;
    final isNumericKb = widget.keyboardType == TextInputType.number ||
        widget.keyboardType == TextInputType.phone;

    if (isNumericKb) {
      finalFormatters = <TextInputFormatter>[
        ...?finalFormatters,
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    final field = TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      obscureText: widget.obscureText,
      style: widget.textStyle ?? const TextStyle(color: Colors.white),
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      inputFormatters: finalFormatters,
      maxLines: 1, // evita crecer verticalmente
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: (widget.textStyle ?? const TextStyle())
            .copyWith(color: Colors.white70),
        // Ícono a la izquierda solo si showIcon es true
        prefixIcon: showIcon ? Icon(widget.icon, color: Colors.white) : null,
        // Ícono a la derecha (ej. ojito de contraseña)
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: const Color.fromRGBO(255, 255, 255, 0.30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        counterText: "", // oculta contador
      ),
    );

    // Ancho y altura opcionales (altura flexible si es null)
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height, // si es null, el TextField se auto-ajusta
      child: field,
    );
  }
}
