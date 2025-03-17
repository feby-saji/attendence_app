import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/functions/formate_date.dart';
import 'package:student_attendance/screens/main_screen.dart';
import 'package:student_attendance/screens/students_screen.dart';

class ExcelSheetStudents extends StatefulWidget {
  const ExcelSheetStudents({super.key});

  @override
  State<ExcelSheetStudents> createState() => _ExcelSheetStudentsState();
}

class _ExcelSheetStudentsState extends State<ExcelSheetStudents> {
  int currentInd = 0;
  final ValueNotifier<List<bool>> isAbsent = ValueNotifier<List<bool>>([]);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isAbsent.value = [];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAbsentStatus();
    });

    sessionDate.addListener(_onSessionDateChange);
  }

  @override
  void dispose() {
    sessionDate.removeListener(_onSessionDateChange);
    super.dispose();
  }

  void _onSessionDateChange() async {
    await _loadAbsentStatus();
  }

  Future<void> _loadAbsentStatus() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (allStudents.value.isEmpty) {
        print('No students available in allStudents');
        return;
      }

      print('Total students: ${allStudents.value.length}');

      List<bool> updatedAbsentList =
          List<bool>.filled(allStudents.value.length, true); // Default to present (true)

      await Future.delayed(const Duration(milliseconds: 500));
      for (int i = 0; i < allStudents.value.length; i++) {
        final student = allStudents.value[i];
        print('Student $i: ${student.studentName}, ID: ${student.id}');

        if (student.id != null) {
          try {
            bool isAbsentStatus = await Db().isStudentAbsent(student.id!, sessionDate.value);
            updatedAbsentList[i] =
                !isAbsentStatus; // If absent is true, set the list to false (present)
          } catch (e) {
            updatedAbsentList[i] = true; // Default to present in case of error
          }
        } else {
          print('Student at index $i has a null ID');
        }
      }

      setState(() {
        isAbsent.value = updatedAbsentList;
      });

      print('Updated isAbsent: ${isAbsent.value}');
    } catch (e) {
      print('Error in _loadAbsentStatus: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> markAttendance(bool absent, int? studentId, int index,
      [bool goToNextStudent = false]) async {
    if (studentId == null || !mounted) return;

    try {
      List<bool> updatedList = List<bool>.from(isAbsent.value);
      updatedList[index] = absent; // Update attendance status (true = present, false = absent)

      if (absent) {
        await Db().markPresent(studentId, sessionDate.value); // Mark present in DB
      } else {
        await Db().markAbsent(studentId, sessionDate.value); // Mark absent in DB
      }

      if (mounted) {
        if (goToNextStudent) {
          setState(() {
            currentInd = (currentInd + 1) % allStudents.value.length;
          });
        }

        setState(() {
          isAbsent.value = updatedList;
        });
      }
    } catch (e) {
      print('Error marking attendance: $e');
      await _loadAbsentStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ValueListenableBuilder(
            valueListenable: allStudents,
            builder: (context, students, _) {
              if (students.isEmpty) {
                return const Center(
                  child: Text('No students available'),
                );
              }

              return ValueListenableBuilder(
                valueListenable: isAbsent,
                builder: (context, absentList, _) {
                  if (absentList.length != students.length) {
                    return const Center(
                      child: Text('Loading student status...'),
                    );
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return ListTile(
                        key: ValueKey(student.id),
                        title: Text(student.studentName),
                        subtitle: Text(student.courseName),
                        trailing: Switch(
                          value: absentList[index], // true = present, false = absent
                          onChanged: (bool value) async {
                            if (student.id != null) {
                              await markAttendance(value, student.id, index);
                            }
                          },
                        ),
                        selectedColor: Colors.blue,
                        selected: currentInd == index,
                      );
                    },
                  );
                },
              );
            },
          ),
        if (!isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () =>
                        markAttendance(true, allStudents.value[currentInd].id, currentInd, true),
                    child: const Text('Present'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        markAttendance(false, allStudents.value[currentInd].id, currentInd, true),
                    child: const Text('Absent'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
