import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../shared/services/update_checker.dart';

/// Tab index → GoRouter path mapping
const _tabPaths = ['/chats', '/stories', '/contacts', '/profile-tab'];

/// Tab icons
const _outlinedIcons = [
  Icons.chat_bubble_outline,
  Icons.circle_outlined,
  Icons.people_outline,
  Icons.person_outline,
];
const _filledIcons = [
  Icons.chat_bubble,
  Icons.circle,
  Icons.people,
  Icons.person,
];
const _tabLabels = ['Chats', 'Stories', 'Contacts', 'Profile'];

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedUpdate) {
        _hasCheckedUpdate = true;
        UpdateChecker.checkOnStartup(context);
      }
    });
  }

  /// Derive the selected tab index from the current GoRouter location.
  int get _currentIndex {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabPaths.indexOf(location);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // The `child` parameter comes from GoRouter and renders the
      // correct screen based on the current route (/chats, /stories, etc.)
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return _buildNavItem(
                  context,
                  index,
                  currentIndex,
                  _outlinedIcons[index],
                  _filledIcons[index],
                  _tabLabels[index],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    int currentIndex,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        // Navigate via GoRouter so the URL stays in sync
        context.go(_tabPaths[index]);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
