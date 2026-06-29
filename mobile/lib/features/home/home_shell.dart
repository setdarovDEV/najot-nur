import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../quizzes/quizzes_tab.dart';
import 'audiobooks_tab.dart';
import 'courses_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  DateTime? _lastBackPressed;

  late final List<Widget> _tabs = [
    HomeTab(onChangeTab: (i) => setState(() => _index = i)),
    const CoursesTab(),
    const AudiobooksTab(),
    const QuizzesTab(),
    const ProfileTab(),
  ];

  static const _exitWindow = Duration(seconds: 2);

  void _handleBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < _exitWindow) {
      _lastBackPressed = null;
      SystemNavigator.pop();
      return;
    }
    _lastBackPressed = now;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l.exitConfirmMessage),
          backgroundColor: AppColors.wine,
          behavior: SnackBarBehavior.floating,
          duration: _exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.wine100,
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              height: 68,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded, color: AppColors.wine),
                  label: l.tabHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.play_circle_outline),
                  selectedIcon:
                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.wine),
                  label: l.tabCourses,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.headphones_outlined),
                  selectedIcon:
                      const Icon(Icons.headphones_rounded, color: AppColors.wine),
                  label: l.tabBooks,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.quiz_outlined),
                  selectedIcon:
                      const Icon(Icons.quiz_rounded, color: AppColors.wine),
                  label: l.tabPracticums,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person_rounded, color: AppColors.wine),
                  label: l.tabProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
