import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/course_model.dart';

/// Web build: [sqflite] is unavailable; persist courses as JSON in [SharedPreferences].
class CourseDatabase {
  CourseDatabase._();
  static final CourseDatabase instance = CourseDatabase._();

  static const _keyCourses = 'target_final_courses_v1';

  Future<List<CourseModel>> allCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCourses);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((e) {
      final m = Map<String, Object?>.from(e as Map);
      return CourseModel.fromRow(m);
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  Future<void> replaceAll(List<CourseModel> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(courses.map((c) => c.toRow()).toList());
    await prefs.setString(_keyCourses, encoded);
  }

  Future<void> upsert(CourseModel c) async {
    final list = await allCourses();
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      list.add(c);
    }
    await replaceAll(list);
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCourses);
  }
}
