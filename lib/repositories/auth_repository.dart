import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/user.dart';
import 'history_repository.dart';

class AuthRepository {
  final historyRepo = HistoryRepository();

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    if (id == null) return null;

    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // ✅ Login (email normalisé)
  Future<int?> login(String email, String password) async {
    final db = await AppDatabase.instance.database;

    final emailNorm = email.trim().toLowerCase();
    final passNorm = password.trim();

    final rows = await db.query(
      'users',
      where: 'email = ? AND passwordHash = ?',
      whereArgs: [emailNorm, passNorm],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final userId = rows.first['id'] as int;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);

    await historyRepo.addEvent(userId: userId, type: 'Auth', message: 'Connexion');
    return userId;
  }

  // ✅ Vérifier si email existe déjà
  Future<bool> emailExists(String email) async {
    final db = await AppDatabase.instance.database;
    final emailNorm = email.trim().toLowerCase();

    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [emailNorm],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  // ✅ Register (avec message clair si email déjà utilisé)
  Future<int> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.instance.database;

    final emailNorm = email.trim().toLowerCase();
    final passNorm = password.trim();
    final nameNorm = fullName.trim();

    // ✅ check avant insert (évite l'erreur SQL)
    final exists = await emailExists(emailNorm);
    if (exists) {
      throw Exception('Cet email est déjà utilisé. Essayez un autre email.');
    }

    try {
      final id = await db.insert('users', {
        'email': emailNorm,
        'passwordHash': passNorm,
        'fullName': nameNorm,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // ✅ Ne connecte pas automatiquement (comme tu veux: "connectez-vous")
      await historyRepo.addEvent(userId: id, type: 'Auth', message: 'Inscription');
      return id;
    } on DatabaseException catch (e) {
      // ✅ si jamais ça arrive quand même (race condition, etc.)
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') && msg.contains('users.email')) {
        throw Exception('Cet email est déjà utilisé. Essayez un autre email.');
      }
      throw Exception('Erreur base de données: $e');
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) throw Exception('Utilisateur non connecté');

    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      {'email': newEmail.trim().toLowerCase()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    await historyRepo.addEvent(userId: userId, type: 'Paramètres', message: 'Email modifié');
  }

  Future<void> updatePassword(String newPasswordPlain) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) throw Exception('Utilisateur non connecté');

    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      {'passwordHash': newPasswordPlain.trim()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    await historyRepo.addEvent(userId: userId, type: 'Paramètres', message: 'Mot de passe modifié');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    await prefs.remove('userId');

    if (userId != null) {
      await historyRepo.addEvent(userId: userId, type: 'Auth', message: 'Déconnexion');
    }
  }
}
