import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medicamentos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        dosis TEXT NOT NULL,
        cantidad INTEGER NOT NULL
      )
    ''');

    await db.execute('''
  CREATE TABLE recordatorios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medicamento_id INTEGER,
    fecha_hora TEXT,
    notificacion_id INTEGER, -- 👈 Agrega esta línea
    FOREIGN KEY (medicamento_id) REFERENCES medicamentos(id)
  )
''');

  }

  // Insertar medicamento y devolver su ID
  Future<int> insertMedicamento(Map<String, dynamic> medicamento) async {
  final db = await database;
  return await db.insert('medicamentos', medicamento);
}


  // Insertar recordatorio (requiere ID de medicamento)
  Future<int> insertRecordatorio(Map<String, dynamic> recordatorio) async {
  final db = await database;
  return await db.insert('recordatorios', recordatorio);
}

  // Obtener todos los medicamentos
  Future<List<Map<String, dynamic>>> getMedicamentos() async {
    final db = await database;
    return await db.query('medicamentos');
  }

  // Obtener recordatorios por medicamento
  Future<List<Map<String, dynamic>>> getRecordatorios(int medicamentoId) async {
    final db = await database;
    return await db.query(
      'recordatorios',
      where: 'medicamento_id = ?',
      whereArgs: [medicamentoId],
    );
  }

  // Borrar medicamento y sus recordatorios
  Future<void> deleteMedicamento(int id) async {
    final db = await database;
    await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }



  




Future<int> updateMedicamento(int id, Map<String, dynamic> row) async {
  final db = await database;
  return await db.update(
    'medicamentos',
    row,
    where: 'id = ?',
    whereArgs: [id],
  );
}




}
