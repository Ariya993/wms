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

    // Animasi logo muter 3D
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Animasi titik loading teks
    _startTextAnimation();
  }

  void _startTextAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return; // Cek ulang mounted setelah delay
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
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
          // Efek rotasi 3D dengan Transform
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                // Menambahkan efek rotasi 3D di sumbu Y
                transform: Matrix4.rotationY(_controller.value * 2 * 3.14159), // Rotasi penuh 360 derajat
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Image.asset(
              'assets/logo.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 16),
          // Teks dengan animasi titik
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



// import 'package:flutter/material.dart';

// class Loading extends StatefulWidget {
//   const Loading({super.key});

//   @override
//   State<Loading> createState() => _LoadingState();
// }

// class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   int _dotCount = 0;

//   @override
//   void initState() {
//     super.initState();

//     // animasi logo muter
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();

//     // animasi titik loading teks
//     _startTextAnimation();
//   }

//   void _startTextAnimation() async {
//     while (mounted) {
//       await Future.delayed(const Duration(milliseconds: 500));
//        if (!mounted) return; // Cek ulang mounted setelah delay
//       setState(() {
//         _dotCount = (_dotCount + 1) % 4;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String dots = '.' * _dotCount;

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           RotationTransition(
//             turns: _controller,
//             child: Image.asset(
//               'assets/logo.png',
//               width: 80,
//               height: 80,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading $dots',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: Color.fromARGB(255, 25, 118, 210),
//                letterSpacing: 0.3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

