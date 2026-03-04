import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'startup_launchpad_v2.db');

    return openDatabase(
      fullPath,
      version: 3, // Augmenté à 3 pour ajouter le champ image
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUsersTable(db);
          await _createHistoryTable(db);
        }
        if (oldVersion < 3) {
          // Ajouter la colonne imageBase64 à la table ideas
          await _addImageColumnToIdeas(db);
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ideas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL,
        description TEXT NOT NULL,
        priorite TEXT NOT NULL,
        categorie TEXT NOT NULL,
        statut TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        imageBase64 TEXT
      )
    ''');

    await _createUsersTable(db);
    await _createHistoryTable(db);
  }

  Future<void> _addImageColumnToIdeas(Database db) async {
    // Vérifier si la colonne existe déjà
    final columns = await db.rawQuery(
      'PRAGMA table_info(ideas)',
    );

    bool hasImageColumn = false;
    for (var column in columns) {
      if (column['name'] == 'imageBase64') {
        hasImageColumn = true;
        break;
      }
    }

    if (!hasImageColumn) {
      await db.execute('''
        ALTER TABLE ideas ADD COLUMN imageBase64 TEXT
      ''');
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        fullName TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }
}