import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/idea.dart';
import '../repositories/idea_repository.dart';

class IdeaDetailsPage extends StatefulWidget {
  final int ideaId;

  const IdeaDetailsPage({super.key, required this.ideaId});

  @override
  State<IdeaDetailsPage> createState() => _IdeaDetailsPageState();
}

class _IdeaDetailsPageState extends State<IdeaDetailsPage>
    with SingleTickerProviderStateMixin {
  final repo = IdeaRepository();
  final ImagePicker _picker = ImagePicker();
  late Future<Idea?> future;

  final statuts = const ['Backlog', 'En cours', 'Terminé'];
  final priorites = const ['Haute', 'Moyenne', 'Basse'];
  final categories = const ['Produit', 'Marketing', 'Technique', 'Business'];

  final titreCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // valeurs sélectionnées (édition)
  String? selectedStatut;
  String? selectedPriorite;
  String? selectedCategorie;

  // Gestion de l'image
  File? _imageFile;
  String? _existingImageBase64;
  bool saving = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    future = repo.getIdeaById(widget.ideaId);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    titreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {
      future = repo.getIdeaById(widget.ideaId);
      _imageFile = null;
      _existingImageBase64 = null;
    });
  }

  void fillFormOnce(Idea idea) {
    // Remplir une seule fois
    if (titreCtrl.text.isNotEmpty || descCtrl.text.isNotEmpty) return;

    titreCtrl.text = idea.titre;
    descCtrl.text = idea.description;

    selectedStatut = statuts.contains(idea.statut) ? idea.statut : statuts.first;
    selectedPriorite = priorites.contains(idea.priorite) ? idea.priorite : priorites.first;
    selectedCategorie = categories.contains(idea.categorie) ? idea.categorie : categories.first;

    // Initialiser l'image existante
    if (idea.imageBase64 != null && idea.imageBase64!.isNotEmpty) {
      _existingImageBase64 = idea.imageBase64;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageBase64 = null; // Remplace l'image existante
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la sélection: ${e.toString()}',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF7B1FA2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageBase64 = null;
    });
  }

  Future<void> save(Idea idea) async {
    FocusScope.of(context).unfocus();

    final id = idea.id;
    if (id == null) return;

    final titre = titreCtrl.text.trim();
    final desc = descCtrl.text.trim();

    if (titre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Le titre est obligatoire'),
            ],
          ),
          backgroundColor: const Color(0xFF7B1FA2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('La description est obligatoire'),
            ],
          ),
          backgroundColor: const Color(0xFF7B1FA2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final cat = selectedCategorie ?? categories.first;
    final st = selectedStatut ?? statuts.first;
    final pr = selectedPriorite ?? priorites.first;

    setState(() => saving = true);

    try {
      String? imageBase64;

      if (_imageFile != null) {
        // Nouvelle image sélectionnée
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } else if (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty) {
        // Conserver l'image existante
        imageBase64 = _existingImageBase64;
      }
      // Si les deux sont null, imageBase64 reste null (pas d'image)

      await repo.updateIdeaFull(
        id: id,
        titre: titre,
        description: desc,
        categorie: cat,
        statut: st,
        priorite: pr,
        imageBase64: imageBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
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
                  'Modifications enregistrées avec succès !',
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e}',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF7B1FA2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteIdea(Idea idea) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
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
        Navigator.pop(context, true);
      }
    }
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Image (optionnelle)',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        if (_imageFile != null || (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty))
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withOpacity(0.10)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _imageFile != null
                      ? Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  )
                      : (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty)
                      ? Image.memory(
                    base64Decode(_existingImageBase64!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  )
                      : Container(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Prendre une photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: BorderSide(color: Colors.black.withOpacity(0.10)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choisir une image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: BorderSide(color: Colors.black.withOpacity(0.10)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (_imageFile == null && (_existingImageBase64 == null || _existingImageBase64!.isEmpty))
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Ajoutez une image pour illustrer votre idée',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
      ],
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 12 + topPad * 0.2, 18, 18),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: FutureBuilder<Idea?>(
                    future: future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      if (snap.hasError) {
                        return Column(
                          children: [
                            // Header avec retour
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
                                  child: const Icon(
                                    Icons.error_outline,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            _buildGlassCard(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erreur: ${snap.error}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: const Color(0xFF111827),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        'Retour',
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
                          ],
                        );
                      }

                      final idea = snap.data;
                      if (idea == null) {
                        return Column(
                          children: [
                            // Header avec retour
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
                                  child: const Icon(
                                    Icons.search_off,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            _buildGlassCard(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Idée introuvable',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'L\'idée avec l\'ID ${widget.ideaId} n\'existe pas ou a été supprimée.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: const Color(0xFF111827),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        'Retour à la liste',
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
                          ],
                        );
                      }

                      fillFormOnce(idea);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header avec retour et actions
                          Row(
                            children: [
                              IconButton(
                                onPressed: saving ? null : () => Navigator.of(context).pop(),
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
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                  onPressed: refresh,
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Brand header
                          Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
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
                                  Icons.edit_outlined,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Modifier l\'idée',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Créée le ${DateTime.parse(idea.dateCreation).day}/${DateTime.parse(idea.dateCreation).month}/${DateTime.parse(idea.dateCreation).year}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.white.withOpacity(0.78),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Glass card form
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Titre
                                TextFormField(
                                  controller: titreCtrl,
                                  enabled: !saving,
                                  decoration: _buildDecoration('Titre', Icons.title),
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Description
                                TextFormField(
                                  controller: descCtrl,
                                  enabled: !saving,
                                  maxLines: 4,
                                  decoration: _buildDecoration(
                                    'Description',
                                    Icons.description_outlined,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Section Image
                                _buildImageSection(),

                                const SizedBox(height: 16),

                                // Catégorie
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
                                  value: selectedCategorie ?? categories.first,
                                  items: categories,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => selectedCategorie = v);
                                  },
                                  label: 'Catégorie',
                                  icon: Icons.category_outlined,
                                  enabled: !saving,
                                ),

                                const SizedBox(height: 16),

                                // Statut
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text(
                                    'Statut',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildDropdownField(
                                  value: selectedStatut ?? statuts.first,
                                  items: statuts,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => selectedStatut = v);
                                  },
                                  label: 'Statut',
                                  icon: Icons.flag_outlined,
                                  enabled: !saving,
                                ),

                                const SizedBox(height: 16),

                                // Priorité
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
                                  value: selectedPriorite ?? priorites.first,
                                  items: priorites,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => selectedPriorite = v);
                                  },
                                  label: 'Priorité',
                                  icon: Icons.priority_high,
                                  enabled: !saving,
                                ),

                                const SizedBox(height: 24),

                                // Bouton Enregistrer
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: saving ? null : () => save(idea),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFF111827),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: saving
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      'Enregistrer les modifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Bouton Supprimer
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: saving
                                        ? null
                                        : () => deleteIdea(idea),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF7B1FA2),
                                      side: const BorderSide(color: Color(0xFF7B1FA2)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: const Text(
                                      'Supprimer l\'idée',
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
                        ],
                      );
                    },
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