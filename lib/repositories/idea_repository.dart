import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/idea.dart';
import 'history_repository.dart';

class IdeaRepository {
  final historyRepo = HistoryRepository();

  Future<List<Map<String, dynamic>>> getIdeasHistory() async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'ideas',
      columns: ['titre', 'date_creation'],
      orderBy: 'id DESC',
    );
  }

  Future<int?> _currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> _log(String type, String message) async {
    final userId = await _currentUserId();
    if (userId == null) return;
    await historyRepo.addEvent(userId: userId, type: type, message: message);
  }

  Future<int> insertIdea(Idea idea) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('ideas', idea.toMap());
    await _log('Ajout', 'Nouvelle idée ajoutée : "${idea.titre}"');
    return id;
  }

  Future<List<Idea>> getAllIdeas() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('ideas', orderBy: 'id DESC');
    return rows.map((m) => Idea.fromMap(m)).toList();
  }

  Future<int> deleteIdea(int id) async {
    final idea = await getIdeaById(id);
    final db = await AppDatabase.instance.database;

    final res = await db.delete('ideas', where: 'id = ?', whereArgs: [id]);

    if (idea != null) {
      await _log('Suppression', 'Idée supprimée : "${idea.titre}"');
    }
    return res;
  }

  Future<int> updateIdea(Idea idea) async {
    final db = await AppDatabase.instance.database;

    final res = await db.update(
      'ideas',
      idea.toMap(),
      where: 'id = ?',
      whereArgs: [idea.id],
    );

    await _log('Modification', 'Idée modifiée : "${idea.titre}"');
    return res;
  }

  Future<int> countByStatus(String statut) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ideas WHERE statut = ?',
      [statut],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<List<Idea>> getIdeasByStatus(String statut) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'ideas',
      where: 'statut = ?',
      whereArgs: [statut],
      orderBy: 'id DESC',
    );
    return rows.map((m) => Idea.fromMap(m)).toList();
  }

  Future<void> updateStatus(int id, String newStatus) async {
    final db = await AppDatabase.instance.database;
    final idea = await getIdeaById(id);

    await db.update(
      'ideas',
      {'statut': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (idea != null) {
      await _log('Kanban', 'Statut de "${idea.titre}" -> $newStatus');
    }
  }

  Future<Idea?> getIdeaById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('ideas', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Idea.fromMap(rows.first);
  }

  Future<int> updateFields(
      int id, {
        String? statut,
        String? priorite,
        String? categorie,
      }) async {
    final db = await AppDatabase.instance.database;
    final before = await getIdeaById(id);

    final data = <String, Object?>{};
    if (statut != null) data['statut'] = statut;
    if (priorite != null) data['priorite'] = priorite;
    if (categorie != null) data['categorie'] = categorie;

    final res = await db.update('ideas', data, where: 'id = ?', whereArgs: [id]);

    if (before != null) {
      final changes = <String>[];
      if (statut != null) changes.add('statut=$statut');
      if (priorite != null) changes.add('priorité=$priorite');
      if (categorie != null) changes.add('catégorie=$categorie');
      await _log('Modification', '"${before.titre}" -> ${changes.join(', ')}');
    }

    return res;
  }

  Future<int> updateIdeaFull({
    required int id,
    required String titre,
    required String description,
    required String categorie,
    required String statut,
    required String priorite, String? imageBase64,
  }) async {
    final db = await AppDatabase.instance.database;

    final res = await db.update(
      'ideas',
      {
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'statut': statut,
        'priorite': priorite,
        'imageBase64': imageBase64,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _log('Modification', 'Idée mise à jour : "$titre"');
    return res;
  }
}
