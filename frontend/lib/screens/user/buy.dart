import 'package:crypton_frontend/services/coin_service.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_dropdown.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:crypton_frontend/services/auth_api_service.dart';

class Buy extends StatefulWidget {
  const Buy({super.key});

  @override
  State<Buy> createState() => _BuyState();
}

class _BuyState extends State<Buy> {
  double? balance;
  String? selectedSymbol;
  Map<String, dynamic>? selectedCoin;

  final TextEditingController _amountController = TextEditingController();
  List<dynamic> _coins = [];

  double get totalCost {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final price =
        double.tryParse(selectedCoin?['current_price'].toString() ?? '') ?? 0.0;
    return amount * price;
  }

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _loadWalletBalance();
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _loadCoins() async {
    try {
      final result = await CoinService().getCoins();
      setState(() {
        _coins = result;
      });
    } catch (_) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت رمز ارزها',
        isError: true,
      );
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final result = await AuthApiService().getWalletBalance();
      setState(() => balance = result);
    } catch (_) {
      setState(() => balance = 0.0);
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت موجودی',
        isError: true,
      );
    }
  }

  void _resetForm() {
    setState(() {
      selectedSymbol = null;
      selectedCoin = null;
      _amountController.clear();
    });
  }

  void _buyCoin() async {
    final amount = double.tryParse(_amountController.text);
    if (selectedCoin == null || amount == null || amount <= 0) {
      showCustomSnackBar(
        context: context,
        message: 'لطفاً مقدار معتبر و رمز ارز را انتخاب کنید',
        isError: true,
      );
      return;
    }

    if ((balance ?? 0) < totalCost) {
      showCustomSnackBar(
        context: context,
        message: 'موجودی کافی نیست',
        isError: true,
      );
      return;
    }

    try {
      final message = await CoinService().buyCoin(
        coinId: selectedCoin!['id'],
        amount: amount,
      );
      showCustomSnackBar(context: context, message: message!);
      _resetForm();
      await _loadWalletBalance();
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در انجام خرید',
        isError: true,
      );
    }
  }

  Widget _buildWalletCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(
              Iconsax.wallet_1,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 12,
            children: [
              Text('موجودی کیف پول', style: appTextTheme.bodyMedium),

              Text(
                balance != null
                    ? '${balance?.toStringAsFixed(4)} USDT'
                    : '-- USDT',
                style: appTextTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('هزینه خرید:'),
          Text('${totalCost.toStringAsFixed(4)} USDT'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('خرید رمز ارز', style: appTextTheme.titleMedium),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(),
            const SizedBox(height: 32),

            CustomDropdownInput<String>(
              labelText: 'انتخاب رمز ارز',
              items:
                  _coins.map<DropdownMenuItem<String>>((coin) {
                    final name = coin['name'] ?? '---';
                    final symbol = coin['symbol'] ?? '---';
                    return DropdownMenuItem<String>(
                      value: symbol,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$name ($symbol)',
                            style: appTextTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              initialValue: selectedSymbol,
              onChanged: (value) {
                if (value == null) return;

                final coin = _coins.firstWhere(
                  (c) => c['symbol'] == value,
                  orElse: () => {},
                );

                setState(() {
                  selectedSymbol = value;
                  selectedCoin = coin;
                });
              },
            ),

            const SizedBox(height: 24),

            CustomInput(
              keyboardType: TextInputType.number,
              controller: _amountController,
              labelText: 'مقدار',
            ),

            const SizedBox(height: 16),

            _buildPricePreview(),

            const SizedBox(height: 32),

            CustomButton(text: 'خرید رمز ارز', onPressed: _buyCoin),
          ],
        ),
      ),
    );
  }
}
