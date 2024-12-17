class StudentAttendence {
  String date;
  int studentId;
  bool attendenceStatus;

  StudentAttendence({
    required this.date,
    required this.studentId,
    required this.attendenceStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'date_time': date,
      'student_id': studentId, // Removed extra space after student_id
      'status': attendenceStatus ? 1 : 0, // 1 for present (true), 0 for absent (false)
    };
  }

  StudentAttendence fromMap(Map<String, dynamic> map) {
    return StudentAttendence(
      date: map['date_time'],
      studentId: map['student_id'],
      attendenceStatus: map['status'] == 1, // 1 means present (true), 0 means absent (false)
    );
  }
}
