import 'package:flutter/material.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/model/student.dart';
import 'package:student_attendance/screens/main_screen.dart';

ValueNotifier<List<Student>> absentStudents = ValueNotifier<List<Student>>([]);

class AbsentStudentsScreen extends StatefulWidget {
  const AbsentStudentsScreen({super.key});

  @override
  State<AbsentStudentsScreen> createState() => _AbsentStudentsScreenState();
}

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  @override
  void initState() {
    Db().getAbsendStudents(sessionDate.value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: absentStudents,
        builder: (context, ind, _) {
          return ListView.builder(
            itemCount: absentStudents.value.length,
            itemBuilder: (context, index) {
              Student student = absentStudents.value[index];
              return ListTile(
                title: Text(student.studentName),
                subtitle: Text('Roll: ${student.rollNumber}, Course: ${student.courseName}'),
              );
            },
          );
        });
  }
}
