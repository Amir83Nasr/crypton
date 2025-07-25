import 'package:crypton_frontend/screens/admin/coins.dart';
import 'package:crypton_frontend/screens/admin/users.dart';

import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedTab = 0;
  final List<String> _tabs = ['مدیریت کاربران', 'مدیریت رمز ارزها'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('پنل ادمین', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 20),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/admin/setting'),
              icon: const Icon(Icons.menu_rounded, size: 24),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final selected = _selectedTab == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _tabs[index],
                            style: appTextTheme.labelMedium?.copyWith(
                              color:
                                  selected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child:
                  _selectedTab == 0
                      ? const AdminUsersTab()
                      : const AdminCoinsTab(),
            ),
          ],
        ),
      ),
    );
  }
}
