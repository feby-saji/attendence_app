import 'package:sqflite/sqflite.dart';
import 'package:student_attendance/functions/formate_date.dart';
import 'package:student_attendance/model/absent_student.dart';
import 'package:student_attendance/model/student.dart';
import 'package:student_attendance/screens/absent_students.dart';
import 'package:student_attendance/screens/main_screen.dart';
import 'package:student_attendance/screens/students_screen.dart';

class Db {
  static final _instance = Db._internal();
  factory Db() => _instance;
  Db._internal();

  final _studentsTable = 'Students';
  final _attendenceTable = 'Absence';
  Database? _db;

  Future<void> init() async {
    print('printing init()');
    _db = await openDatabase('my_db.db', version: 1, onCreate: (Database db, int version) async {
      // is_present :  0 for false, 1 for true
      await db.execute(
        'CREATE TABLE $_studentsTable (id INTEGER PRIMARY KEY, student_name TEXT, roll_number INTEGER, course_name TEXT)',
      );
      await db.execute(
        'CREATE TABLE $_attendenceTable (date_time Text, status INTEGER NOT NULL DEFAULT 0, student_id INTEGER, FOREIGN KEY (student_id) REFERENCES $_studentsTable(id))',
      );
    });
  }

  loadAllStudents() async {
    if (!await checkTableEmpty()) {
      allStudents.value.clear();
      List<Map<String, dynamic>> studentMap = await _db!.query(_studentsTable);

      for (var student in studentMap) {
        allStudents.value.add(Student.fromMap(student));
        allStudents.notifyListeners();
      }
    }
  }

  Future<List<Student>> getData() async {
    if (!await checkTableEmpty()) {
      List<Map<String, dynamic>> studentMap = await _db!.query(_studentsTable);

      return List.generate(studentMap.length, (i) {
        return Student.fromMap(studentMap[i]);
      });
    }
    print('returning empty list  from getData');
    return [];
  }

  Future<int> saveStudent(Student student) async {
    print('saving data');
    int id = await _db!
        .insert(_studentsTable, student.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    print('checkTableEmpty : ${checkTableEmpty()}');
    return id;
  }

  Future<bool> checkTableEmpty() async {
    _db ?? await init();
    int? count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM $_studentsTable'));
    return count == 0;
  }

  // absent students TABLE
  Future<bool> isStudentAbsent(int studentId, DateTime date) async {
    print('sesssion date from isStudentAbsent : ${sessionDate.value}');

    _db ?? await init();
    String formatedDate = formatDate(date);

    final result = await _db!.query(
      _attendenceTable,
      where: 'student_id = ? AND date_time = ?',
      whereArgs: [studentId, formatedDate],
    );
    print(
        'print student from isStudentAbsent : ${result.first['date_time']},  student:  ${result.first['student_id']},');
    print('');
    await printAbsentstudents();
    return result.isNotEmpty;
  }

  Future<void> getAbsendStudents(DateTime date) async {
    _db ?? await init();
    String formatedDate = formatDate(date);

    // SQL query to get absent students for the given date
    final result = await _db?.rawQuery('''
    SELECT $_studentsTable.*
    FROM $_attendenceTable AS absence
    INNER JOIN $_studentsTable ON absence.student_id = $_studentsTable.id
    WHERE absence.date_time = ?
  ''', [formatedDate]);

    if (result != null && result.isNotEmpty) {
      absentStudents.value.clear();
      for (var element in result) {
        absentStudents.value.add(Student.fromMap(element));
      }
      absentStudents.notifyListeners();
    } else {
      absentStudents.value.clear();
      absentStudents.notifyListeners();
    }
  }

  addAbsentStudent(int id, DateTime date) async {
    _db ?? await init();
    String formatedDate = formatDate(date);
    print('print date from addAbsentStudent : $formatedDate');
    print('');
    final result = await _db?.query(_attendenceTable,
        where: 'student_id = ? AND date_time = ?', whereArgs: [id, formatedDate]);
    if (result == null || result.isEmpty) {
      StudentAttendence student =
          StudentAttendence(date: formatedDate, studentId: id, attendenceStatus: false);
      await _db?.insert(
        _attendenceTable,
        student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  removeAbsentStudent(int id, DateTime date) async {
    _db ?? await init();
    String formatedDate = formatDate(date);

    // Delete record where student_id and date_time match
    int? deletedId = await _db?.delete(
      _attendenceTable,
      where: 'student_id = ? AND date_time = ?',
      whereArgs: [id, formatedDate],
    );

    print('Deleted: ${deletedId ?? 'Nothing deleted'}');
  }

// PRINT TABLES
  Future<void> printStudents() async {
    if (_db != null) {
      List<Map<String, dynamic>> students = await _db!.query(_studentsTable);

      // Print each row to the console
      for (var student in students) {
        print(
            'Student ID: ${student['id']}, Name: ${student['name']}, Roll No: ${student['rollNumber']}');
      }
    }
  }

  Future<void> printAbsentstudents() async {
    if (_db != null) {
      List<Map<String, dynamic>> students = await _db!.query(_attendenceTable);

      // Print each row to the console
      for (var student in students) {
        print('date_time ID: ${student['date_time']}, student_id: ${student['student_id']}, ');
      }
    }
  }
}
