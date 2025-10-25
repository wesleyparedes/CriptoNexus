import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  static const String _soundPath = 'sounds/swoosh.mp3';
  static const Color _appBackgroundColor = Color(0xFF07070C);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const String _fixedSlogan = 'Sua jornada crypto começa aqui.';
  late AnimationController _logoController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playStartSound();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));
    _scaleAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));
    _logoController.forward();
    Timer(const Duration(seconds: 3), _checkUserStatus);
  }

  void _playStartSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource(_soundPath));
    player.onPlayerComplete.listen((_) => player.dispose());
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 35),
            FadeTransition(
              opacity: _opacityAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF7AF0FF), Color(0xFF7AF0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'CriptoNexus',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _opacityAnimation,
              child: const Text(
                _fixedSlogan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 80),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                backgroundColor: Colors.white10,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carregando...',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
