import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import 'home_tab_page.dart';
import 'mine_tab_page.dart';
import 'template_tab_page.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    const pages = <Widget>[
      HomeTabPage(),
      TemplateTabPage(),
      MineTabPage(),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: state.tabIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: NavigationBar(
              height: 72,
              selectedIndex: state.tabIndex,
              onDestinationSelected: (index) => state.setTab(index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded),
                  label: '模板',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
