import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:iconsax/iconsax.dart';

class Assets extends StatefulWidget {
  const Assets({super.key});

  @override
  State<Assets> createState() => _AssetsState();
}

class _AssetsState extends State<Assets> {
  List<Map<String, dynamic>> _assets = [];
  bool isAssetsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final result = await AuthApiService().getMyAssets();
      setState(() {
        _assets = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('همه دارایی‌ها', style: appTextTheme.titleMedium),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 16, right: 16),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_right_1, size: 24),
          ),
        ),
      ),
      body:
          isAssetsLoading
              ? const Center(child: CircularProgressIndicator())
              : _assets.isEmpty
              ? Center(
                child: Text(
                  'هیچ دارایی‌ای یافت نشد',
                  style: appTextTheme.bodyMedium,
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAssets,
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    final coin = asset['coin'];
                    final name = coin['name'];
                    final symbol = coin['symbol'].toUpperCase();
                    final image = coin['image'];
                    final amount = double.tryParse(asset['amount']) ?? 0;
                    final currentPrice =
                        double.tryParse(coin['current_price']) ?? 0;
                    final totalValue = amount * currentPrice;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                        ),
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
                            padding: const EdgeInsets.all(8),
                            child: ClipOval(
                              child:
                                  image.isNotEmpty
                                      ? Image.network(
                                        image,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.currency_bitcoin,
                                            color: AppColors.primary,
                                            size: 36,
                                          );
                                        },
                                      )
                                      : Icon(
                                        Icons.currency_bitcoin,
                                        color: AppColors.primary,
                                        size: 36,
                                      ),
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            spacing: 6,
                            children: [
                              Text('$name ($symbol)'),

                              Text(
                                '${totalValue.toStringAsFixed(2)} \$ :ارزش دارایی',
                                style: appTextTheme.bodyMedium,
                              ),

                              Text(
                                '${amount.toStringAsFixed(8)} :مقدار دارایی',
                                style: appTextTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
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
