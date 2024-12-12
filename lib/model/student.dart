import 'package:excel/excel.dart';

class Student {
  int? id;
  String studentName;
  int rollNumber;
  String courseName;

  Student({
    this.id,
    required this.studentName,
    required this.rollNumber,
    required this.courseName,
  });

  factory Student.fromExcelRow(List<Data?> row) {
    return Student(
      studentName: row[0]?.value.toString() ?? '', // Assuming name is in the first column
      rollNumber:
          int.tryParse(row[1]?.value.toString() ?? '0') ?? 0, // Assuming id is in the second column
      courseName: row[2]?.value.toString() ?? '', // Assuming course is in the third column
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'student_name': studentName,
      'roll_number': rollNumber,
      'course_name': courseName,
    };

    if (id != null) map['id'] = id as int;

    return map;
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      studentName: map['student_name'] as String,
      rollNumber: map['roll_number'] as int,
      courseName: map['course_name'] as String,
    );
  }
}
