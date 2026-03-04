import '../database/app_database.dart';

class ProfileRepository {
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> createUser({
    required String email,
    required String passwordHash,
    required String fullName,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert('users', {
      'email': email,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateEmail(int userId, String newEmail) async {
    final db = await AppDatabase.instance.database;
    return db.update('users', {'email': newEmail}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> updatePassword(int userId, String newPasswordHash) async {
    final db = await AppDatabase.instance.database;
    return db.update('users', {'passwordHash': newPasswordHash}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> addHistory({
    required int userId,
    required String type,
    required String message,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert('history', {
      'userId': userId,
      'type': type,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    final db = await AppDatabase.instance.database;
    return db.query('history', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
  }
}
