import 'package:crypton_frontend/services/auth_api_service.dart';

import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:crypton_frontend/widgets/custom_modal.dart';

import 'package:crypton_frontend/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminSendMessage extends StatefulWidget {
  const AdminSendMessage({super.key});

  @override
  State<AdminSendMessage> createState() => AdminSendMessageState();
}

class AdminSendMessageState extends State<AdminSendMessage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> announcements = [];
  bool isLoading = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final data = await AuthApiService().getAnnouncements();
      setState(() {
        announcements = data;
      });
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) return;

    try {
      await AuthApiService().createAnnouncement(title: title, message: message);
      showCustomSnackBar(
        context: context,
        message: 'اطلاعیه با موفقیت ارسال شد',
      );
      _titleController.clear();
      _messageController.clear();
      _loadAnnouncements();
    } catch (e) {
      showCustomSnackBar(context: context, message: 'خطا در ارسال اطلاعیه: $e');
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    final confirmed = await showCustomBottomModal<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('حذف اطلاعیه', style: appTextTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            'آیا از حذف این اطلاعیه مطمئن هستید؟',
            style: appTextTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () => Navigator.pop(context, false),
                  text: 'خیر',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: CustomButton(
                  onPressed: () => Navigator.pop(context, true),
                  text: 'بله',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthApiService().deleteAnnouncement(id);
        _loadAnnouncements();
      } catch (e) {
        showCustomSnackBar(context: context, message: 'خطا در حذف اطلاعیه: $e');
      }
    }
  }

  Future<void> _editAnnouncement(Map<String, dynamic> ann) async {
    _titleController.text = ann['title'] ?? '';
    _messageController.text = ann['message'] ?? '';

    final edited = await showCustomBottomModal<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ویرایش اطلاعیه', style: appTextTheme.titleMedium),
          const SizedBox(height: 24),

          CustomInput(controller: _titleController, labelText: 'عنوان'),
          const SizedBox(height: 16),
          CustomInput(controller: _messageController, labelText: 'متن اطلاعیه'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () => Navigator.pop(context, false),
                  text: 'لغو',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'ذخیره تغییرات',
                  onPressed: () async {
                    final title = _titleController.text.trim();
                    final message = _messageController.text.trim();

                    if (title.isEmpty || message.isEmpty) {
                      showCustomSnackBar(
                        context: context,
                        message: 'لطفاً تمام فیلدها را پر کنید',
                      );
                      return;
                    }

                    try {
                      await AuthApiService().updateAnnouncement(
                        id: ann['id'],
                        title: title,
                        message: message,
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      showCustomSnackBar(
                        context: context,
                        message: 'خطا در ویرایش: $e',
                      );
                      Navigator.pop(context, false);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (edited == true) {
      _titleController.clear();
      _messageController.clear();
      await _loadAnnouncements();

      showCustomSnackBar(
        context: context,
        message: 'اطلاعیه با موفقیت ویرایش شد',
      );
    }
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> ann) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.announcement,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              ann['title'] ?? '',
              style: appTextTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editAnnouncement(ann);
              } else if (value == 'delete') {
                _deleteAnnouncement(ann['id']);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('ویرایش', style: appTextTheme.bodyMedium),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف', style: appTextTheme.bodyMedium),
                  ),
                ],
            icon: const Icon(Icons.more_vert, size: 20),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null) {
      return Center(child: Text('خطا در دریافت اطلاعات: $errorText'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.separated(
        itemCount: announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildAnnouncementCard(announcements[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'ارسال اطلاعیه به کاربران',
            style: appTextTheme.titleMedium,
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomInput(
              controller: _titleController,
              labelText: 'عنوان اطلاعیه',
            ),

            const SizedBox(height: 16),

            CustomInput(
              controller: _messageController,
              labelText: 'متن اطلاعیه',
            ),

            const SizedBox(height: 16),

            CustomButton(text: 'ارسال اطلاعیه', onPressed: _submitAnnouncement),

            const Divider(height: 40, endIndent: 6, indent: 6),

            Expanded(child: _buildAnnouncementList()),
          ],
        ),
      ),
    );
  }
}
