import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background gradient pro
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFF7B1FA2), // violet
                  Color(0xFF3F51B5), // indigo
                  Color(0xFF1976D2), // bleu
                ],
              ),
            ),
          ),

          // ✅ Glow subtil en haut (effet premium)
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),

          // ✅ Blur léger (glass)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ✅ Logo animé (scale + glassmorphism)
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 98,
                          height: 98,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rocket_launch_outlined,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ Titre (pro)
                      const Text(
                        'Start up\nLaunchpad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'organisez vos idées • roadmap • kanban',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.78),
                          letterSpacing: 0.6,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // ✅ Bouton premium (légère transparence + ombre)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF202124),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Commencer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),



                      const SizedBox(height: 14),

                      // ✅ Dot animé simple
                      _AnimatedDot(controller: _ctrl),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    final pulse = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return Opacity(
          opacity: pulse.value,
          child: Transform.scale(
            scale: pulse.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}