import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../utils/currency_util.dart';

const Color kLightRed = Color(0xFFFFF1F1);
const Color kDangerRed = Color(0xFFD32F2F);
const Color kAccentPurple = Color(0xFF6C63FF);

class ProductsScreen extends StatelessWidget {
  final List<Product> products;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final ProductSortOption sortOption;
  final ValueChanged<ProductSortOption> onSortOptionChanged;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onDelete;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const ProductsScreen({
    super.key,
    required this.products,
    required this.searchText,
    required this.onSearchChanged,
    required this.sortOption,
    required this.onSortOptionChanged,
    required this.onProductTap,
    required this.onDelete,
    required this.onRetry,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final filter = searchText.trim().toLowerCase();
    final filteredProducts = filter.isEmpty
        ? products
        : products
            .where((product) =>
                product.name.toLowerCase().contains(filter.toLowerCase()))
            .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search products',
                filled: true,
                fillColor: const Color(0xFFF7F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Sort by:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<ProductSortOption>(
                    value: sortOption,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: ProductSortOption.alphabetical,
                        child: Text('A → Z'),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.lowStockFirst,
                        child: Text('Low stock first'),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.priceAsc,
                        child: Text('Price low → high'),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.priceDesc,
                        child: Text('Price high → low'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onSortOptionChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(builder: (context) {
                if (isLoading) {
                  return ListView.separated(
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                if (hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 72, color: kDangerRed),
                          const SizedBox(height: 16),
                          const Text(
                            'Network error while loading products.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pull to retry or check your connection.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: onRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 72, color: Color(0xFF7C93F5)),
                          SizedBox(height: 16),
                          Text('No products found',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            'Try a different keyword or add a new product to get started.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: kDangerRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Remove product'),
                              content: const Text(
                                  'Are you sure you want to remove this product?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kDangerRed,
                                      foregroundColor: Colors.white),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                        return confirmed == true;
                      },
                      onDismissed: (direction) => onDelete(product),
                      child: InkWell(
                        onTap: () => onProductTap(product),
                        borderRadius: BorderRadius.circular(16),
                        child: Builder(
                          builder: (context) => Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? (product.isLowStock
                                        ? Colors.red[900]
                                        : Colors.grey[800])
                                    : (product.isLowStock
                                        ? kLightRed
                                        : Colors.white),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 8),
                                        Text(
                                            'Stock ${product.quantity} · ${formatKes(product.sellingPrice)}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (product.isLowStock)
                                        const Icon(Icons.warning_amber_rounded,
                                            color: kDangerRed),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white38
                                              : Colors.black26),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
