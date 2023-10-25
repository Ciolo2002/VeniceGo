import 'package:flutter/material.dart';



class MyNavigationBar extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final NavigationDestinationLabelBehavior? labelBehavior;
  final int selectedIndex;
  final void Function(int index) onItemTap;
  final Color? backgroundColor;

  const MyNavigationBar({
    Key? key,
    required this.onItemTap,
    required this.destinations,
    this.selectedIndex = 0,
    this.backgroundColor,
    this.labelBehavior,
  }) : super(key: key);

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
      labelBehavior: widget.labelBehavior,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int tappedIndex) {
        setState(() {
          _selectedIndex = tappedIndex;
        });

        //widget.onItemTap(tappedIndex);
      },
      animationDuration: const Duration(milliseconds: 1500),
      destinations: widget.destinations,
    );
  }
}
