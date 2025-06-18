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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicamentos (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    dosis TEXT NOT NULL,
    cantidad INTEGER NOT NULL,
    fecha_inicio TEXT,
    fecha_fin TEXT
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

    await db.execute('''
  CREATE TABLE registro_tomas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recordatorio_id INTEGER,
    estado TEXT, -- "tomado", "omitido", "pospuesto"
    fecha TEXT, -- fecha en que se registró
    FOREIGN KEY (recordatorio_id) REFERENCES recordatorios(id)
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

  Future<List<Map<String, dynamic>>> getRecordatoriosDeHoy() async {
    final db = await database;
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    // Unir medicamentos y recordatorios, filtrar por fecha de hoy
    return await db.rawQuery(
      '''
  SELECT r.id, r.fecha_hora, r.notificacion_id, m.nombre, m.dosis, m.cantidad
  FROM recordatorios r
  JOIN medicamentos m ON r.medicamento_id = m.id
  WHERE date(r.fecha_hora) = ?
  ORDER BY r.fecha_hora ASC
''',
      [hoyStr],
    );
  }

  Future<void> registrarToma(int recordatorioId, String estado) async {
    final db = await database;
    await db.insert('registro_tomas', {
      'recordatorio_id': recordatorioId,
      'estado': estado,
      'fecha': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> contarPosposiciones(int recordatorioId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM registro_tomas WHERE recordatorio_id = ? AND estado = ?',
      [recordatorioId, 'pospuesto'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }


  Future<Map<String, dynamic>?> getRecordatorioPorId(int id) async {
  final db = await database;
  final result = await db.rawQuery('''
    SELECT r.*, m.nombre, m.dosis, m.cantidad
    FROM recordatorios r
    JOIN medicamentos m ON r.medicamento_id = m.id
    WHERE r.id = ?
  ''', [id]);

  return result.isNotEmpty ? result.first : null;
}

}
