import 'package:flutter/material.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/model/student.dart';

ValueNotifier<List<Student>> filteredStudents = ValueNotifier<List<Student>>([]);
DateTimeRange? selectedDateRange;

class AbsentStudentsScreen extends StatefulWidget {
  const AbsentStudentsScreen({super.key});

  @override
  State<AbsentStudentsScreen> createState() => _AbsentStudentsScreenState();
}

enum Choice {
  fullPresent,
  fullAbsent,
  absentStudents,
}

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  Choice? _choice = Choice.absentStudents;

  @override
  void initState() {
    // _fetchFilteredStudents();
    super.initState();
  }

  Future<void> _fetchFilteredStudents() async {
    print('Running _fetchFilteredStudents function');
    if (selectedDateRange == null) {
      DateTime now = DateTime.now();
      selectedDateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    }

    if (_choice == Choice.absentStudents) {
      // Fetch absences from the database
      //  filteredStudents = await Db().fetchAbsences(
      //   selectedDateRange!.start,
      //   selectedDateRange!.end,
      // );
      // print('Fetched absences: ${absences.length}');
      // filteredAbsences.value = absences;
    } else {
      List<Student> students = await Db().fetchAttendance(
        selectedDateRange!,
        _choice!,
      );
      print('Fetched students: ${students.length}');
      filteredStudents.value = students;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1000)),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      selectedDateRange = pickedRange;
      await _fetchFilteredStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown and Date Range Picker
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<Choice>(
                  isExpanded: true,
                  value: _choice,
                  items: Choice.values.map((choice) {
                    return DropdownMenuItem<Choice>(
                      value: choice,
                      child: Text(
                        choice == Choice.fullAbsent
                            ? '100% Absent'
                            : choice == Choice.fullPresent
                                ? '100% Present'
                                : 'Absent Students',
                      ),
                    );
                  }).toList(),
                  onChanged: (selectedChoice) {
                    setState(() {
                      _choice = selectedChoice;
                    });
                    _fetchFilteredStudents();
                  },
                  hint: const Text('Select a filter'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () => _pickDateRange(context),
              ),
            ],
          ),
        ),
        // Display filtered students
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: filteredStudents,
            builder: (context, List<Student> students, _) {
              if (students.isEmpty) {
                return const Center(child: Text('No students found for the selected filter.'));
              }
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  Student student = students[index];
                  return ListTile(
                    title: Text(student.studentName),
                    subtitle: Text('Roll: ${student.rollNumber}, Course: ${student.courseName}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
