import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:student_attendance/db/db.dart';
import 'package:student_attendance/functions/formate_date.dart';
import 'package:student_attendance/screens/absent_students.dart';
import 'package:student_attendance/screens/students_screen.dart';
import 'package:student_attendance/widgets/bottom_nav.dart';

ValueNotifier<DateTime> sessionDate = ValueNotifier<DateTime>(DateTime.now());

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const StudentsScreen(),
    const AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance App'),
        actions: [
          ValueListenableBuilder(
              valueListenable: currentPageIndex,
              builder: (context, value, child) {
                return Visibility(
                    visible: currentPageIndex.value == 0,
                    child: IconButton(
                        onPressed: () => datePciker(context), icon: const Icon(Icons.date_range)));
              })
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: currentPageIndex,
        builder: (BuildContext ctx, int ind, _) {
          return _screens[currentPageIndex.value];
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        var databasesPath = await getDatabasesPath();

        print(databasesPath);
      }),
      bottomNavigationBar: const NavigationBarWidget(),
    );
  }

  Future<void> datePciker(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: sessionDate.value, // Show the current session date
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      sessionDate.value = pickedDate;
      sessionDate.notifyListeners();
      print('Picked date: $pickedDate');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected Date: ${formatDate(sessionDate.value)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
