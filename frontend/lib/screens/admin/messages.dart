import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminMessages extends StatefulWidget {
  const AdminMessages({super.key});

  @override
  State<AdminMessages> createState() => _AdminMessagesState();
}

class _AdminMessagesState extends State<AdminMessages> {
  List<Map<String, dynamic>> contactMessages = [];
  bool isLoading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final messages = await AuthApiService().getContactMessages();
      setState(() => contactMessages = messages);
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(
                  '${msg['name']} ${msg['family']}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                if ((msg['stars'] ?? 0) > 0)
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < msg['stars'] ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              msg['message'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        itemCount: contactMessages.length,
        itemBuilder: (ctx, i) => _buildMessageCard(contactMessages[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('صندوق پیام‌ها', style: appTextTheme.titleMedium),
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
        padding: const EdgeInsets.all(16),
        child: _buildMessageList(),
      ),
    );
  }
}
