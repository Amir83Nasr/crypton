import 'package:flutter/material.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:iconsax/iconsax.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double? balance;
  bool isAssetsLoading = true;
  List<Map<String, dynamic>> _assets = [];
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadWalletBalance(),
      _loadAssets(),
      _loadTransactions(),
    ]);
  }

  Future<void> _loadWalletBalance() async {
    try {
      final result = await AuthApiService().getWalletBalance();
      setState(() => balance = result);
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت موجودی',
        isError: true,
      );
      setState(() => balance = 0.0);
    }
  }

  Future<void> _loadAssets() async {
    try {
      final result = await AuthApiService().getMyAssets();
      setState(() {
        _assets = result.take(10).toList();
        isAssetsLoading = false;
      });
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت دارایی‌ها',
        isError: true,
      );
      setState(() {
        _assets = [];
        isAssetsLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final result = await AuthApiService().getUserTransactions();
      setState(() => _transactions = result.take(10).toList());
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت تراکنش‌ها',
        isError: true,
      );
      setState(() => _transactions = []);
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'خرید',
            icon: const Icon(Iconsax.activity),
            onPressed: () => Navigator.pushNamed(context, '/user/buy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'سواپ',
            icon: const Icon(Iconsax.activity),
            onPressed: () => Navigator.pushNamed(context, '/user/swap'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'فروش',
            icon: const Icon(Iconsax.activity),
            onPressed: () => Navigator.pushNamed(context, '/user/sell'),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsList() {
    if (isAssetsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assets.isEmpty) {
      return Center(
        child: Text('هیچ دارایی‌ای یافت نشد', style: appTextTheme.bodyMedium),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('دارایی‌های من:', style: appTextTheme.titleSmall),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/user/assets'),
              child: Text(
                'مشاهده همه',
                style: appTextTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _assets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final asset = _assets[index];
              final symbol = asset['coin']['symbol'] ?? '---';
              final amount = asset['amount'] ?? 0;
              final logoUrl = asset['coin']['image'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child:
                          logoUrl.isNotEmpty
                              ? Image.network(
                                logoUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Icon(
                                      Icons.currency_bitcoin,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                              )
                              : Icon(
                                Icons.currency_bitcoin,
                                color: AppColors.primary,
                                size: 36,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      symbol.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: appTextTheme.headlineMedium,
                    ),
                    Text(
                      double.parse(amount.toString()).toStringAsFixed(6),
                      textAlign: TextAlign.center,
                      style: appTextTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تاریخچه تراکنش‌ها:', style: appTextTheme.titleSmall),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/user/history'),
              child: Text(
                'مشاهده همه',
                style: appTextTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Text('تراکنشی ثبت نشده است', style: appTextTheme.bodyMedium)
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isBuy = tx['transaction_type'] == 'buy';
                final coinSymbol = tx['coin_symbol'] ?? '';
                final rawValue = tx['total_value'];
                final value =
                    rawValue != null
                        ? double.tryParse(
                              rawValue.toString(),
                            )?.toStringAsFixed(2) ??
                            '0.00'
                        : '0.00';
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          size: 32,
                          isBuy ? Iconsax.trend_up : Iconsax.trend_down,
                          color: isBuy ? Colors.green : Colors.red,
                        ),
                      ),

                      Text((isBuy ? 'خرید' : 'فروش')),

                      const SizedBox(height: 12),

                      Text(
                        coinSymbol.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: appTextTheme.headlineMedium,
                      ),

                      Text('$value \$', style: appTextTheme.bodyMedium),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('پنل کاربری', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 20),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 24),
              onPressed: () => Navigator.pushNamed(context, '/user/setting'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildAssetsList(),
              const SizedBox(height: 16),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }
}
