class AbsentStudent {
  final int id;
  final String studentName;
  final int rollNumber;
  final String courseName;
  final String date; // Store the absent date

  AbsentStudent({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.courseName,
    required this.date,
  });

  // Factory constructor to convert map to AbsentStudent
  factory AbsentStudent.fromMap(Map<String, dynamic> map) {
    return AbsentStudent(
      id: map['id'],
      studentName: map['student_name'],
      rollNumber: map['roll_number'],
      courseName: map['course_name'],
      date: map['absent_date'], // Ensure it's correctly parsed
    );
  }
}
