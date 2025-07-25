import 'package:crypton_frontend/services/user_service.dart';
import 'package:crypton_frontend/utils/to_persian.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_modal.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final UserService _userService = UserService();

  List<dynamic> _allUsers = [];

  String _searchQuery = '';
  bool _isLoading = false;

  // کش وضعیت لود اولیه
  bool _hasLoadedOnce = false;

  List<dynamic> get _filteredUsers {
    final query = _searchQuery.toLowerCase();
    return _allUsers.where((user) {
      final fullName =
          '${user['name']} ${user['family']} ${user['username']}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    // اگر قبلا یکبار لود شده و نیازی به فورس رفرش نیست، درخواست نزن
    if (_hasLoadedOnce && !forceRefresh) return;

    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(forceRefresh: forceRefresh);
      setState(() {
        _allUsers =
            users
                .where((u) => u['role'] != 'admin' && u['is_superuser'] != true)
                .toList();
        _hasLoadedOnce = true;
      });
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت کاربران: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(int userId, bool isActive) async {
    final success = await _userService.toggleUserStatus(userId, isActive);
    if (success) {
      final index = _allUsers.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        setState(() {
          _allUsers[index]['is_active'] = !isActive;
        });
      }
      showCustomSnackBar(
        context: context,
        message: isActive ? 'کاربر مسدود شد' : 'کاربر فعال شد',
      );
    } else {
      showCustomSnackBar(
        context: context,
        message: 'خطا در تغییر وضعیت کاربر',
        isError: true,
      );
    }
  }

  Future<void> _showUserDetails(int userId) async {
    final user = _allUsers.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => null,
    );

    if (user == null) {
      showCustomSnackBar(
        context: context,
        message: 'کاربر یافت نشد',
        isError: true,
      );
      return;
    }

    final isBlocked = !(user['is_active'] as bool? ?? false);

    showCustomBottomModal(
      context: context,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(user),
            const SizedBox(height: 16),
            _buildUserInfo(user),
            const SizedBox(height: 24),
            CustomButton(
              text: isBlocked ? 'لغو مسدود کردن' : 'مسدود کردن',
              onPressed: () async {
                await _toggleUserStatus(userId, user['is_active']);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(Map user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(right: 12, left: 16, top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Iconsax.user, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${user['name']} ${user['family']}',
                style: appTextTheme.titleLarge,
              ),
            ],
          ),
          Text(
            user['is_active'] ? 'فعال' : 'مسدود',
            style: appTextTheme.bodyMedium?.copyWith(
              color: user['is_active'] ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(Map user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نام کاربری: ${user['username']}',
            style: appTextTheme.bodyMedium,
          ),
          if (user['age'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'سن: ${convertToPersianNumber(user['age'])} سال',
              style: appTextTheme.bodyMedium,
            ),
          ],
          if (user['gender'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'جنسیت: ${user['gender'] == 'male' ? 'مرد' : 'زن'}',
              style: appTextTheme.bodyMedium,
            ),
          ],
          if (user['assets'] is Map<String, dynamic>) ...[
            const SizedBox(height: 12),
            Text('دارایی‌ها:', style: appTextTheme.titleSmall),
            const SizedBox(height: 8),
            ...user['assets'].entries.map(
              (entry) => Row(
                children: [
                  const Icon(Iconsax.coin_1, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: appTextTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(Map user) {
    return GestureDetector(
      onTap: () => _showUserDetails(user['id']),
      child: Container(
        decoration: BoxDecoration(
          color:
              user['is_active']
                  ? Colors.transparent
                  : AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user['is_active'] ? AppColors.primary : AppColors.error,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${user['name']} ${user['family']}',
                style: appTextTheme.bodyMedium,
              ),
            ),
            const Icon(Iconsax.arrow_left_2, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'جستجو کاربر...',
        prefixIcon: const Icon(Iconsax.search_normal_1),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadUsers(forceRefresh: true),
      child: Column(
        children: [
          _buildSearchBox(),
          const SizedBox(height: 16),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? const Center(child: Text('هیچ کاربری یافت نشد'))
                    : ListView.separated(
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              _buildUserCard(_filteredUsers[index]),
                    ),
          ),
        ],
      ),
    );
  }
}
