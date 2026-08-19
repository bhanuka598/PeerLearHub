import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool center;

  const SectionTitle({super.key, required this.title, this.center = true});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }
}
