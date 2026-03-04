import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../repositories/idea_repository.dart';
import 'idea_details_page.dart';

class KanbanPage extends StatefulWidget {
  const KanbanPage({super.key});

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage>
    with SingleTickerProviderStateMixin {
  final repo = IdeaRepository();

  bool loading = true;
  String? error;

  List<Idea> backlog = [];
  List<Idea> inProgress = [];
  List<Idea> done = [];

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    loadBoard();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ====== PRIORITÉ : tri (Haute > Moyenne > Basse) ======
  int prioRank(String p) {
    if (p == 'Haute') return 3;
    if (p == 'Moyenne') return 2;
    return 1;
  }

  void sortByPriority(List<Idea> list) {
    list.sort((a, b) => prioRank(b.priorite).compareTo(prioRank(a.priorite)));
  }

  Future<void> loadBoard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final ideas = await repo.getAllIdeas();

      backlog = ideas.where((i) => i.statut == 'Backlog').toList();
      inProgress = ideas.where((i) => i.statut == 'En cours').toList();
      done = ideas.where((i) => i.statut == 'Terminé').toList();

      // ✅ trier par priorité dans chaque colonne
      sortByPriority(backlog);
      sortByPriority(inProgress);
      sortByPriority(done);

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> moveIdea(Idea idea, String newStatus) async {
    if (idea.id == null) return;
    if (idea.statut == newStatus) return;
    await repo.updateFields(idea.id!, statut: newStatus);
    await loadBoard();
  }

  // ====== flèches ↤ / ↦ ======
  String? previousStatus(String current) {
    if (current == 'En cours') return 'Backlog';
    if (current == 'Terminé') return 'En cours';
    return null;
  }

  String? nextStatus(String current) {
    if (current == 'Backlog') return 'En cours';
    if (current == 'En cours') return 'Terminé';
    return null;
  }

  // ===== UI (couleurs, badges, animations) =====
  Color prioColor(String p) {
    if (p == 'Haute') return const Color(0xFFEF4444);
    if (p == 'Moyenne') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Color statusColor(String s) {
    if (s == 'Backlog') return const Color(0xFF3B82F6);
    if (s == 'En cours') return const Color(0xFF8B5CF6);
    return const Color(0xFF059669);
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.82, Color borderColor = Colors.white}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor.withOpacity(0.55), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget badge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ====== Carte draggable + flèches ======
  Widget ideaCard(Idea idea) {
    final pColor = prioColor(idea.priorite);

    return Draggable<Idea>(
      data: idea,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 330,
          child: Opacity(
              opacity: 0.9, child: _ideaCardView(idea, dragging: true)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _ideaCardView(idea)),
      child: _ideaCardView(idea),
    );
  }

  Widget _ideaCardView(Idea idea, {bool dragging = false}) {
    final prev = previousStatus(idea.statut);
    final next = nextStatus(idea.statut);
    final pColor = prioColor(idea.priorite);

    return FadeTransition(
      opacity: _fade,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: _buildGlassCard(
          opacity: 0.92,
          borderColor: pColor, // Bordure selon la priorité
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + bouton détails
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idea.titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.14),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      iconSize: 16,
                      tooltip: 'Détails',
                      icon: const Icon(Icons.open_in_new,
                          color: Colors.black54),
                      onPressed: () async {
                        if (idea.id == null) return;
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IdeaDetailsPage(ideaId: idea.id!)),
                        );
                        if (res == true && mounted) loadBoard();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                idea.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  badge(idea.categorie, Colors.grey.shade700,
                      icon: Icons.category_outlined),
                  badge(idea.priorite, pColor, icon: _getPrioIcon(idea.priorite)),
                ],
              ),

              const SizedBox(height: 12),

              // Flèches et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor(idea.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      idea.statut,
                      style: TextStyle(
                        color: statusColor(idea.statut),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prev == null
                              ? Colors.grey.withOpacity(0.1)
                              : const Color(0xFF111827).withOpacity(0.1),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          iconSize: 16,
                          tooltip: 'Retour',
                          onPressed: prev == null
                              ? null
                              : () => moveIdea(idea, prev),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: prev == null
                                ? Colors.grey
                                : const Color(0xFF111827),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: next == null
                              ? Colors.grey.withOpacity(0.1)
                              : const Color(0xFF111827).withOpacity(0.1),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          iconSize: 16,
                          tooltip: 'Avancer',
                          onPressed: next == null
                              ? null
                              : () => moveIdea(idea, next),
                          icon: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: next == null
                                ? Colors.grey
                                : const Color(0xFF111827),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPrioIcon(String p) {
    if (p == 'Haute') return Icons.whatshot;
    if (p == 'Moyenne') return Icons.bolt;
    return Icons.check_circle;
  }

  // ====== Colonne DragTarget (drop zone) ======
  Widget kanbanColumn({
    required String title,
    required String status,
    required IconData icon,
    required List<Idea> ideas,
  }) {
    return Expanded(
      child: DragTarget<Idea>(
        onWillAccept: (idea) => idea != null && idea.statut != status,
        onAccept: (idea) => moveIdea(idea, status),
        builder: (context, candidateData, rejectedData) {
          final isHover = candidateData.isNotEmpty;
          final columnColor = statusColor(status);

          return FadeTransition(
            opacity: _fade,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isHover
                    ? columnColor.withOpacity(0.08)
                    : Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHover
                      ? columnColor.withOpacity(0.35)
                      : Colors.white.withOpacity(0.55),
                  width: isHover ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de la colonne
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: columnColor.withOpacity(0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: columnColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: columnColor.withOpacity(0.2),
                              ),
                              child: Icon(icon, size: 20, color: columnColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: columnColor,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: columnColor.withOpacity(0.7),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: columnColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${ideas.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: columnColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isHover)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: columnColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: columnColor.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.unfold_more_rounded,
                                color: columnColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Déposer ici',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: columnColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ideas.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: columnColor.withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune idée',
                                  style: TextStyle(
                                    color: columnColor.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.separated(
                            itemCount: ideas.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                ideaCard(ideas[i]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (identique à AddIdeaPage)
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
            top: -90,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),

          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 12 + topPad * 0.2, 18, 12),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Row(
                      children: [
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
                          child: const Icon(
                            Icons.dashboard_outlined,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Tableau Kanban',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Visualisez et gérez vos idées par statut',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.78),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                          ),
                          child: IconButton(
                            onPressed: loadBoard,
                            icon: const Icon(
                              Icons.refresh,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenu principal
                Expanded(
                  child: loading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : error != null
                      ? Center(
                    child: _buildGlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: $error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loadBoard,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                const Color(0xFF111827),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      final board = Row(
                        children: [
                          kanbanColumn(
                            title: 'Backlog',
                            status: 'Backlog',
                            icon: Icons.lightbulb_outline,
                            ideas: backlog,
                          ),
                          kanbanColumn(
                            title: 'En cours',
                            status: 'En cours',
                            icon: Icons.build_outlined,
                            ideas: inProgress,
                          ),
                          kanbanColumn(
                            title: 'Terminé',
                            status: 'Terminé',
                            icon: Icons.done_all,
                            ideas: done,
                          ),
                        ],
                      );

                      if (constraints.maxWidth >= 900) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          child: board,
                        );
                      } else {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          child: SizedBox(
                            width: constraints.maxWidth *
                                (constraints.maxWidth < 600
                                    ? 2.2
                                    : 1.5),
                            child: board,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}