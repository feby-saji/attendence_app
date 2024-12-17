import 'package:flutter/material.dart';
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
    print('Printing init()');
    _db = await openDatabase('my_db.db', version: 1, onCreate: (Database db, int version) async {
      // is_present:  0 for false, 1 for true
      await db.execute(
        'CREATE TABLE $_studentsTable (id INTEGER PRIMARY KEY, student_name TEXT, roll_number INTEGER, course_name TEXT)',
      );
      await db.execute(
        'CREATE TABLE $_attendenceTable (date_time TEXT, status INTEGER NOT NULL DEFAULT 0, student_id INTEGER, FOREIGN KEY (student_id) REFERENCES $_studentsTable(id))',
      );
    });
  }

  // Load all students and notify listeners (if using a listener-based state management)
  Future<void> loadAllStudents() async {
    if (!await checkTableEmpty()) {
      allStudents.value.clear();
      List<Map<String, dynamic>> studentMap = await _db!.query(_studentsTable);

      for (var student in studentMap) {
        allStudents.value.add(Student.fromMap(student));
        allStudents.notifyListeners();
      }
    }
  }

  Future<List<Student>> getAllStudents() async {
    if (await checkTableEmpty()) return [];
    List<Map<String, dynamic>> studentMap = await _db!.query(_studentsTable);
    return studentMap.map((student) => Student.fromMap(student)).toList();
  }

  Future<int> saveStudent(Student student) async {
    print('Saving student data');
    int id = await _db!.insert(
      _studentsTable,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<bool> checkTableEmpty() async {
    _db ?? await init();
    int? count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM $_studentsTable'));
    return count == 0;
  }

// ATTENDENCE table

  //this functino runs daily once(adding all students to DB as present)
  addAllStudentsAsPresent(int studentId, String formattedDate) async {
    _db ?? await init();

    await _db!.transaction((txn) async {
      final result = await txn.query(
        _attendenceTable,
        where: 'student_id = ? AND date_time = ?',
        whereArgs: [studentId, formattedDate],
      );

      if (result.isEmpty) {
        // Add absence if not already present
        StudentAttendence studentAttendance = StudentAttendence(
          date: formattedDate,
          studentId: studentId,
          attendenceStatus: true, // true means present
        );

        await txn.insert(
          _attendenceTable,
          studentAttendance.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('present record added for studentId: $studentId on date: $formattedDate');
      } else {
        print('Attendance already recorded for studentId: $studentId on date: $formattedDate');
      }
    });
  }

  Future<List<Student>> fetchAttendance(DateTimeRange dateRange, Choice choice) async {
    String startDate = formatDate(dateRange.start);
    String endDate = formatDate(dateRange.end);

    print('Running query with startDate: $startDate and endDate: $endDate');

    // Run raw query to fetch student attendance data
    final result = await _db!.rawQuery('''
    SELECT s.student_name, 
           s.roll_number, 
           s.course_name,
           COUNT(CASE WHEN a.status = 1 THEN 1 END) as days_present,
           COUNT(CASE WHEN a.status = 0 THEN 1 END) as days_absent,
           COUNT(*) as total_days
    FROM $_studentsTable s
    INNER JOIN $_attendenceTable a ON s.id = a.student_id
    WHERE a.date_time BETWEEN ? AND ?
    GROUP BY s.student_name, s.roll_number, s.course_name
  ''', [startDate, endDate]);

    print('Query result: ${result.length} rows retrieved.');

    List<Student> filteredStudents = [];

    for (var row in result) {
      String studentName = row['student_name'] as String;
      int rollNumber = row['roll_number'] as int;
      String courseName = row['course_name'] as String;
      int daysPresent = row['days_present'] as int? ?? 0;
      int daysAbsent = row['days_absent'] as int? ?? 0;
      int totalDays = row['total_days'] as int;

      print('Processing student: $studentName, Roll Number: $rollNumber');
      print('Days Present: $daysPresent, Days Absent: $daysAbsent, Total Days: $totalDays');

      if (choice == Choice.fullAbsent) {
        if (daysAbsent == totalDays && totalDays > 0) {
          print('$studentName is absent for all days');
          filteredStudents.add(
              Student(studentName: studentName, rollNumber: rollNumber, courseName: courseName));
        }
      } else {
        if (daysPresent == totalDays && totalDays > 0) {
          print('$studentName is present for all days');
          filteredStudents.add(
              Student(studentName: studentName, rollNumber: rollNumber, courseName: courseName));
        }
      }
    }

    print('Filtered students: ${filteredStudents.length}');
    return filteredStudents;
  }

// TODO
  Future<bool> isStudentAbsent(int studentId, DateTime date) async {
    String formattedDate = formatDate(date);

    final result = await _db!.query(
      _attendenceTable,
      where: 'student_id = ? AND date_time = ?',
      whereArgs: [studentId, formattedDate],
    );
    print('isStudentAbsent : ${result.first['status']} , ${result.first['student_id']}');

    if (result.isNotEmpty) {
      // 'status'  0 = absent, 1 = present
      var status = result.first['status'];
      return status == 0;
    } else {
      // No record means the student was not absent on this date (assumed present)
      return false;
    }
  }

  // Add or update absence as absent for a student on a specific date
  Future<void> markAbsent(int studentId, DateTime date) async {
    _db ?? await init();
    String formattedDate = formatDate(date);

    await _db!.transaction((txn) async {
      final result = await txn.query(
        _attendenceTable,
        where: 'student_id = ? AND date_time = ?',
        whereArgs: [studentId, formattedDate],
      );

      if (result.isEmpty) {
        // Add student as absence since the student desnt exist
        StudentAttendence studentAttendance = StudentAttendence(
          date: formattedDate,
          studentId: studentId,
          attendenceStatus: false, // False means absent
        );

        // Insert attendance record
        await txn.insert(
          _attendenceTable,
          studentAttendance.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('Absent record added for studentId: $studentId on date: $formattedDate');
      } else {
        await txn.update(
          _attendenceTable,
          {'status': 0}, // // 1 for present (true), 0 for absent (false)
          where: 'student_id = ? AND date_time = ?',
          whereArgs: [studentId, formattedDate],
        );
        // print('Attendance already recorded for studentId: $studentId on date: $formattedDate');
      }
    });
  }

  // Add or update absence as present for a student on a specific date
  Future<void> markPresent(int studentId, DateTime date) async {
    _db ?? await init();
    String formattedDate = formatDate(date);

    await _db!.transaction((txn) async {
      final result = await txn.query(
        _attendenceTable,
        where: 'student_id = ? AND date_time = ?',
        whereArgs: [studentId, formattedDate],
      );

      if (result.isEmpty) {
        // Add rpresent student
        StudentAttendence studentAttendance = StudentAttendence(
          date: formattedDate,
          studentId: studentId,
          attendenceStatus: true, //
        );

        await txn.insert(
          _attendenceTable,
          studentAttendance.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('present record added for studentId: $studentId on date: $formattedDate');
      } else {
        await txn.update(
          _attendenceTable,
          {'status': 1}, // 1 for present (true), 0 for absent (false)
          where: 'student_id = ? AND date_time = ?',
          whereArgs: [studentId, formattedDate],
        );
        // print('Attendance already recorded for studentId: $studentId on date: $formattedDate');
      }
    });
  }

  Future<void> deleteAllData() async {
    _db ?? await init();

    // Begin the transaction
    await _db!.transaction((txn) async {
      await txn.delete(
        _attendenceTable, // Table name
      );
      print('All data deleted from $_attendenceTable');
    });
  }

  // Print Students Table
  Future<void> printStudents() async {
    if (_db != null) {
      List<Map<String, dynamic>> students = await _db!.query(_studentsTable);
      for (var student in students) {
        print(
            'Student ID: ${student['id']}, Name: ${student['student_name']}, Roll No: ${student['roll_number']}');
      }
    }
  }

  // Print Absence Table
  Future<void> printAbsentStudents() async {
    if (_db != null) {
      List<Map<String, dynamic>> students = await _db!.query(_attendenceTable);
      for (var student in students) {
        print(
            'Date: ${student['date_time']}, Student ID: ${student['student_id']}, Status: ${student['status']}');
      }
    }
  }
}
