import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/services/coin_service.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_dropdown.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Sell extends StatefulWidget {
  const Sell({super.key});

  @override
  State<Sell> createState() => _SellState();
}

class _SellState extends State<Sell> {
  double? walletBalance;
  Map<String, dynamic>? selectedCoin;
  List<Map<String, dynamic>> _coins = [];

  final TextEditingController _amountController = TextEditingController();

  double get enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  double get selectedCoinPrice {
    final price = selectedCoin?['coin']['current_price'];
    return price is String
        ? double.tryParse(price) ?? 0.0
        : price is num
        ? price.toDouble()
        : 0.0;
  }

  double get maxSellable {
    final amount = selectedCoin?['amount'];
    return amount is String
        ? double.tryParse(amount) ?? 0.0
        : amount is num
        ? amount.toDouble()
        : 0.0;
  }

  double get totalValue => enteredAmount * selectedCoinPrice;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([_loadAssets(), _loadWalletBalance()]);
    setState(() => isLoading = false);
  }

  Future<void> _loadAssets() async {
    try {
      final result = await AuthApiService().getMyAssets();
      setState(() => _coins = result);
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت دارایی‌ها',
        isError: true,
      );
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final result = await AuthApiService().getWalletBalance();
      setState(() => walletBalance = result);
    } catch (_) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت موجودی کیف پول',
        isError: true,
      );
    }
  }

  Future<void> _handleSell() async {
    if (selectedCoin == null || enteredAmount <= 0) {
      showCustomSnackBar(
        context: context,
        message: 'لطفاً رمز ارز و مقدار معتبر انتخاب کنید',
        isError: true,
      );
      return;
    }

    if (enteredAmount > maxSellable) {
      showCustomSnackBar(
        context: context,
        message: 'مقدار وارد شده بیشتر از دارایی شماست',
        isError: true,
      );
      return;
    }

    try {
      await CoinService().sellCoin(
        coinSymbol: selectedCoin!['coin']['symbol'],
        amount: enteredAmount,
      );

      showCustomSnackBar(context: context, message: 'فروش با موفقیت انجام شد');

      _amountController.clear();
      setState(() => selectedCoin = null);
      await _fetchData();
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در انجام فروش',
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
                walletBalance != null
                    ? '${walletBalance?.toStringAsFixed(4)} USDT'
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

  Widget _buildAssetDropdown() {
    return CustomDropdownInput<int>(
      labelText: 'انتخاب رمز ارز',
      initialValue: selectedCoin?['id'],
      items:
          _coins.map<DropdownMenuItem<int>>((asset) {
            final id = asset['id'];
            final name = asset['coin']['name'];
            final symbol = asset['coin']['symbol'];

            return DropdownMenuItem<int>(
              value: id,
              child: Text('$name ($symbol)'),
            );
          }).toList(),
      onChanged: (selectedId) {
        setState(() {
          selectedCoin = _coins.firstWhere(
            (asset) => asset['id'] == selectedId,
          );
        });
      },
    );
  }

  Widget _buildAssetInfo() {
    if (selectedCoin == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('مقدار قابل فروش:'), Text('0.0000')],
        ),
      );
    }

    final amount = double.tryParse(selectedCoin!['amount'].toString()) ?? 0.0;
    final symbol = selectedCoin!['coin']['symbol'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('مقدار قابل فروش:'),
          Text('${amount.toStringAsFixed(4)} $symbol'),
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
          Text('ارزش فروش:'),
          Text('${totalValue.toStringAsFixed(4)} USDT'),
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
          padding: const EdgeInsets.only(top: 16),
          child: Text('فروش', style: appTextTheme.titleMedium),
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
            _buildAssetDropdown(),
            const SizedBox(height: 16),
            _buildAssetInfo(),
            const SizedBox(height: 16),
            CustomInput(
              keyboardType: TextInputType.number,
              controller: _amountController,
              labelText: 'مقدار فروش',
            ),
            const SizedBox(height: 16),
            _buildPricePreview(),
            const SizedBox(height: 32),
            CustomButton(text: 'تایید فروش', onPressed: _handleSell),
          ],
        ),
      ),
    );
  }
}
