import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/user.dart';
import '../models/idea.dart';
import '../repositories/auth_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/idea_repository.dart';
import '../settings/app_settings.dart';
import '../services/json_transfer_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final auth = AuthRepository();
  final historyRepo = HistoryRepository();
  final ideasRepo = IdeaRepository();
  final transfer = JsonTransferService();

  bool loading = true;
  String? error;

  AppUser? user;
  List<Map<String, dynamic>> events = [];
  List<Idea> ideas = [];

  late TabController tabCtrl;

  @override
  void initState() {
    super.initState();
    tabCtrl = TabController(length: 3, vsync: this);
    loadAll();
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
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Future<void> exportJson() async {
    try {
      final file = await transfer.exportIdeasToJsonFile();

      if (!mounted) return;
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
              Text(
                'Export JSON créé\n${file.path}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Erreur export: $e'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) throw Exception("Fichier invalide");

      final content = await File(path).readAsString();
      final inserted = await transfer.importIdeasFromJsonString(content);

      if (!mounted) return;
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
              Text(
                'Import terminé ✅ ($inserted idées ajoutées)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Erreur import: $e'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final u = await auth.getCurrentUser();
      if (u == null) {
        setState(() {
          loading = false;
          error = 'Session introuvable. Reconnectez-vous.';
        });
        return;
      }

      final h = await historyRepo.getHistory(u.id!);
      final allIdeas = await ideasRepo.getAllIdeas();

      if (!mounted) return;
      setState(() {
        user = u;
        events = h;
        ideas = allIdeas;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String fmtIso(String iso) {
    try {
      final d = DateTime.parse(iso);
      String two(int x) => x.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String notifBacklogHigh() {
    final count = ideas.where((i) => i.statut == 'Backlog' && i.priorite == 'Haute').length;
    return '$count tâche(s) en priorité haute dans le backlog';
  }

  String notifProgress() {
    if (ideas.isEmpty) return 'Ajoutez des idées pour voir la progression';
    final done = ideas.where((i) => i.statut == 'Terminé').length;
    final pct = ((done / ideas.length) * 100).round();
    return 'Vous avez terminé $pct% de vos objectifs';
  }

  Future<void> changeEmail() async {
    if (user == null) return;
    final ctrl = TextEditingController(text: user!.email);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier email'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: 'Nouvel email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await auth.updateEmail(ctrl.text.trim());
      await loadAll();
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
                  'Email modifié avec succès',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> changePassword() async {
    if (user == null) return;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier mot de passe'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: 'Nouveau mot de passe',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (ctrl.text.trim().length < 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Mot de passe trop court'),
                ],
              ),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
        return;
      }

      await auth.updatePassword(ctrl.text.trim());
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
                  'Mot de passe modifié avec succès',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    await auth.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  Widget _buildEventTile(Map<String, dynamic> h) {
    final type = (h['type'] ?? '').toString();
    final msg = (h['message'] ?? '').toString();
    final createdAt = (h['createdAt'] ?? '').toString();

    return Container(
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
              color: const Color(0xFF7B1FA2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              color: Color(0xFF7B1FA2),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmtIso(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaTile(Idea i) {
    return Container(
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
              color: const Color(0xFF3F51B5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
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
                  i.titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Créée: ${fmtIso(i.dateCreation)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: tabCtrl,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7B1FA2),
              Color(0xFF3F51B5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: [
          Tab(
            height: 48,
            iconMargin: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Profil'),
                ],
              ),
            ),
          ),
          Tab(
            height: 48,
            iconMargin: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Historique'),
                ],
              ),
            ),
          ),
          Tab(
            height: 48,
            iconMargin: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final topPad = MediaQuery.of(context).padding.top;

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
            right: -80,
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
            left: -60,
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
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12 + topPad * 0.2, 20, 16),
                  child: Row(
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
                          onPressed: loadAll,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
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
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez votre compte et vos préférences',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTabBar(),
                ),

                const SizedBox(height: 20),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: tabCtrl,
                    children: [
                      // ===== Profil =====
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: loading
                            ? _buildGlassCard(
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
                            : error != null
                            ? _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.1),
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
                                  onPressed: loadAll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFFFF6B6B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(
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
                            : Column(
                          children: [
                            _buildGlassCard(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7B1FA2),
                                          Color(0xFF3F51B5),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user!.fullName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user!.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: changeEmail,
                                          icon: const Icon(
                                            Icons.email_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Email'),
                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                            const Color(0xFF7B1FA2),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(12),
                                            ),
                                            padding: const EdgeInsets
                                                .symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: changePassword,
                                          icon: const Icon(
                                            Icons.lock_outline,
                                            size: 18,
                                          ),
                                          label: const Text(
                                              'Mot de passe'),
                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                            const Color(
                                                0xFF3F51B5),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(12),
                                            ),
                                            padding: const EdgeInsets
                                                .symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Notifications',
                                    Icons.notifications_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                          const Color(0xFFF59E0B)
                                              .withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Color(0xFFF59E0B),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Informations',
                                              style: TextStyle(
                                                fontWeight:
                                                FontWeight.w700,
                                                color: Color(
                                                    0xFF92400E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          notifBacklogHigh(),
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notifProgress(),
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== Historique =====
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Idées récentes',
                                    Icons.lightbulb_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  if (ideas.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Aucune idée',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (ideas.isNotEmpty)
                                    ...ideas.take(10).map(_buildIdeaTile),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Historique des activités',
                                    Icons.history_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  if (events.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Aucun événement',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (events.isNotEmpty)
                                    ...events.take(10).map(_buildEventTile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== Paramètres =====
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildGlassCard(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B1FA2)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.dark_mode_outlined,
                                    color: Color(0xFF7B1FA2),
                                  ),
                                ),
                                title: const Text(
                                  'Mode sombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                value: settings.darkMode,
                                onChanged: (v) => settings.setDarkMode(v),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Taille du texte',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.text_decrease,
                                        color: Color(0xFF6B7280),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: settings.fontScale,
                                          min: 0.85,
                                          max: 1.35,
                                          divisions: 10,
                                          label: settings.fontScale
                                              .toStringAsFixed(2),
                                          onChanged: (v) =>
                                              settings.setFontScale(v),
                                          activeColor: const Color(0xFF3F51B5),
                                          inactiveColor:
                                          const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.text_increase,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                title: const Text(
                                  'Exporter mes idées (JSON)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                subtitle: const Text(
                                  'Créer un fichier pour sauvegarder / partager',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                onTap: exportJson,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.download,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                title: const Text(
                                  'Importer des idées (JSON)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                subtitle: const Text(
                                  'Importer depuis un autre téléphone',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                onTap: importJson,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: Color(0xFFFF6B6B),
                                  ),
                                ),
                                title: const Text(
                                  'Déconnexion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                onTap: logout,
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
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