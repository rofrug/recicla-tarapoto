import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/information_controller.dart';

class InformationScreen extends GetView<InformationController> {
  const InformationScreen({Key? key}) : super(key: key);

  static const Color kPrimary = Color(0xFF31ADA0);
  static const Color kPrimary2 = Color(0xFF59D999);
  static const Color kInk = Colors.black87;

  @override
  Widget build(BuildContext context) {
    // ---------- DATA (se mantiene tu contenido oficial) ----------
    final List<String> descriptions = [
      "Cada establecimiento puede producir diferentes cantidades y tipos de residuos, esto según su tipo de actividades, consumo de productos, o a las actividades a las que se dedique.",
      "La recolección de residuos en nuestra ciudad tiene horarios y también días preestablecidos para cada sector. Los sectores cuentan con jirones o avenidas según su ubicación.",
      "Al llenarse el camión, se transporta los residuos recolectados a las celdas de tratamiento que están ubicadas en Yacucatina a 45 minutos de la ciudad de Tarapoto.",
      "Al llegar los residuos a disposición final se vierte en las fosas de tratamiento, se esparce una capa de tierra. El proceso se repite hasta alcanzar la máxima capacidad.",
      "El equipo de la Unidad de Residuos Sólidos de la Municipalidad de San Martín monitorea constantemente las diferentes etapas del proceso asegurando un buen funcionamiento.",
    ];

    final List<String> titles = [
      "Generación de Residuos",
      "Recolección de Residuos",
      "Transporte de Residuos",
      "Disposición Final",
      "Monitoreo y Mantenimiento",
    ];

    final List<String> imagePaths = [
      'lib/assets/info1a.png',
      'lib/assets/info4a.png',
      'lib/assets/info2a.png',
      'lib/assets/info5a.png',
      'lib/assets/info3a.png',
    ];

    final List<String> segregationTitles = [
      "Segregación de Residuos",
      "¿Cómo Segregar?",
      "Residuos Orgánicos",
      "Residuos Inorgánicos",
      "Residuos No Aprovechables",
      "Gestión de Residuos Sólidos",
    ];

    final List<String> segregationDescriptions = [
      "Consiste en clasificar los desechos según su clasificación (orgánico, inorgánico o no aprovechables) para facilitar su reciclaje, reutilización o disposición final adecuada.\n"
          "Al segregar contribuimos a disminuir la cantidad de basura que llega a los vertederos, ahorramos recursos y promovemos una economía circular.",
      "La segregación efectiva implica depositar los residuos orgánicos, inorgánicos y no aprovechables en recipientes individuales.\n"
          "De forma alternativa, existen formas de tratar nuestros residuos, lo cual se explica de manera mas detallada en los siguientes cuadros.",
      "Previo tratamiento que se puede dar en nuestros hogares, estos desechos pueden ser aprovechados, ya que después de un proceso natural, los residuos orgánicos se convierten en abono de alta calidad.\n"
          "Cada hogar puede ser parte de la solución al implementar prácticas de segregación de residuos orgánicos.",
      "Para reciclar a gran medida los residuos inorgánicos, se requiere de procesos específicos para su gestión y a menudo se transforman en nuevos productos.\n"
          "En Tarapoto existe un proceso de recolección puerta a puerta para recolectar los diferentes tipos de residuos inorgánicos.",
      "Los residuos no aprovechables deben ser enviados a los rellenos sanitarios diseñados para contener tratar y minimizar  a gran medida su impacto ambiental.\n"
          "Tarapoto cuenta con un relleno sanitario que procesa estos residuos, evitando riesgos para la población y el medio ambiente.",
      "Los beneficios de una buena gestión y segregación de los residuos desde nuestros hogares son innumerables, y poniendo nuestro granito de arena haremos que esto funcione. Cada pequeño esfuerzo cuenta. ¡Hagamos de nuestro Tarapoto un lugar más sostenible!",
    ];

    final List<String> segregationImages = [
      'lib/assets/info1b.png',
      'lib/assets/info2b.png',
      'lib/assets/info3b.png',
      'lib/assets/info4b.png',
      'lib/assets/info5b.png',
      'lib/assets/info6b.png',
    ];

    final List<String> simpleTitles = [
      "Generación de Residuos",
      "Recolección de Residuos",
      "Transporte de Residuos",
      "Disposición Final",
    ];

    final List<String> simpleDescriptions = [
      "Así como beneficios económicos, al reciclar productos comunes en nuestros hogares como botellas de vidrios convertidos en vasos, o embaces plásticos en macetas.\n\n"
          "La segregación y el reciclaje de inorgánicos en la fuente es el primer paso para cultivar una cultura de cuidado ambiental en cada hogar.",
      "Menos volumen de residuos a la hora de la recolección, permitiendo abarcar mayor territorio con menos tiempo  y menos recursos.\n\n"
          "Minimización de riesgo de accidentes laborales durante la recolección, como cortes por vidrios o bultos demasiado pesados.",
      "Menos volumen de residuos, significa menos viajes al relleno, menor consumo de combustible, mayor ahorro de recursos económicos y prolongación de la vida útil de los vehículos recolectores.\n\n"
          "Así como la disminución de emisión de gases de efecto invernadero por parte de los vehículos recolectores.",
      "Los inorgánicos tienen un tiempo prolongado de descomposición por ende permanecen mucho más tiempo en los rellenos sanitarios ocupando espacio.\n\n"
          "Al reducir el volumen de residuos inorgánicos, se extiende la vida útil de los rellenos sanitarios y se posterga la necesidad de abrir nuevos.",
    ];

    // ---------- Controllers para carouseles (con viewportFraction para efecto carrusel) ----------
    final PageController pageController =
        PageController(viewportFraction: 0.92);
    final RxInt currentPage = 0.obs;

    final PageController segregationController =
        PageController(viewportFraction: 0.92);
    final RxInt segregationPage = 0.obs;

    final PageController simplePageController =
        PageController(viewportFraction: 0.92);
    final RxInt simpleCurrentPage = 0.obs;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HERO / HEADER ----------
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Información sobre Reciclaje',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '¿Por qué es importante reciclar?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "El reciclaje es fundamental para reducir la contaminación ambiental y conservar recursos naturales. "
                    "Al reciclar, ayudamos a disminuir la cantidad de basura enviada a los vertederos, lo cual es clave para un desarrollo sostenible.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ---------- SECCIÓN 1 ----------
            _SectionTitle(
              icon: Icons.recycling,
              title: 'Etapas de la Gestión de Residuos',
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: size.height * 0.68,
              child: Stack(
                children: [
                  PageView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: pageController,
                    onPageChanged: (i) => currentPage.value = i,
                    itemCount: descriptions.length,
                    itemBuilder: (_, index) {
                      return _StageCard(
                        imagePath: imagePaths[index],
                        title: titles[index],
                        description: descriptions[index],
                      );
                    },
                  ),
                  // dots
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Obx(() => _Dots(
                          length: descriptions.length,
                          current: currentPage.value,
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ---------- SECCIÓN 2 ----------
            _SectionTitle(
              icon: Icons.report_problem_outlined,
              title: 'Principales Problemas de la Gestión de Residuos Sólidos',
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: size.height * 0.68,
              child: Stack(
                children: [
                  PageView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: segregationController,
                    onPageChanged: (i) => segregationPage.value = i,
                    itemCount: segregationTitles.length,
                    itemBuilder: (_, index) {
                      final isLast = index == segregationTitles.length - 1;
                      return _SegregationCard(
                        isLast: isLast,
                        title: segregationTitles[index],
                        description: segregationDescriptions[index],
                        imagePath: segregationImages[index],
                      );
                    },
                  ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Obx(() => _Dots(
                          length: segregationTitles.length,
                          current: segregationPage.value,
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ---------- SECCIÓN 3 ----------
            _SectionTitle(
              icon: Icons.emoji_events_outlined,
              title:
                  'Principales Beneficios al Segregar y Reciclar Residuos Inorgánicos',
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: size.height * 0.45,
              child: Stack(
                children: [
                  PageView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: simplePageController,
                    onPageChanged: (i) => simpleCurrentPage.value = i,
                    itemCount: simpleTitles.length,
                    itemBuilder: (_, index) {
                      return _BenefitCard(
                        title: simpleTitles[index],
                        description: simpleDescriptions[index],
                      );
                    },
                  ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Obx(() => _Dots(
                          length: simpleTitles.length,
                          current: simpleCurrentPage.value,
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}

// ======= Widgets de apoyo estilizados =======

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

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
          child: const Icon(Icons.check, color: _StageCard.kPrimary, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: _StageCard.kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _StageCard.kInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.current});
  final int length;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : const Color.fromRGBO(63, 188, 159, 1), // consistente
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;

  static const kPrimary = InformationScreen.kPrimary;
  static const kPrimary2 = InformationScreen.kPrimary2;
  static const kInk = InformationScreen.kInk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2),
      child: Card(
        elevation: 6,
        shadowColor: kPrimary.withOpacity(.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(imagePath, fit: BoxFit.cover),
                  // Sutil overlay para legibilidad si la foto es muy clara
                  Container(color: Colors.black12.withOpacity(.05)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimary2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegregationCard extends StatelessWidget {
  const _SegregationCard({
    required this.isLast,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final bool isLast;
  final String title;
  final String description;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2),
      child: Card(
        elevation: 6,
        shadowColor: InformationScreen.kPrimary.withOpacity(.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Texto arriba con gradiente verde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    InformationScreen.kPrimary,
                    InformationScreen.kPrimary2
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: isLast
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          "Gestión de Residuos Sólidos",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Los beneficios de una buena gestión y segregación de los residuos desde nuestros hogares son innumerables, y poniendo nuestro granito de arena haremos que esto funcione.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          "Cada pequeño esfuerzo cuenta.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "¡Hagamos de nuestro Tarapoto un lugar más sostenible!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            // Imagen debajo
            Expanded(
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Card(
        color: InformationScreen.kPrimary2,
        elevation: 6,
        shadowColor: InformationScreen.kPrimary.withOpacity(.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    description,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
