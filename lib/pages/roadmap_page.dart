import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../repositories/idea_repository.dart';
import 'idea_details_page.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage>
    with SingleTickerProviderStateMixin {
  final repo = IdeaRepository();

  bool loading = true;
  String? error;

  List<Idea> all = [];

  final categories = const ['Produit', 'Marketing', 'Technique', 'Business'];

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

    loadRoadmap();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> loadRoadmap() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final ideas = await repo.getAllIdeas();
      setState(() {
        all = ideas;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // ====== Helpers ======
  int prioRank(String p) {
    if (p == 'Haute') return 3;
    if (p == 'Moyenne') return 2;
    return 1;
  }

  DateTime parseDate(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  // Échéance dynamique
  DateTime dueDate(Idea idea) {
    final base = parseDate(idea.dateCreation);
    if (idea.priorite == 'Haute') return base.add(const Duration(days: 14));
    if (idea.priorite == 'Moyenne') return base.add(const Duration(days: 30));
    return base.add(const Duration(days: 45));
  }

  String fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Color prioColor(String p) {
    if (p == 'Haute') return const Color(0xFFFF6B6B);
    if (p == 'Moyenne') return const Color(0xFFFFA726);
    return const Color(0xFF66BB6A);
  }

  IconData statutIcon(String s) {
    if (s == 'Backlog') return Icons.inbox_outlined;
    if (s == 'En cours') return Icons.play_arrow_outlined;
    return Icons.check_circle_outline;
  }

  Color statutColor(String s) {
    if (s == 'Backlog') return const Color(0xFF7B1FA2);
    if (s == 'En cours') return const Color(0xFF1976D2);
    return const Color(0xFF4CAF50);
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
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
          child: child,
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ====== Sections (dynamique via Kanban) ======
  List<Idea> trimestreObjectives() {
    final list = all
        .where((i) => i.priorite == 'Haute' && i.statut != 'Terminé')
        .toList();

    list.sort((a, b) => dueDate(a).compareTo(dueDate(b)));
    return list.take(6).toList();
  }

  List<Idea> upcomingDeadlines() {
    final list = all.where((i) => i.statut != 'Terminé').toList();
    list.sort((a, b) => dueDate(a).compareTo(dueDate(b)));
    return list.take(10).toList();
  }

  double globalProgress() {
    if (all.isEmpty) return 0;
    final done = all.where((i) => i.statut == 'Terminé').length;
    return done / all.length;
  }

  Map<String, _CatProgress> progressByCategory() {
    final map = <String, _CatProgress>{};

    for (final c in categories) {
      final items = all.where((i) => i.categorie == c).toList();
      final total = items.length;
      final done = items.where((i) => i.statut == 'Terminé').length;

      items.sort((a, b) => prioRank(b.priorite).compareTo(prioRank(a.priorite)));
      final majors = items.take(3).toList();

      map[c] = _CatProgress(
        categorie: c,
        total: total,
        done: done,
        majors: majors,
      );
    }

    return map;
  }

  Future<void> openIdea(Idea idea) async {
    if (idea.id == null) return;
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IdeaDetailsPage(ideaId: idea.id!)),
    );
    if (mounted) await loadRoadmap();
    if (res == true && mounted) await loadRoadmap();
  }

  Widget _buildSectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3F51B5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF3F51B5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _globalProgressCard() {
    final p = globalProgress();
    final pct = (p * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // Fond blanc opaque
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Color(0xFF7B1FA2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Progression globale',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${all.where((i) => i.statut == 'Terminé').length} / ${all.length} idées terminées',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: p,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7B1FA2),
                                Color(0xFF3F51B5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _objectivesCard(List<Idea> objectives) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Objectifs du trimestre', Icons.flag_outlined),
          const SizedBox(height: 20),
          if (objectives.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun objectif "Haute priorité" en attente',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (objectives.isNotEmpty)
            ...objectives.map((i) {
              final d = dueDate(i);
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => openIdea(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statutColor(i.statut).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            statutIcon(i.statut),
                            color: statutColor(i.statut),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i.titre,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChip(
                                    i.priorite,
                                    prioColor(i.priorite),
                                    icon: Icons.whatshot,
                                  ),
                                  _buildChip(
                                    'Cible: ${fmtDate(d)}',
                                    const Color(0xFF6B7280),
                                    icon: Icons.event,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _deadlinesCard(List<Idea> deadlines) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Échéances', Icons.event_available),
          const SizedBox(height: 20),
          if (deadlines.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                  SizedBox(width: 12),
                  Text(
                    'Aucune échéance prochaine',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (deadlines.isNotEmpty)
            ...deadlines.map((i) {
              final d = dueDate(i);
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => openIdea(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i.titre,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChip(
                                    i.statut,
                                    statutColor(i.statut),
                                    icon: statutIcon(i.statut),
                                  ),
                                  _buildChip(
                                    i.priorite,
                                    prioColor(i.priorite),
                                    icon: Icons.priority_high,
                                  ),
                                  _buildChip(
                                    fmtDate(d),
                                    const Color(0xFF6B7280),
                                    icon: Icons.schedule,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _categoryProgressCard(_CatProgress cp) {
    final total = cp.total;
    final done = cp.done;
    final progress = total == 0 ? 0.0 : done / total;
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Color(0xFF3F51B5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cp.categorie,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$done / $total fonctionnalités',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B1FA2),
                      Color(0xFF3F51B5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Fonctionnalités majeures',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          if (cp.majors.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Text(
                  'Aucune idée dans cette catégorie',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          if (cp.majors.isNotEmpty)
            ...cp.majors.map((i) => Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => openIdea(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statutColor(i.statut).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statutIcon(i.statut),
                          color: statutColor(i.statut),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.titre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildChip(
                                  i.statut,
                                  statutColor(i.statut),
                                  icon: statutIcon(i.statut),
                                ),
                                _buildChip(
                                  i.priorite,
                                  prioColor(i.priorite),
                                  icon: Icons.priority_high,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final objectives = trimestreObjectives();
    final deadlines = upcomingDeadlines();
    final catMap = progressByCategory();

    return Scaffold(
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

          // Soft glow blobs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12 + topPad * 0.2, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom AppBar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: loadRoadmap,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.timeline_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Roadmap',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Planification et suivi de vos objectifs',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (loading)
                    _buildGlassCard(
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (error != null)
                    _buildGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Color(0xFFFF6B6B),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: $error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadRoadmap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Progression globale
                        _globalProgressCard(),

                        const SizedBox(height: 20),

                        // Objectifs du trimestre
                        _objectivesCard(objectives),

                        const SizedBox(height: 20),

                        // Échéances
                        _deadlinesCard(deadlines),

                        const SizedBox(height: 20),

                        // Section titre pour les catégories
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildSectionTitle(
                            'Fonctionnalités majeures par catégorie',
                            Icons.category,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Cartes de catégories
                        ...categories.map((c) => _categoryProgressCard(catMap[c]!)),
                      ],
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatProgress {
  final String categorie;
  final int total;
  final int done;
  final List<Idea> majors;

  _CatProgress({
    required this.categorie,
    required this.total,
    required this.done,
    required this.majors,
  });
}