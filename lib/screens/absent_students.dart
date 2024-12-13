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

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  bool showAbsent = true;

  @override
  void initState() {
    _fetchFilteredStudents();
    super.initState();
  }

  Future<void> _fetchFilteredStudents() async {
    print('printing running _fetchFilteredStudents function');
    if (selectedDateRange == null) {
      DateTime now = DateTime.now();
      selectedDateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    }
    List<Student> students = await Db().fetchAttendance(
      selectedDateRange!,
      showAbsent,
    );
    print('Fetched students: ${students.length}');
    filteredStudents.value = students;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
        // Chip selection and Date Range Picker
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('100% Absent'),
                selected: showAbsent,
                onSelected: (selected) {
                  if (!showAbsent) {
                    setState(() {
                      showAbsent = true;
                    });
                    _fetchFilteredStudents();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('100% Present'),
                selected: !showAbsent,
                onSelected: (selected) {
                  if (showAbsent) {
                    setState(() {
                      showAbsent = false;
                    });
                    _fetchFilteredStudents();
                  }
                },
              ),
              const Spacer(),
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
