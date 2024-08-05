import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('image_marker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE svg_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        svg_content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertSvg(String svgContent) async {
    final db = await instance.database;
    final data = {
      'svg_content': svgContent,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('svg_data', data);
  }

  Future<List<Map<String, dynamic>>> getSvgList() async {
    final db = await instance.database;
    return await db.query('svg_data', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getSvgById(int id) async {
    final db = await instance.database;
    final results =
        await db.query('svg_data', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateSvg(int id, String svgContent) async {
    final db = await instance.database;
    final data = {
      'svg_content': svgContent,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.update('svg_data', data, where: 'id = ?', whereArgs: [id]);
  }
}
