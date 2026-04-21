import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/currency_util.dart';

const Color kAccentPurple = Color(0xFF6C63FF);
const Color kSuccessGreen = Color(0xFF2E7D32);
const Color kDangerRed = Color(0xFFD32F2F);

class SalesScreen extends StatelessWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final int saleQuantity;
  final ValueChanged<Product?> onProductChange;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onRecordSale;
  final VoidCallback onReset;
  final bool isProcessing;
  final String? errorMessage;

  const SalesScreen({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.saleQuantity,
    required this.onProductChange,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onRecordSale,
    required this.onReset,
    this.isProcessing = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        selectedProduct ?? (products.isNotEmpty ? products.first : null);
    final availableStock = selected?.quantity ?? 0;
    final total = selected != null ? saleQuantity * selected.sellingPrice : 0.0;
    final isDisabled = selected == null || availableStock == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record Sale',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Select product',
                filled: true,
                fillColor: const Color(0xFFF7F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Product?>(
                  value: selected,
                  isExpanded: true,
                  items: products
                      .map((product) => DropdownMenuItem<Product>(
                          value: product, child: Text(product.name)))
                      .toList(),
                  onChanged: onProductChange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Available stock: $availableStock',
                      style: const TextStyle(fontSize: 16)),
                ),
                if (availableStock == 0)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Text('Out of stock',
                        style: TextStyle(
                            color: kDangerRed, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: saleQuantity <= 1
                            ? Colors.grey.shade400
                            : Colors.black,
                        onPressed:
                            saleQuantity <= 1 ? null : onDecreaseQuantity,
                      ),
                      Text('$saleQuantity',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: isDisabled || saleQuantity >= availableStock
                            ? Colors.grey.shade400
                            : Colors.black,
                        onPressed: isDisabled || saleQuantity >= availableStock
                            ? null
                            : onIncreaseQuantity,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(formatKes(total),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kSuccessGreen)),
                    ],
                  ),
                ],
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(errorMessage!,
                    style: const TextStyle(color: kDangerRed, fontSize: 14)),
              ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled || isProcessing ? null : onRecordSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Record Sale', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccentPurple,
                  side: const BorderSide(color: kAccentPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Clear form', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
