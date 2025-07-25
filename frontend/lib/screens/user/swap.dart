import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/services/coin_service.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_dropdown.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Swap extends StatefulWidget {
  const Swap({super.key});

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> {
  double? walletBalance;
  List<Map<String, dynamic>> _userAssets = [];
  List<Map<String, dynamic>> _allCoins = [];
  Map<String, dynamic>? fromCoin;
  Map<String, dynamic>? toCoin;

  final TextEditingController _amountController = TextEditingController();

  double get enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  bool isLoading = false;

  double get exchangeRate {
    if (fromCoin == null || toCoin == null) return 0.0;

    final fromPrice =
        double.tryParse(fromCoin!['coin']['current_price'].toString()) ?? 0;
    final toPrice = double.tryParse(toCoin!['current_price'].toString()) ?? 1;

    if (fromPrice == 0 || toPrice == 0) return 0.0;
    return fromPrice / toPrice;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final assets = await AuthApiService().getMyAssets();
      final balance = await AuthApiService().getWalletBalance();
      final coins = await CoinService().getCoins();

      setState(() {
        _userAssets = assets;
        walletBalance = balance;
        _allCoins = coins.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت اطلاعات',
        isError: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  double get maxFromAmount {
    if (fromCoin == null) return 0.0;
    return double.tryParse(fromCoin!['amount'].toString()) ?? 0.0;
  }

  double get estimatedToAmount => enteredAmount * exchangeRate;

  Future<void> _handleSwap() async {
    if (fromCoin == null || toCoin == null) {
      showCustomSnackBar(
        context: context,
        message: 'ارز مبدا و مقصد را انتخاب کنید',
        isError: true,
      );
      return;
    }

    final fromSymbol = fromCoin!['coin']['symbol'];
    final toSymbol = toCoin!['symbol'];

    if (fromSymbol == toSymbol) {
      showCustomSnackBar(
        context: context,
        message: 'ارز مبدا و مقصد نباید یکی باشند',
        isError: true,
      );
      return;
    }

    if (enteredAmount <= 0) {
      showCustomSnackBar(
        context: context,
        message: 'مقدار نامعتبر است',
        isError: true,
      );
      return;
    }

    if (enteredAmount > maxFromAmount) {
      showCustomSnackBar(
        context: context,
        message: 'مقدار بیش از دارایی شماست',
        isError: true,
      );
      return;
    }

    try {
      await CoinService().swapCoin(
        fromSymbol: fromSymbol,
        toSymbol: toSymbol,
        amount: enteredAmount,
      );

      showCustomSnackBar(
        context: context,
        message: '✅ سواپ با موفقیت انجام شد',
      );
      _amountController.clear();
      setState(() {
        fromCoin = null;
        toCoin = null;
      });
      await _fetchData();
    } catch (_) {
      showCustomSnackBar(
        context: context,
        message: '❌ خطا در انجام سواپ',
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

  Widget _buildDropdownFrom() {
    return CustomDropdownInput<Map<String, dynamic>>(
      labelText: 'از ارز',
      initialValue: fromCoin,
      items:
          _userAssets.map((coin) {
            final data = coin['coin'];
            return DropdownMenuItem<Map<String, dynamic>>(
              value: coin,
              child: Text('${data['name']} (${data['symbol']})'),
            );
          }).toList(),
      onChanged: (value) => setState(() => fromCoin = value),
    );
  }

  Widget _buildDropdownTo() {
    return CustomDropdownInput<Map<String, dynamic>>(
      labelText: 'به ارز',
      initialValue: toCoin,
      items:
          _allCoins.map((coin) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: coin,
              child: Text('${coin['name']} (${coin['symbol']})'),
            );
          }).toList(),
      onChanged: (value) => setState(() => toCoin = value),
    );
  }

  Widget _buildToInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('مقدار دریافتی:'),
          (toCoin == null || fromCoin == null || _amountController.text.isEmpty)
              ? Text('0.00000000')
              : Text(
                ' ${estimatedToAmount.toStringAsFixed(8)} ${toCoin!['symbol']}',
              ),
        ],
      ),
    );
  }

  Widget _buildFromInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('مقدار داریی:'),
          (fromCoin == null)
              ? Text('0.000000')
              : Text(
                ' ${maxFromAmount.toStringAsFixed(6)} ${fromCoin!['coin']['symbol']}',
              ),
        ],
      ),
    );
  }

  Widget _buildSwapInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('نرخ تبدیل:'),
          (fromCoin == null || toCoin == null)
              ? Text('----')
              : Text(
                '${fromCoin!['coin']['symbol']} = ${exchangeRate.toStringAsFixed(8)} ${toCoin!['symbol']}',
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('سواپ', style: appTextTheme.titleMedium),
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

            _buildDropdownFrom(),
            const SizedBox(height: 16),

            _buildFromInfo(),
            const SizedBox(height: 16),

            _buildDropdownTo(),
            const SizedBox(height: 16),

            _buildSwapInfo(),
            const SizedBox(height: 16),

            CustomInput(
              labelText: 'مقدار',
              keyboardType: TextInputType.number,
              controller: _amountController,
            ),
            const SizedBox(height: 16),

            _buildToInfo(),
            const SizedBox(height: 32),

            CustomButton(text: 'تایید سواپ', onPressed: _handleSwap),
          ],
        ),
      ),
    );
  }
}
