class AbsentStudent {
  String studentName;
  int rollNumber;
  String courseName;
  String? date;

  AbsentStudent({
    this.date,
    required this.rollNumber,
    required this.courseName,
    required this.studentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'date_time': date,
      'student_name': studentName,
      'roll_number': rollNumber,
      'course_name': courseName,
    };
  }

  AbsentStudent fromMap(Map<String, dynamic> map) {
    return AbsentStudent(
      date: map['date_time'],
      studentName: map['student_name'],
      rollNumber: map['roll_number'],
      courseName: map['course_name'],
    );
  }
}
