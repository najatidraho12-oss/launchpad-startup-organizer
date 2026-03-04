import 'package:flutter/material.dart';

class ActionsSection extends StatelessWidget {
  final VoidCallback onAddIdea;
  final VoidCallback onIdeasList;
  final VoidCallback onKanban;
  final VoidCallback onRoadmap;

  const ActionsSection({
    super.key,
    required this.onAddIdea,
    required this.onIdeasList,
    required this.onKanban,
    required this.onRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_outlined, color: Color(0xFF3F51B5), size: 20),
              SizedBox(width: 8),
              Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // CHANGER Wrap à GridView pour mieux contrôler le layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Nouvelle Idée',
                color: const Color(0xFF7B1FA2),
                onTap: onAddIdea,
              ),
              _QuickActionButton(
                icon: Icons.list_alt_outlined,
                label: 'Mes Idées',
                color: const Color(0xFF3F51B5),
                onTap: onIdeasList,
              ),
              _QuickActionButton(
                icon: Icons.view_kanban_outlined,
                label: 'Kanban',
                color: const Color(0xFF1976D2),
                onTap: onKanban,
              ),
              _QuickActionButton(
                icon: Icons.timeline_outlined,
                label: 'Roadmap',
                color: const Color(0xFF0097A7),
                onTap: onRoadmap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}