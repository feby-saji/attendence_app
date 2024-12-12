import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/model/student.dart';
import 'package:student_attendance/screens/students_screen.dart';

excelSheetToStudent(FilePickerResult result) async {
  print('//converting  excel sheet to students');

  var bytes = File(result.files.single.path!).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  bool ignoredHeading = false;
  allStudents.value.clear();
  for (var table in excel.tables.keys) {
    var rows = excel.tables[table]?.rows;
    if (rows != null) {
      for (var row in rows) {
        if (ignoredHeading) {
          Student student = Student.fromExcelRow(row);
          int id = await Db().saveStudent(student);
          student.id = id;
          allStudents.value.add(student);
        } else {
          ignoredHeading = true;
          continue;
        }
      }
      allStudents.notifyListeners();
    }
  }
  // print(allStudents.value.length);
  // allStudents.value.addAll(await Db().getData());
  // allStudents.notifyListeners();
  // print(allStudents.value.length);
}
