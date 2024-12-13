import 'package:flutter/material.dart';
import 'package:student_attendance/db/db.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsentStatus();
    });

    // Add a listener to sessionDate to reload students when the date changes
    sessionDate.addListener(_onSessionDateChange);
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    sessionDate.removeListener(_onSessionDateChange);
    super.dispose();
  }

  // Listener to reload students when sessionDate changes
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

      List<bool> updatedAbsentList = List<bool>.filled(allStudents.value.length, false);

      await Future.delayed(const Duration(milliseconds: 500));
      for (int i = 0; i < allStudents.value.length; i++) {
        final student = allStudents.value[i];
        print('Student $i: ${student.studentName}, ID: ${student.id}');

        if (student.id != null) {
          try {
            updatedAbsentList[i] = await Db().isStudentAbsent(student.id!, sessionDate.value);
            // print('Student ID: ${student.id}, Status: ${updatedAbsentList[i]}');
          } catch (e) {
            // print('Error loading status for student ${student.id}: $e');
            updatedAbsentList[i] = false;
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
    if (studentId == null || !mounted || isAbsent.value[index] == absent) return;

    try {
      List<bool> updatedList = List<bool>.from(isAbsent.value);
      updatedList[index] = absent;

      if (absent) {
        await Db().addAbsentStudent(studentId, sessionDate.value);
      } else {
        await Db().removeAbsentStudent(studentId, sessionDate.value);
      }

      if (mounted) {
        if (goToNextStudent) {
          setState(() {
            currentInd = (currentInd + 1) % allStudents.value.length;
          });
        }
        setState(() {
          isAbsent.value = updatedList;
          isAbsent.notifyListeners();
        });
      }
    } catch (e) {
      print('Error marking attendance: $e');
      await _loadAbsentStatus(); // Reload status to ensure data consistency
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
                          value: absentList[index],
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
                    onPressed: allStudents.value.isNotEmpty
                        ? () => markAttendance(
                            false, allStudents.value[currentInd].id, currentInd, true)
                        : null,
                    child: const Text('Present'),
                  ),
                  ElevatedButton(
                    onPressed: allStudents.value.isNotEmpty
                        ? () =>
                            markAttendance(true, allStudents.value[currentInd].id, currentInd, true)
                        : null,
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
