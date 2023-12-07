import 'package:flutter/material.dart';

class MyNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Color? backgroundColor;
  final void Function(int) onDestinationSelected;

  const MyNavigationBar({
    super.key,
    this.selectedIndex = 0,
    this.backgroundColor,
    required this.onDestinationSelected,
  });

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        animationDuration: const Duration(milliseconds: 1500),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          // NavigationDestination(
          //  icon: Icon(Icons.search),
          //  selectedIcon: Icon(Icons.search),
          //  label: 'Search',
          // ),
          NavigationDestination(
            icon: Icon(Icons.bookmark),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Account',
            // Within the `FirstRoute` widget
          ),
        ]);
  }
}
