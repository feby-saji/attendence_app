import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:student_attendance/functions/formate_date.dart';
import 'package:student_attendance/model/absent_student.dart';
import 'package:student_attendance/model/student.dart';

class Db {
  static final _instance = Db._internal();
  factory Db() => _instance;
  Db._internal();

  final _studentsTable = 'Students';
  final _absenceTable = 'Absence';
  Database? _db;

  Future<void> init() async {
    print('Initializing Database');
    _db = await openDatabase('my_db.db', version: 1, onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE $_studentsTable (id INTEGER PRIMARY KEY, student_name TEXT, roll_number INTEGER, course_name TEXT)',
      );
      await db.execute(
        'CREATE TABLE $_absenceTable (date_time TEXT, student_id INTEGER, FOREIGN KEY (student_id) REFERENCES $_studentsTable(id))',
      );
    });
  }

  // Check if the Students table is empty
  Future<bool> isStudentsTableEmpty() async {
    _db ?? await init();
    int? count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM $_studentsTable'));
    return count == 0;
  }

  // Add student to the Students table
  Future<int> saveStudent(Student student) async {
    _db ?? await init();
    print('Saving student data');
    return await _db!.insert(
      _studentsTable,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Add a student as absent in the Absence table
  Future<void> markAbsent(int studentId, DateTime date) async {
    _db ?? await init();
    String formattedDate = formatDate(date);

    await _db!.insert(
      _absenceTable,
      {'date_time': formattedDate, 'student_id': studentId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    print('Marked absent: Student ID $studentId on $formattedDate');
  }

  // Remove a student from the Absence table to mark as present
  Future<void> markPresent(int studentId, DateTime date) async {
    _db ?? await init();
    String formattedDate = formatDate(date);

    await _db!.delete(
      _absenceTable,
      where: 'student_id = ? AND date_time = ?',
      whereArgs: [studentId, formattedDate],
    );
    print('Marked present: Student ID $studentId on $formattedDate');
  }

  // Check if a student is absent on a specific date
  Future<bool> isStudentAbsent(int studentId, DateTime date) async {
    _db ?? await init();
    String formattedDate = formatDate(date);

    final result = await _db!.query(
      _absenceTable,
      where: 'student_id = ? AND date_time = ?',
      whereArgs: [studentId, formattedDate],
    );

    return result.isNotEmpty; // Student is absent if a record exists
  }

  Future<List<AbsentStudent>> fetchAbsentStudents(DateTimeRange dateRange) async {
    _db ?? await init();
    String startDate = formatDate(dateRange.start);
    String endDate = formatDate(dateRange.end);

    final result = await _db!.rawQuery('''
  SELECT s.student_name, s.roll_number, s.course_name, a.date_time AS absent_date, s.id AS student_id
  FROM $_studentsTable s
  INNER JOIN $_absenceTable a ON s.id = a.student_id
  WHERE a.date_time BETWEEN ? AND ?
  ''', [startDate, endDate]);

    return result.map((row) {
      int studentId = row['student_id'] as int? ?? 0; // Default to 0 if null
      String studentName =
          row['student_name'] as String? ?? 'Unknown'; // Default to 'Unknown' if null
      int rollNumber = row['roll_number'] as int? ?? 0; // Default to 0 if null
      String courseName =
          row['course_name'] as String? ?? 'Unknown'; // Default to 'Unknown' if null
      String absentDate = row['absent_date'] as String? ?? ''; // Default to '' if null

      return AbsentStudent(
        id: studentId,
        date: absentDate,
        studentName: studentName,
        rollNumber: rollNumber,
        courseName: courseName,
      );
    }).toList();
  }

  List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<List<AbsentStudent>> fetch100PercentAbsentStudents(DateTimeRange dateRange) async {
    _db ?? await init();

    String startDate = formatDate(dateRange.start);
    String endDate = formatDate(dateRange.end);

    // Generate all the dates in the range
    List<DateTime> datesInRange = getDatesInRange(dateRange.start, dateRange.end);
    int totalDays = datesInRange.length;

    try {
      final result = await _db!.rawQuery('''
  SELECT students.id, students.student_name, students.roll_number, students.course_name, COUNT(absence.date_time) AS absent_count
  FROM students
  LEFT JOIN absence
    ON students.id = absence.student_id 
    AND absence.date_time BETWEEN ? AND ?
  GROUP BY students.id
  HAVING absent_count = ?
''', [startDate, endDate, totalDays]);

      return result.map((row) {
        int studentId = row['id'] as int? ?? 0;
        String studentName = row['student_name'] as String? ?? 'Unknown';
        int rollNumber = row['roll_number'] as int? ?? 0;
        String courseName = row['course_name'] as String? ?? 'Unknown';

        return AbsentStudent(
          id: studentId,
          date: '', // No date associated directly in this query, can be adjusted
          studentName: studentName,
          rollNumber: rollNumber,
          courseName: courseName,
        );
      }).toList();
    } catch (e) {
      print('Error fetching 100% absent students: $e');
      rethrow; // Rethrow the error for higher-level handling
    }
  }

  // Fetch students who are 100% present within a date range
  Future<List<AbsentStudent>> fetch100PercentPresentStudents(DateTimeRange dateRange) async {
    _db ?? await init();
    String startDate = formatDate(dateRange.start);
    String endDate = formatDate(dateRange.end);

    try {
      final result = await _db!.rawQuery('''
      SELECT s.id, s.student_name, s.roll_number, s.course_name, COUNT(a.date_time) as present_count
      FROM $_studentsTable s
      LEFT JOIN $_absenceTable a 
        ON s.id = a.student_id 
        AND a.date_time BETWEEN ? AND ?
      GROUP BY s.id
      HAVING present_count = 0  -- No absences in this date range, meaning 100% present
    ''', [startDate, endDate]);

      return result.map((row) {
        // Safely cast and handle potential null values
        int studentId = row['id'] as int? ?? 0; // Default to 0 if null
        String studentName =
            row['student_name'] as String? ?? 'Unknown'; // Default to 'Unknown' if null
        int rollNumber = row['roll_number'] as int? ?? 0; // Default to 0 if null
        String courseName =
            row['course_name'] as String? ?? 'Unknown'; // Default to 'Unknown' if null

        return AbsentStudent(
          id: studentId,
          date: '',
          studentName: studentName,
          rollNumber: rollNumber,
          courseName: courseName,
        );
      }).toList();
    } catch (e) {
      print('Error fetching 100% present students: $e');
      rethrow; // Rethrow the error for higher-level handling
    }
  }

  // Add this method in your Db class
  Future<List<Student>> getAllStudents() async {
    _db ?? await init();
    final result = await _db!.query(_studentsTable);
    return result.map((row) => Student.fromMap(row)).toList();
  }

  // Debugging helpers: Print students and absences
  Future<void> printStudents() async {
    final students = await _db!.query(_studentsTable);
    for (var student in students) {
      print(student);
    }
  }

  Future<void> printAbsences() async {
    final absences = await _db!.query(_absenceTable);
    for (var absence in absences) {
      print(absence);
    }
  }

  // Delete all records
  Future<void> deleteAllData() async {
    _db ?? await init();
    await _db!.delete(_studentsTable);
    await _db!.delete(_absenceTable);
    print('All data deleted');
  }
}
