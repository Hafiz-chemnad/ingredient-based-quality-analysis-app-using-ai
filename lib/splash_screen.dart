import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isMounted = false;
  double _logoOpacity = 0.0; // For fade-in effect
  double _logoScale = 0.8; // Start smaller for zoom-in effect

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    // Start animation after a small delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isMounted) {
        setState(() {
          _logoOpacity = 1.0;
          _logoScale = 1.2; // Zoom in effect
        });
      }
    });

    // Navigate after delay
    Timer(const Duration(seconds: 5), () {
      if (_isMounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _logoOpacity, // Fade-in effect
                child: AnimatedScale(
                  scale: _logoScale, // Zoom-in effect
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOut, // Smooth transition
                  child: Image.asset(
                    'assets/images/vector-nutrition-logo_809747-141.jpg',
                    width: 400,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Logo Not Found',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 50), // Moves text to bottom
            child: Text(
              "NutriScan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
