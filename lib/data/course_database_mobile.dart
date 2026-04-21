import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/course_model.dart';

class CourseDatabase {
  CourseDatabase._();
  static final CourseDatabase instance = CourseDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'target_final.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE courses (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  credits REAL NOT NULL,
  incourse_marks REAL NOT NULL,
  target_grade TEXT,
  predicted_grade TEXT,
  detail_url TEXT,
  semester_label TEXT,
  synced_at INTEGER NOT NULL,
  assessment_rows TEXT
);
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add assessment_rows column for existing installs
          await db.execute(
            'ALTER TABLE courses ADD COLUMN assessment_rows TEXT;',
          );
        }
      },
    );
  }

  Future<List<CourseModel>> allCourses() async {
    final db = await database;
    final rows = await db.query('courses', orderBy: 'code ASC');
    return rows.map(CourseModel.fromRow).toList();
  }

  Future<void> replaceAll(List<CourseModel> courses) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('courses');
      for (final c in courses) {
        await txn.insert('courses', c.toRow());
      }
    });
  }

  Future<void> upsert(CourseModel c) async {
    final db = await database;
    await db.insert(
      'courses',
      c.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('courses');
  }
}
