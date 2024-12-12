import 'package:flutter/material.dart';
import 'package:student_attendance/db/db.dart';
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
    const AbsentStudentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance App'),
        actions: [
          IconButton(onPressed: () => datePciker(context), icon: const Icon(Icons.date_range))
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: currentPageIndex,
        builder: (BuildContext ctx, int ind, _) {
          return _screens[currentPageIndex.value];
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        await Db().getAbsendStudents(sessionDate.value);
      }),
      bottomNavigationBar: const NavigationBarWidget(),
    );
  }

  datePciker(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    pickedDate ??= DateTime.now();

    sessionDate.value = pickedDate;
    sessionDate.notifyListeners();
  }
}
