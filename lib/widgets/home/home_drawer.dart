import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  final VoidCallback onGoIdeas;
  final VoidCallback onGoKanban;
  final VoidCallback onGoRoadmap;
  final VoidCallback onGoStats;
  final VoidCallback onGoProfile;

  const HomeDrawer({
    super.key,
    required this.onGoIdeas,
    required this.onGoKanban,
    required this.onGoRoadmap,
    required this.onGoStats,
    required this.onGoProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111827),
      // Supprime la forme arrondie par défaut
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Étire sur toute la largeur
          children: [
            // Header avec dégradé - étiré sur toute la largeur
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B1FA2),
                    Color(0xFF3F51B5),
                    Color(0xFF1976D2),
                  ],
                ),
                // Supprime les coins arrondis
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Startup LaunchPad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion d\'idées & roadmap',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    _DrawerItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Tableau de bord',
                      onTap: () => Navigator.pop(context),
                      isActive: true,
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.list_alt_outlined,
                      label: 'Mes idées',
                      onTap: () {
                        Navigator.pop(context);
                        onGoIdeas();
                      },
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.view_kanban_outlined,
                      label: 'Kanban',
                      onTap: () {
                        Navigator.pop(context);
                        onGoKanban();
                      },
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.timeline_outlined,
                      label: 'Roadmap',
                      onTap: () {
                        Navigator.pop(context);
                        onGoRoadmap();
                      },
                    ),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Statistiques',
                      onTap: () {
                        Navigator.pop(context);
                        onGoStats();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'Profil',
                      onTap: () {
                        Navigator.pop(context);
                        onGoProfile();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Version 1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}