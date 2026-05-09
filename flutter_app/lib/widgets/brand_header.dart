import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('CheckIn',
            style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w700,
                color: Color(0xFF061734),
                height: 1.15)),
        SizedBox(height: 8),
        Text('Dependable daily care',
            style: TextStyle(
                fontSize: 19,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w400,
                height: 1.25)),
      ],
    );
  }
}
