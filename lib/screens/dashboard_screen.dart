import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/currency_util.dart';
import '../widgets/value_card.dart';

const Color kLowStockRed = Color(0xFFFFE6E6);
const Color kDangerRed = Color(0xFFD32F2F);
const Color kAccentPurple = Color(0xFF6C63FF);

class DashboardScreen extends StatelessWidget {
  final double totalSales;
  final double totalProfit;
  final List<Product> lowStockProducts;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final VoidCallback onAddSale;
  final VoidCallback onAddProduct;
  final VoidCallback onRetry;

  const DashboardScreen({
    super.key,
    required this.totalSales,
    required this.totalProfit,
    required this.lowStockProducts,
    required this.onAddSale,
    required this.onAddProduct,
    required this.onRetry,
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
  });

  Widget _buildLowStockRow(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: kLowStockRed,
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(product.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: kDangerRed, size: 18),
              const SizedBox(width: 6),
              Text('${product.quantity} left',
                  style: const TextStyle(
                      color: kDangerRed, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOffline)
              Builder(
                builder: (context) => Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : const Color(0xFFE7EDF9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Offline mode enabled. Data is cached locally.',
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87)),
                ),
              ),
            if (isLoading) ...[
              _buildLoadingCard(),
              _buildLoadingCard(),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ValueCard(
                      title: 'Today\'s Sales',
                      value: formatKes(totalSales),
                    ),
                  ),
                  Expanded(
                    child: ValueCard(
                      title: 'Today\'s Profit',
                      value: formatKes(totalProfit),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Low Stock Alerts',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kDangerRed)),
              const SizedBox(height: 10),
              if (errorMessage != null)
                Card(
                  color: const Color(0xFFFFEBEE),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errorMessage!,
                            style: const TextStyle(
                                color: kDangerRed,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentPurple,
                              foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (lowStockProducts.isEmpty)
                Builder(
                  builder: (context) => Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[900]
                        : const Color(0xFFEEF7ED),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('All stocked up!',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            'No low stock items. Keep an eye on your top sellers and add more stock when needed.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: lowStockProducts
                      .map((product) => _buildLowStockRow(product))
                      .toList(),
                ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Add Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: onAddSale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kAccentPurple,
                      side: const BorderSide(color: kAccentPurple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: onAddProduct,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
