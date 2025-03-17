import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure you have this import
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/model/student.dart';
import 'package:student_attendance/model/absent_student.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  AttendanceScreenState createState() => AttendanceScreenState();
}

class AttendanceScreenState extends State<AttendanceScreen> {
  DateTimeRange? _selectedDateRange;
  List<Student> _students = [];
  List<AbsentStudent> _absentStudents = [];
  List<AbsentStudent> _100PercentAbsent = [];
  List<AbsentStudent> _100PercentPresent = [];
  bool _isLoading = false;
  String _selectedOutput = 'Absent Students';

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange(); // Set default date range
    _loadStudents();
  }

  // Set a default date range of 1 week
  void _setDefaultDateRange() {
    DateTime now = DateTime.now();
    DateTime start = now.subtract(const Duration(days: 7));
    DateTime end = now;
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
    // Fetch attendance data for the default range
    _fetchAttendance(_selectedDateRange!);
  }

  // Load all students
  _loadStudents() async {
    setState(() {
      _isLoading = true;
    });
    _students = await Db().getAllStudents();
    setState(() {
      _isLoading = false;
    });
  }

  // Handle date range picker
  _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });

      // Fetch attendance for the selected date range
      _fetchAttendance(picked);
    }
  }

  // Fetch attendance based on date range
  _fetchAttendance(DateTimeRange dateRange) async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedOutput == 'Absent Students') {
      _absentStudents = await Db().fetchAbsentStudents(dateRange);
    } else if (_selectedOutput == '100% Absent Students') {
      _100PercentAbsent = await Db().fetch100PercentAbsentStudents(dateRange);
    } else if (_selectedOutput == '100% Present Students') {
      _100PercentPresent = await Db().fetch100Perce4ntPresentStudents(dateRange);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Mark student as present
  _markStudentPresent(int studentId) async {
    if (_selectedDateRange != null) {
      await Db().markPresent(studentId, _selectedDateRange!.start);
      _fetchAttendance(_selectedDateRange!); // Refresh the attendance list
    }
  }

  // Mark student as absent
  _markStudentAbsent(int studentId) async {
    if (_selectedDateRange != null) {
      await Db().markAbsent(studentId, _selectedDateRange!.start);
      _fetchAttendance(_selectedDateRange!); // Refresh the attendance list
    }
  }

  // Format date for display (using intl for a nicer format)
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date); // Day and Month format
  }

  // Format full date range (with 'from' and 'to' labels)
  String _formatDateRange(DateTimeRange range) {
    return '${DateFormat('dd MMM').format(range.start)} to ${DateFormat('dd MMM').format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Date range selection and dropdown in a Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Range Button
                ElevatedButton(
                  onPressed: _pickDateRange,
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select Date Range'
                        : _formatDateRange(_selectedDateRange!),
                    overflow: TextOverflow.ellipsis, // Prevent overflow if the text is too long
                  ),
                ),
                const SizedBox(width: 10), // Spacer between the button and dropdown
                // Dropdown for selecting output
                DropdownButton<String>(
                  value: _selectedOutput,
                  items: [
                    'Absent Students',
                    '100% Absent Students',
                    '100% Present Students',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOutput = value!;
                    });
                    if (_selectedDateRange != null) {
                      _fetchAttendance(_selectedDateRange!);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Attendance list for the selected output
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedDateRange != null &&
                _selectedOutput == 'Absent Students' &&
                _absentStudents.isEmpty)
              const Text('No absent students found for the selected range.')
            else if (_selectedDateRange != null && _selectedOutput == 'Absent Students')
              Expanded(
                child: ListView.builder(
                  itemCount: _absentStudents.length,
                  itemBuilder: (context, index) {
                    final absentStudent = _absentStudents[index];
                    return ListTile(
                      title: Text(absentStudent.studentName),
                      subtitle: Text(
                        'Roll: ${absentStudent.rollNumber}, Course: ${absentStudent.date}',
                      ),
                    );
                  },
                ),
              )
            else if (_selectedDateRange != null && _selectedOutput == '100% Absent Students')
              // Handle "100% Absent Students"
              Expanded(
                child: ListView.builder(
                  itemCount: _100PercentAbsent.isEmpty ? 1 : _100PercentAbsent.length,
                  itemBuilder: (context, index) {
                    if (_100PercentAbsent.isEmpty) {
                      return const Center(
                          child: Text('No 100% absent students found for the selected range.'));
                    }
                    final absentStudent = _100PercentAbsent[index];
                    return ListTile(
                      title: Text(absentStudent.studentName),
                      subtitle: Text(
                        'Roll: ${absentStudent.rollNumber}, Course: ${absentStudent.courseName}\nAbsent on: ${absentStudent.date}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle),
                        onPressed: () => _markStudentPresent(absentStudent.id),
                      ),
                    );
                  },
                ),
              )
            else if (_selectedDateRange != null && _selectedOutput == '100% Present Students')
              // Handle "100% Present Students"
              Expanded(
                child: ListView.builder(
                  itemCount: _100PercentPresent.isEmpty ? 1 : _100PercentPresent.length,
                  itemBuilder: (context, index) {
                    if (_100PercentPresent.isEmpty) {
                      return const Center(
                          child: Text('No 100% present students found for the selected range.'));
                    }
                    final student = _100PercentPresent[index];
                    return ListTile(
                      title: Text(student.studentName),
                      subtitle: Text('Roll: ${student.rollNumber}, Course: ${student.courseName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => _markStudentAbsent(student.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
