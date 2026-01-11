import 'package:flutter/material.dart';

class OnboardingItem {
  String title;
  String subtitle;
  String description;
  String mainImage; // Imagen principal (Logo o icono grande)
  IconData iconSmall; // Elemento decorativo 1
  IconData iconBlur; // Elemento decorativo 2
  Color lightColor;
  Color darkColor;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.mainImage,
    required this.iconSmall,
    required this.iconBlur,
    required this.lightColor,
    required this.darkColor,
  });
}
