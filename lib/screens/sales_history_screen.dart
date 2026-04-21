import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../utils/currency_util.dart';

const Color kAccentPurple = Color(0xFF6C63FF);

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final sales = appState.sales.where((sale) {
      final saleDate = sale.date;
      return saleDate.year == _selectedDate.year &&
          saleDate.month == _selectedDate.month &&
          saleDate.day == _selectedDate.day;
    }).toList();

    final totalSales = sales.fold<double>(0, (sum, sale) {
      final product = appState.products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: 'Unknown',
          buyingPrice: 0,
          sellingPrice: 0,
          quantity: 0,
          lowStockThreshold: 0,
        ),
      );
      return sum + (sale.quantity * product.sellingPrice);
    });

    final totalProfit = sales.fold<double>(0, (sum, sale) {
      final product = appState.products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: 'Unknown',
          buyingPrice: 0,
          sellingPrice: 0,
          quantity: 0,
          lowStockThreshold: 0,
        ),
      );
      return sum +
          (sale.quantity * (product.sellingPrice - product.buyingPrice));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Sales',
                      value: formatKes(totalSales),
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Profit',
                      value: formatKes(totalProfit),
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sales.isEmpty
                  ? const Center(
                      child: Text('No sales for selected date'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        final product = appState.products.firstWhere(
                          (p) => p.id == sale.productId,
                          orElse: () => Product(
                            id: '',
                            name: 'Unknown Product',
                            buyingPrice: 0,
                            sellingPrice: 0,
                            quantity: 0,
                            lowStockThreshold: 0,
                          ),
                        );
                        final saleTime = sale.date;
                        final profit = sale.quantity *
                            (product.sellingPrice - product.buyingPrice);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${saleTime.hour}:${saleTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantity: ${sale.quantity}',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Revenue: ${formatKes(sale.quantity * product.sellingPrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Profit: ${formatKes(profit)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: kAccentPurple, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
