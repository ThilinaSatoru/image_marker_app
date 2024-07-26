import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'items.db');
    print('Database file path: $dbPath'); // Print the database file path
    return await openDatabase(
      dbPath,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, imagePath TEXT)",
        );
        await db.execute(
          "CREATE TABLE item_markers(id INTEGER PRIMARY KEY AUTOINCREMENT, itemId INTEGER, x REAL, y REAL, name TEXT, icon TEXT, color TEXT, FOREIGN KEY(itemId) REFERENCES items(id))",
        );
      },
      version: 1,
    );
  }

  Future<int> insertItem(String imagePath) async {
    final db = await database;
    return await db.insert(
      'items',
      {'imagePath': imagePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItem(int id, String imagePath) async {
    final db = await database;
    await db.update(
      'items',
      {'imagePath': imagePath},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> insertMarker(
      int itemId, List<Map<String, dynamic>> markerDetails) async {
    final db = await database;

    // Delete existing markers for this item
    await db.delete('item_markers', where: 'itemId = ?', whereArgs: [itemId]);

    // Insert new markers
    for (var marker in markerDetails) {
      await db.insert(
        'item_markers',
        {
          'itemId': itemId,
          'x': marker['x'],
          'y': marker['y'],
          'name': marker['name'],
          'icon': marker['icon'],
          'color': marker['color'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateMarker(int id, String imagePath,
      List<Map<String, dynamic>> markerDetails) async {
    final db = await database;

    // Update the item record
    await db.update(
      'items',
      {'imagePath': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete existing markers for this item
    await db.delete('item_markers', where: 'itemId = ?', whereArgs: [id]);

    // Insert updated markers
    for (var marker in markerDetails) {
      await db.insert(
        'item_markers',
        {
          'itemId': id,
          'x': marker['x'],
          'y': marker['y'],
          'name': marker['name'],
          'icon': marker['icon'],
          'color': marker['color'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('items');
  }

  Future<Map<String, dynamic>?> getItem(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getMarkers() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT * FROM item_markers
  ''');
  }

  Future<List<Map<String, dynamic>>> getMarkersForItem(int itemId) async {
    final db = await database;
    return await db.query(
      'item_markers',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }
}
