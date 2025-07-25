import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, dynamic>> _allTransactions = [];

  Future<void> _loadTransactions() async {
    try {
      final result = await AuthApiService().getUserTransactions();
      setState(() => _allTransactions = result.toList());
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت تراکنش‌ها',
        isError: true,
      );
      setState(() => _allTransactions = []);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('تاریخچه تراکنش‌ها', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,

        toolbarHeight: 72,
        leading: Padding(
          padding: EdgeInsets.only(top: 16, right: 16),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Iconsax.arrow_right_1, size: 24),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _allTransactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final tx = _allTransactions[index];
            final isBuy = tx['transaction_type'] == 'buy';

            final rawValue = tx['total_value'];
            final value =
                double.tryParse(rawValue.toString())?.toStringAsFixed(4) ??
                '0.0000';

            final rawDate = tx['date'] ?? tx['timestamp'] ?? '';
            DateTime? dateTime;
            try {
              dateTime = DateTime.parse(rawDate);
            } catch (_) {
              dateTime = null;
            }
            final formattedDate =
                dateTime != null
                    ? DateFormat('yyyy/MM/dd').format(dateTime)
                    : 'نامشخص';

            final coinName = tx['coin_name'];
            final coinSymbol = tx['coin_symbol'].toUpperCase();

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      size: 28,
                      isBuy ? Iconsax.trend_up : Iconsax.trend_down,
                      color: isBuy ? Colors.green : Colors.red,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 6,
                    children: [
                      Text('$coinName ($coinSymbol)'),
                      Text('$formattedDate :تاریخ ${isBuy ? 'خرید' : 'فروش'}'),
                      Text('$value :ارزش ${isBuy ? 'خرید' : 'فروش'}'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
