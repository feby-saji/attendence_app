import 'package:flutter/material.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/functions/excel_to_student.dart';
import 'package:student_attendance/functions/import_excel.dart';
import 'package:student_attendance/model/student.dart';
import 'package:student_attendance/screens/main_screen.dart';
import 'package:student_attendance/widgets/excel_sheet_student.dart';

ValueNotifier<List<Student>> allStudents = ValueNotifier<List<Student>>([]);

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  void initState() {
    super.initState();

    // Initial load of all students from the database
    _loadStudents();
  }

  // Load students from the database
  _loadStudents() async {
    List<Student> students = await Db().getAllStudents();
    allStudents.value = students; // Update the ValueNotifier with the fetched students
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: allStudents,
      builder: (context, ind, _) {
        if (allStudents.value.isNotEmpty) {
          return const ExcelSheetStudents();
        } else {
          return const ImportStudentsFromExcel();
        }
      },
    );
  }
}

class ImportStudentsFromExcel extends StatefulWidget {
  const ImportStudentsFromExcel({super.key});

  @override
  State<ImportStudentsFromExcel> createState() => _ImportStudentsFromExcelState();
}

class _ImportStudentsFromExcelState extends State<ImportStudentsFromExcel> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () async {
              var result = await importExcelSheet(context);
              if (result != null) {
                await excelSheetToStudent(result); // Convert and save the students to the database
              }
            },
            child: Image.asset(
              'assets/icons/import.png',
              scale: 3,
            ),
          ),
          const Text('Import students from excel sheet'),
        ],
      ),
    );
  }
}
