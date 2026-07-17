import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_nav_bar.dart';
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
        // Content must scroll *behind* the floating glass pill so its
        // BackdropFilter has something real to blur.
        extendBody: true,
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: _index,
          onSelect: (i) => setState(() => _index = i),
          items: [
            GlassNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: l.tabHome,
            ),
            GlassNavItem(
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_fill_rounded,
              label: l.tabCourses,
            ),
            GlassNavItem(
              icon: Icons.headphones_outlined,
              activeIcon: Icons.headphones_rounded,
              label: l.tabBooks,
            ),
            GlassNavItem(
              icon: Icons.quiz_outlined,
              activeIcon: Icons.quiz_rounded,
              label: l.tabPracticums,
            ),
            GlassNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: l.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}
