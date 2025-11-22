import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tabs/home_tab.dart';
import '../checkin/checkin_tab.dart';
import '../checkin/history_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      const HomeTab(),
      const CheckinTab(),
      const HistoryTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFD), Color(0xFFEAF3FB)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.home, color: theme.colorScheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.fact_check_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.fact_check, color: theme.colorScheme.primary),
                label: 'Check-in',
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.history, color: theme.colorScheme.primary),
                label: 'Lịch sử',
              ),
            ],
          ),
        ),
      ),
    );
  }
}