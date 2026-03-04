import 'dart:ui';
import 'package:flutter/material.dart';

import '../repositories/idea_repository.dart';
import '../settings/app_settings.dart';

import '../widgets/home/home_drawer.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/ stats_section.dart';
import '../widgets/home/actions_section.dart';
import '../widgets/home/ activity_section.dart';

import 'add_idea_page.dart';
import 'ideas_list_page.dart';
import 'kanban_page.dart';
import 'roadmap_page.dart';
import 'stats_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final repo = IdeaRepository();

  bool loading = true;
  int backlog = 0;
  int encours = 0;
  int termine = 0;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    loadCounts();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> loadCounts() async {
    setState(() => loading = true);
    try {
      final b = await repo.countByStatus('Backlog');
      final e = await repo.countByStatus('En cours');
      final t = await repo.countByStatus('Terminé');

      if (!mounted) return;
      setState(() {
        backlog = b;
        encours = e;
        termine = t;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Erreur: ${e.toString().length > 40 ? '${e.toString().substring(0, 40)}...' : e}'),
            ],
          ),
          backgroundColor: const Color(0xFF7B1FA2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> openAddIdea() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIdeaPage()),
    );
    if (result == true) {
      await loadCounts();
    }
  }

  Future<void> openIdeasList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IdeasListPage()),
    );
    await loadCounts();
  }

  Future<void> openKanban() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KanbanPage()),
    );
    await loadCounts();
  }

  void goRoadmap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoadmapPage()),
    );
  }

  void goStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatsPage()),
    );
  }

  void goProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(settings: widget.settings),
      ),
    );
  }

  void goIdeas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IdeasListPage()),
    );
  }

  void goKanban() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KanbanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(
        onGoIdeas: goIdeas,
        onGoKanban: goKanban,
        onGoRoadmap: goRoadmap,
        onGoStats: goStats,
        onGoProfile: goProfile,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: loadCounts,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFF7B1FA2),
                  Color(0xFF3F51B5),
                  Color(0xFF1976D2),
                ],
              ),
            ),
          ),

          // Soft glow blobs (réduire l'opacité)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Blur effect (réduire l'intensité)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: 16),
                    StatsSection(
                      loading: loading,
                      backlog: backlog,
                      encours: encours,
                      termine: termine,
                    ),
                    const SizedBox(height: 18),
                    ActionsSection(
                      onAddIdea: openAddIdea,
                      onIdeasList: openIdeasList,
                      onKanban: openKanban,
                      onRoadmap: goRoadmap,
                    ),
                    const SizedBox(height: 18),
                    const ActivitySection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: openAddIdea,
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7B1FA2),
                  Color(0xFF3F51B5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}