import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();

    // animasi logo muter
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // animasi titik loading teks
    _startTextAnimation();
  }

  void _startTextAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // 0 -> 3
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = '.' * _dotCount;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Image.asset(
              'assets/logo.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading $dots',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color.fromARGB(255, 25, 118, 210),
               letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
