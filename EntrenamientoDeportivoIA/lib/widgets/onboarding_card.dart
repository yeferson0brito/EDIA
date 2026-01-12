import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../models/onboarding_item.dart';

class OnboardingCard extends StatelessWidget {
  final OnboardingItem item;
  final double pageOffset;
  final int index;

  const OnboardingCard({
    super.key,
    required this.item,
    required this.pageOffset,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double cardWidth = size.width - 60;
    double cardHeight = size.height * .65;
    
    // --- CÁLCULOS MATEMÁTICOS DEL PARALLAX ---
    double rotate = index - pageOffset;
    double count = 0;
    double page = pageOffset;
    
    // Lógica para separar la parte entera de la fraccionaria, Esto determina cuánto se ha desplazado la página relativa a su índice
    while (page > 1) {
      page--;
      count++;
    }
    
    double animationVal = Curves.easeOutBack.transform(page);
    double animate = 100 * (count + animationVal);
    double columnAnimation = 50 * (count + animationVal);
    
    // Ajuste relativo al índice actual para que cada tarjeta tenga su propio offset
    for (int a = 0; a < index; a++) {
      animate -= 100;
      columnAnimation -= 50;
    }
    // -----------------------------------------

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _buildTopText(),
          _buildBackgroundImage(cardWidth, cardHeight, size),
          _buildAboveCard(cardWidth, cardHeight, size, columnAnimation),
          _buildMainImage(size, rotate),
          _buildBlurIcon(cardWidth, size, animate),
          _buildSmallIcon(size, animate),
        ],
      ),
    );
  }

  Widget _buildTopText() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 20),
          Text(
            item.title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 40, // Ajustado para móviles
                color: item.lightColor),
          ),
          const SizedBox(width: 5),
          Text(
            item.subtitle,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: item.darkColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(double cardWidth, double cardHeight, Size size) {
    return Positioned(
      width: cardWidth,
      height: cardHeight,
      bottom: size.height * .10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            color: item.lightColor.withOpacity(0.3), // Fondo base
          ),
        ),
      ),
    );
  }

  Widget _buildAboveCard(double cardWidth, double cardHeight, Size size, double columnAnimation) {
    return Positioned(
      width: cardWidth,
      height: cardHeight,
      bottom: size.height * .10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
            color: item.darkColor.withOpacity(0.9), // Tarjeta principal oscura
            borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.all(30),
        child: Transform.translate(
          offset: Offset(-columnAnimation, 0), // Movimiento parallax del texto
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'EDIA AI',
                style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage(Size size, double rotate) {
    // Imagen principal (Logo) que rota
    return Positioned(
      bottom: size.height * .10 + 20, // Un poco arriba del borde inferior de la tarjeta
      right: -20, // Salida por la derecha
      child: Transform.rotate(
        angle: -math.pi / 14 * rotate, // Rotación basada en el scroll
        child: Image.asset(
          item.mainImage,
          height: size.height * .35, // Tamaño dinámico
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildBlurIcon(double cardWidth, Size size, double animate) {
    // Elemento decorativo fondo (Parallax rápido)
    return Positioned(
      right: cardWidth / 2 - 60 + animate,
      bottom: size.height * .05,
      child: Icon(item.iconBlur, size: 100, color: item.lightColor.withOpacity(0.4)),
    );
  }

  Widget _buildSmallIcon(Size size, double animate) {
    // Elemento decorativo frente (Parallax medio)
    return Positioned(
      right: -10 + animate,
      top: size.height * .2,
      child: Icon(item.iconSmall, size: 60, color: Colors.white.withOpacity(0.8)),
    );
  }
}
