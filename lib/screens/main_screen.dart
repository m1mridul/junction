import 'package:flutter/material.dart';
import 'package:junction/screens/calender_screen.dart';
import 'package:junction/screens/profile_screen.dart';
import 'home_screen.dart';
import 'case_list_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ✅ ক্যালেন্ডারের জন্য GlobalKey
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const CaseListScreen(),
      CalendarScreen(key: _calendarKey), // ✅ key যোগ করা হলো
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          // ✅ ক্যালেন্ডার ট্যাবে ট্যাপ করলে আজকের তারিখে ফিরে যাও
          if (index == 2) {
            _calendarKey.currentState?.resetToToday();
          }
        },
        backgroundColor: const Color(0xFF032836),
        selectedItemColor: const Color(0xFFE5B25D),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'মামলাসমূহ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'ক্যালেন্ডার',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'প্রোফাইল',
          ),
        ],
      ),
    );
  }
}
