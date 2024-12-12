import 'package:flutter/material.dart';

ValueNotifier<int> currentPageIndex = ValueNotifier<int>(0);

class NavigationBarWidget extends StatelessWidget {
  const NavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentPageIndex,
      builder: (BuildContext ctx, int ind, _) {
        return NavigationBar(
          onDestinationSelected: (int index) {
            currentPageIndex.value = index;
          },
          indicatorColor: Colors.amber,
          selectedIndex: currentPageIndex.value,
          destinations: <Widget>[
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/students.png',
                scale: 20,
              ),
              label: 'students',
            ),
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/absent.png',
                scale: 20,
              ),
              label: 'Absent students',
            ),
          ],
        );
      },
    );
  }
}
