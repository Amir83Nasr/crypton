import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:iconsax/iconsax.dart';

class Announcement extends StatefulWidget {
  const Announcement({super.key});

  @override
  State<Announcement> createState() => _AnnouncementState();
}

class _AnnouncementState extends State<Announcement> {
  final AuthApiService _api = AuthApiService();

  bool _isLoading = true;
  String? _errorText;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = await _api.getAnnouncements();
      setState(() => _announcements = data);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('اطلاعیه‌ها', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,

        leading: Padding(
          padding: const EdgeInsets.only(top: 16, right: 16),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_right_1, size: 24),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorText != null
              ? Center(child: Text('خطا: $_errorText'))
              : _announcements.isEmpty
              ? const Center(child: Text('هیچ اطلاعیه‌ای وجود ندارد'))
              : RefreshIndicator(
                onRefresh: _loadAnnouncements,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder:
                      (context, index) =>
                          _buildAnnouncementCard(_announcements[index]),
                ),
              ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> ann) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
      ),
      shadowColor: AppColors.primary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.announcement, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ann['title'] ?? '',
                    style: appTextTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ann['message'] ?? '', style: appTextTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
