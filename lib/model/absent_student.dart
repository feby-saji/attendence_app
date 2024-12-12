class StudentAttendence {
  String date;
  int studentId;
  bool attendenceStatus;

  StudentAttendence({required this.date, required this.studentId, required this.attendenceStatus});

  Map<String, dynamic> toMap() {
    return {
      'date_time': date,
      'student_id ': studentId,
      'status': attendenceStatus == true ? 0 : 1,
    };
  }

  fromMap(Map<String, dynamic> map) {
    return StudentAttendence(
        date: map['date'],
        studentId: map['studentId'],
        attendenceStatus: map['status'] == 0 ? true : false);
  }
}
