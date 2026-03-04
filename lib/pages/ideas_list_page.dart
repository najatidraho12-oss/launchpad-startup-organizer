import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../repositories/idea_repository.dart';
import 'idea_details_page.dart';
import 'add_idea_page.dart';

class IdeasListPage extends StatefulWidget {
  const IdeasListPage({super.key});

  @override
  State<IdeasListPage> createState() => _IdeasListPageState();
}

class _IdeasListPageState extends State<IdeasListPage>
    with SingleTickerProviderStateMixin {
  final repo = IdeaRepository();
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // filtres
  final List<String> categories = const [
    'Toutes',
    'Produit',
    'Marketing',
    'Technique',
    'Business'
  ];
  final List<String> priorites = const ['Toutes', 'Haute', 'Moyenne', 'Basse'];

  String selectedCategorie = 'Toutes';
  String selectedPriorite = 'Toutes';

  // tri
  final List<String> sortOptions = const ['Date', 'Priorité', 'Titre'];
  String selectedSort = 'Date';
  bool sortAsc = false;

  // data
  bool loading = true;
  String? error;
  List<Idea> allIdeas = [];
  List<Idea> filteredIdeas = [];

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(applyFiltersAndSort);
    loadIdeas();

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
    searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadIdeas() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final ideas = await repo.getAllIdeas();
      setState(() {
        allIdeas = ideas;
        loading = false;
      });
      applyFiltersAndSort();
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

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

  void applyFiltersAndSort() {
    final q = searchCtrl.text.trim().toLowerCase();

    List<Idea> result = allIdeas.where((idea) {
      final matchSearch = q.isEmpty ||
          idea.titre.toLowerCase().contains(q) ||
          idea.description.toLowerCase().contains(q);

      final matchCat =
          selectedCategorie == 'Toutes' || idea.categorie == selectedCategorie;
      final matchPrio =
          selectedPriorite == 'Toutes' || idea.priorite == selectedPriorite;

      return matchSearch && matchCat && matchPrio;
    }).toList();

    result.sort((a, b) {
      int cmp = 0;
      if (selectedSort == 'Date') {
        cmp = parseDate(a.dateCreation).compareTo(parseDate(b.dateCreation));
      } else if (selectedSort == 'Priorité') {
        cmp = prioRank(a.priorite).compareTo(prioRank(b.priorite));
      } else {
        cmp = a.titre.toLowerCase().compareTo(b.titre.toLowerCase());
      }
      return sortAsc ? cmp : -cmp;
    });

    setState(() {
      filteredIdeas = result;
    });
  }

  void resetFilters() {
    setState(() {
      searchCtrl.clear();
      selectedCategorie = 'Toutes';
      selectedPriorite = 'Toutes';
      selectedSort = 'Date';
      sortAsc = false;
      filteredIdeas = List<Idea>.from(allIdeas);
    });
    applyFiltersAndSort();
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.55)),
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

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
          elevation: 8,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: enabled ? onChanged : null,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.black54),
                  const SizedBox(width: 12),
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ====== UI helpers (badges) ======
  Color chipBg(String type, String value) {
    if (type == 'cat') return Colors.grey.withOpacity(0.15);
    if (type == 'prio') {
      if (value == 'Haute') return Colors.red.withOpacity(0.15);
      if (value == 'Moyenne') return Colors.orange.withOpacity(0.18);
      return Colors.green.withOpacity(0.15);
    }
    if (value == 'Backlog') return Colors.blue.withOpacity(0.15);
    if (value == 'En cours') return Colors.deepPurple.withOpacity(0.15);
    return Colors.teal.withOpacity(0.15);
  }

  Color chipText(String type, String value) {
    if (type == 'cat') return Colors.grey.shade800;
    if (type == 'prio') {
      if (value == 'Haute') return Colors.red.shade800;
      if (value == 'Moyenne') return Colors.orange.shade800;
      return Colors.green.shade800;
    }
    if (value == 'Backlog') return Colors.blue.shade800;
    if (value == 'En cours') return Colors.deepPurple.shade800;
    return Colors.teal.shade800;
  }

  Widget chip(String type, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg(type, label),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipText(type, label).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == 'cat') ...[
            const Icon(Icons.category_outlined, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: chipText(type, label),
            ),
          ),
        ],
      ),
    );
  }

  // ====== actions ======
  Future<void> confirmDelete(Idea idea) async {
    if (idea.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer : "${idea.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await repo.deleteIdea(idea.id!);
      await loadIdeas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFF51CF66),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Idée supprimée avec succès !',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> openDetails(Idea idea) async {
    if (idea.id == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IdeaDetailsPage(ideaId: idea.id!)),
    );

    if (result == true || result == false) {
      await loadIdeas();
    }
  }

  Widget _buildIdeaCard(Idea idea, int index) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.03 * (index + 1)),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Interval(0.1 * index, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        child: GestureDetector(
          onTap: () => openDetails(idea),
          child: _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et actions
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        idea.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Boutons d'action
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Modifier',
                            onPressed: () => openDetails(idea),
                            icon: Icon(Icons.edit_outlined,
                                size: 20, color: Colors.black54),
                          ),
                          IconButton(
                            tooltip: 'Supprimer',
                            onPressed: () => confirmDelete(idea),
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  idea.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 16),

                // Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip('prio', idea.priorite),
                    chip('statut', idea.statut),
                    chip('cat', idea.categorie),
                  ],
                ),

                const SizedBox(height: 12),

                // Date et bouton détails
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Créé le ${DateTime.parse(idea.dateCreation).day}/${DateTime.parse(idea.dateCreation).month}/${DateTime.parse(idea.dateCreation).year}',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Détails',
                            style: TextStyle(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: const Color(0xFF111827),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre section filtres
          const Text(
            'Filtres & Tri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Recherche
          TextFormField(
            controller: searchCtrl,
            decoration: _buildDecoration('Rechercher', Icons.search),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Catégorie et Priorité
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Catégorie',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDropdownField(
                      value: selectedCategorie,
                      items: categories,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedCategorie = v);
                        applyFiltersAndSort();
                      },
                      label: 'Catégorie',
                      icon: Icons.category_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Priorité',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDropdownField(
                      value: selectedPriorite,
                      items: priorites,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedPriorite = v);
                        applyFiltersAndSort();
                      },
                      label: 'Priorité',
                      icon: Icons.priority_high,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tri
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Trier par',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDropdownField(
                      value: selectedSort,
                      items: sortOptions,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedSort = v);
                        applyFiltersAndSort();
                      },
                      label: 'Trier par',
                      icon: Icons.sort,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Ordre',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      border: Border.all(color: Colors.black.withOpacity(0.10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => sortAsc = true);
                            applyFiltersAndSort();
                          },
                          icon: Icon(
                            Icons.arrow_upward,
                            color: sortAsc
                                ? const Color(0xFF3F51B5)
                                : Colors.black54,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => sortAsc = false);
                            applyFiltersAndSort();
                          },
                          icon: Icon(
                            Icons.arrow_downward,
                            color: !sortAsc
                                ? const Color(0xFF3F51B5)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bouton réinitialiser
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: BorderSide(color: Colors.black.withOpacity(0.10)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      // Solution 1: Resize pour éviter le débordement du clavier
      resizeToAvoidBottomInset: true,
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
            bottom: false, // Important pour éviter le débordement en bas
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
                            Icons.lightbulb_outline,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mes Idées',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Retrouvez toutes vos idées en un seul endroit',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final added = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddIdeaPage()),
                            );
                            if (added == true) loadIdeas();
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: loadIdeas,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenu principal avec SingleChildScrollView pour éviter le débordement
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          // Section Filtres
                          _buildFiltersSection(),

                          const SizedBox(height: 20),

                          // Section Résultats
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.list_alt_outlined,
                                    size: 20, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  'Résultats : ${filteredIdeas.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Liste des idées
                          loading
                              ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                              : error != null
                              ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Text(
                              'Erreur: $error',
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          )
                              : filteredIdeas.isEmpty
                              ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.white
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune idée trouvée',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Essayez de modifier vos filtres',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Column(
                            children: List.generate(
                              filteredIdeas.length,
                                  (index) {
                                final idea = filteredIdeas[index];
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(
                                      bottom: 12),
                                  child: _buildIdeaCard(
                                      idea, index),
                                );
                              },
                            ),
                          ),

                          // Espace supplémentaire pour le clavier
                          SizedBox(
                            height: MediaQuery.of(context).viewInsets.bottom > 0
                                ? 100
                                : 20,
                          ),
                        ],
                      ),
                    ),
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