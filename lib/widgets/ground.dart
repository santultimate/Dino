import 'package:flutter/material.dart';

class Ground extends StatelessWidget {
  const Ground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFF8B4513),
        border: Border(
          top: BorderSide(color: Color(0xFF654321), width: 2),
        ),
      ),
    );
  }
}