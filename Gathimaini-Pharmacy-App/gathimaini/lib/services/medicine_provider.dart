import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';

class MedicineProvider with ChangeNotifier {
  Database? _db;
  List<Medicine> _medicines = [];
  bool _isLoading = false;

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = 'pharmacy_local.db';

    // Fix: getDatabasesPath() crashes on the Web. We only use it for Mobile/Desktop.
    if (!kIsWeb) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'pharmacy_local.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            rating REAL NOT NULL,
            category TEXT,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('medicines');

      _medicines = maps
          .map(
            (map) => Medicine(
              id: map['id'] as String,
              name: map['name'] as String,
              description: map['description'] as String,
              price: (map['price'] as num).toDouble(),
              rating: (map['rating'] as num).toDouble(),
              category: map['category'] as String?,
              imageUrl: map['imageUrl'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading medicines: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Always stops the loading spinner!
    }
  }

  Future<void> addMedicine(Medicine medicine) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await database;
      await db.insert('medicines', {
        'id': medicine.id,
        'name': medicine.name,
        'description': medicine.description,
        'price': medicine.price,
        'rating': medicine.rating,
        'category': medicine.category,
        'imageUrl': medicine.imageUrl,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await loadMedicines(); // Refresh data immediately
    } catch (e) {
      debugPrint('Error adding medicine: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await database;
      await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
      await loadMedicines(); // Refresh data immediately
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
