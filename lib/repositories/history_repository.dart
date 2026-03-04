import '../database/app_database.dart';

class HistoryRepository {
  Future<void> addEvent({
    required int userId,
    required String type,
    required String message,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('history', {
      'userId': userId,
      'type': type,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }
}
