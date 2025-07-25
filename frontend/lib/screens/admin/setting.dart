import 'package:crypton_frontend/services/public_api_service.dart';

import 'package:crypton_frontend/screens/login.dart';

import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_modal.dart';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSetting extends StatefulWidget {
  const AdminSetting({super.key});

  @override
  State<AdminSetting> createState() => _AdminSettingState();
}

class _AdminSettingState extends State<AdminSetting> {
  void _showLogoutConfirmation() {
    showCustomBottomModal(
      context: context,
      child: Column(
        children: [
          Text('آیا مطمئن هستید؟', style: appTextTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            'آیا می‌خواهید از حساب کاربری خارج شوید؟',
            style: appTextTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'خروج',
                  onPressed: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'انصراف',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _logout() {
    PublicApiService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    setState(() {
      if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    await saveThemeMode(mode); // این متد جدید ما هست
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('منو ادمین', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,

        leading: Padding(
          padding: const EdgeInsets.only(top: 24, right: 20),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 24),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('مشاهده نظرات کاربران'),
              leading: const Icon(Icons.reviews),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: () => Navigator.pushNamed(context, '/admin/messages'),
            ),
          ),

          SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('ارسال پیام برای کاربران'),
              leading: const Icon(Icons.message_rounded),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: () => Navigator.pushNamed(context, '/admin/sendmessage'),
            ),
          ),

          SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.brightness_6),
                    title: Text('حالت تم'),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChoiceChip(
                        label: const Text('سیستم'),
                        selected: _themeMode == ThemeMode.system,
                        onSelected: (_) => _saveTheme(ThemeMode.system),
                      ),
                      ChoiceChip(
                        label: const Text('روشن'),
                        selected: _themeMode == ThemeMode.light,
                        onSelected: (_) => _saveTheme(ThemeMode.light),
                      ),
                      ChoiceChip(
                        label: const Text('تاریک'),
                        selected: _themeMode == ThemeMode.dark,
                        onSelected: (_) => _saveTheme(ThemeMode.dark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          CustomButton(
            text: 'خروج از حساب کاربری',
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
    );
  }
}
