import 'package:flutter/material.dart';

enum DocumentType {
  theory, // Anlatım
  vocabulary, // Wortschatz
  practice, // Pratik
  grammar, // Gramer
  dialogue, // Dialog
  pdfGeneral, // PDF Genel
}

class CourseLevel {
  final String id;
  final String name;
  final String description;
  final Color color;
  final int order;

  const CourseLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.order,
  });
}

class CourseTheme {
  final String id;
  final String levelId;
  final int themeNumber;
  final String title;
  final String subtitle;
  final String? description;
  final List<String> topics;

  const CourseTheme({
    required this.id,
    required this.levelId,
    required this.themeNumber,
    required this.title,
    required this.subtitle,
    this.description,
    this.topics = const [],
  });
}
