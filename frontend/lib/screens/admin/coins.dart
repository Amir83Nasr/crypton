import 'package:crypton_frontend/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:crypton_frontend/theme.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_modal.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';

class AdminCoinsTab extends StatefulWidget {
  const AdminCoinsTab({super.key});

  @override
  State<AdminCoinsTab> createState() => _AdminCoinsTabState();
}

class _AdminCoinsTabState extends State<AdminCoinsTab> {
  final CoinService _coinService = CoinService();

  List<dynamic> _allCoins = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<dynamic> get _filteredCoins {
    final query = _searchQuery.toLowerCase();
    return _allCoins.where((coin) {
      final name = '${coin['name']} ${coin['symbol']}'.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      if (forceRefresh) {
        _coinService.clearCache();
      }
      final coins = await _coinService.getCoins();
      setState(() {
        _allCoins = coins;
      });
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'خطا در دریافت رمز ارزها: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCoinStatus(String symbol, bool isActive) async {
    final success = await _coinService.toggleCoinStatus(symbol, isActive);
    if (success) {
      final index = _allCoins.indexWhere((coin) => coin['symbol'] == symbol);
      if (index != -1) {
        setState(() {
          _allCoins[index]['is_active'] = !isActive;
        });
      }

      showCustomSnackBar(
        context: context,
        message: isActive ? 'رمز ارز غیرفعال شد' : 'رمز ارز فعال شد',
      );
    } else {
      showCustomSnackBar(
        context: context,
        message: 'خطا در تغییر وضعیت رمز ارز',
        isError: true,
      );
    }
  }

  String _formatNumber(dynamic value, {int decimalPlaces = 4}) {
    if (value == null) return '-';
    return double.tryParse(value.toString())?.toStringAsFixed(decimalPlaces) ??
        '-';
  }

  void _showCoinDetails(Map<String, dynamic> coin) {
    final isDisabled = !(coin['is_active'] as bool? ?? false);

    showCustomBottomModal(
      context: context,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Image.network(
                      coin['image'],
                      errorBuilder: (_, __, ___) => const Icon(Iconsax.coin),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${coin['name']} (${coin['symbol']})',
                      style: appTextTheme.titleLarge,
                    ),
                  ),
                  Text(
                    coin['is_active'] ? 'فعال' : 'غیرفعال',
                    style: appTextTheme.bodyMedium?.copyWith(
                      color:
                          coin['is_active']
                              ? AppColors.primary
                              : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCoinInfo(coin),
            const SizedBox(height: 24),
            CustomButton(
              text: isDisabled ? 'فعال‌سازی' : 'غیرفعال‌سازی',
              onPressed: () async {
                await _toggleCoinStatus(coin['symbol'], coin['is_active']);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinInfo(Map<String, dynamic> coin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('قیمت فعلی: ${_formatNumber(coin['current_price'])} \$'),
          const SizedBox(height: 8),
          Text('بیشترین قیمت: ${_formatNumber(coin['ath'])} \$'),
          const SizedBox(height: 8),
          Text('کمترین قیمت: ${_formatNumber(coin['atl'])} \$'),
          const SizedBox(height: 8),
          Text(
            'ارزش بازار: ${_formatNumber(coin['market_cap'], decimalPlaces: 0)} \$',
          ),
          const SizedBox(height: 8),
          Text(
            'حجم معاملات: ${_formatNumber(coin['total_volume'], decimalPlaces: 0)}',
          ),
          const SizedBox(height: 8),
          Text('رتبه بازار: ${coin['market_cap_rank'] ?? '-'}'),
        ],
      ),
    );
  }

  Widget _buildCoinCard(Map<String, dynamic> coin) {
    return GestureDetector(
      onTap: () => _showCoinDetails(coin),
      child: Container(
        decoration: BoxDecoration(
          color:
              coin['is_active']
                  ? Colors.transparent
                  : AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: coin['is_active'] ? AppColors.primary : AppColors.error,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Image.network(
                coin['image'],
                errorBuilder: (_, __, ___) => const Icon(Iconsax.coin),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${coin['name']} (${coin['symbol']})',
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
        hintText: 'جستجوی رمز ارز...',
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
      onRefresh: () => _loadCoins(forceRefresh: true),
      child: Column(
        children: [
          _buildSearchBox(),
          const SizedBox(height: 16),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCoins.isEmpty
                    ? const Center(child: Text('هیچ رمز ارزی یافت نشد'))
                    : ListView.separated(
                      itemCount: _filteredCoins.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              _buildCoinCard(_filteredCoins[index]),
                    ),
          ),
        ],
      ),
    );
  }
}
