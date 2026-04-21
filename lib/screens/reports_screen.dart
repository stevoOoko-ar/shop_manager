import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../utils/currency_util.dart';
import '../widgets/value_card.dart';

class ReportItem {
  final DateTime date;
  final double sales;
  final double profit;

  const ReportItem(
      {required this.date, required this.sales, required this.profit});
}

const Color kAccentBlue = Color(0xFF3B82F6);
const Color kSuccessGreen = Color(0xFF2E7D32);
const Color kDangerRed = Color(0xFFD32F2F);

class ReportsScreen extends StatelessWidget {
  final List<ReportItem> dailySales;
  final bool isLoading;
  final String? errorMessage;
  final ReportPeriod selectedPeriod;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final List<Product> bestSellers;
  final VoidCallback onRetry;
  final VoidCallback? onExportCsv;

  const ReportsScreen({
    super.key,
    required this.dailySales,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.bestSellers,
    required this.onRetry,
    required this.onExportCsv,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final totalWeekSales =
        dailySales.fold<double>(0, (prev, item) => prev + item.sales);
    final totalWeekProfit =
        dailySales.fold<double>(0, (prev, item) => prev + item.profit);
    final maxSales = dailySales
        .map((e) => e.sales)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);
    final hasNoData = dailySales.every((item) => item.sales == 0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPeriod == ReportPeriod.sevenDays
                  ? 'Sales trend (last 7 days)'
                  : 'Sales trend (last 30 days)',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onPeriodChanged(ReportPeriod.sevenDays),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedPeriod == ReportPeriod.sevenDays
                          ? Colors.white
                          : Colors.black87,
                      backgroundColor: selectedPeriod == ReportPeriod.sevenDays
                          ? kAccentBlue
                          : Colors.white,
                      side: BorderSide(
                          color: selectedPeriod == ReportPeriod.sevenDays
                              ? kAccentBlue
                              : Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('7 days'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onPeriodChanged(ReportPeriod.thirtyDays),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedPeriod == ReportPeriod.thirtyDays
                          ? Colors.white
                          : Colors.black87,
                      backgroundColor: selectedPeriod == ReportPeriod.thirtyDays
                          ? kAccentBlue
                          : Colors.white,
                      side: BorderSide(
                          color: selectedPeriod == ReportPeriod.thirtyDays
                              ? kAccentBlue
                              : Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('30 days'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (onExportCsv != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Sales to CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            ValueCard(title: 'Total sales', value: formatKes(totalWeekSales)),
            ValueCard(
                title: 'Total profit',
                value: formatKes(totalWeekProfit),
                color: kSuccessGreen),
            const SizedBox(height: 18),
            if (bestSellers.isNotEmpty) ...[
              const Text('Top sellers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: bestSellers.map((item) {
                  return Expanded(
                    child: Builder(
                      builder: (context) => Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[900]
                            : const Color(0xFFF4F8FF),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(item.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : null)),
                              const SizedBox(height: 8),
                              Text(formatKes(item.sellingPrice),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kAccentBlue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],
            if (isLoading)
              Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    height: 24,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else if (errorMessage != null)
              Builder(
                builder: (context) => Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[900]
                      : const Color(0xFFFFF2F2),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errorMessage!,
                            style: const TextStyle(
                                color: kDangerRed,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentBlue,
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
                ),
              )
            else if (hasNoData)
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.show_chart,
                            size: 72, color: Color(0xFF7C93F5)),
                      ),
                    ),
                    const Text('No sales yet this week',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Record your first sale to populate the chart and get daily insights.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                height: 210,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: dailySales.map((item) {
                    final barHeight =
                        maxSales > 0 ? 140.0 * (item.sales / maxSales) : 0.0;
                    final isHighlight = item.sales ==
                        dailySales.map((e) => e.sales).reduce(
                            (value, element) =>
                                value > element ? value : element);
                    return Expanded(
                      child: Tooltip(
                        message:
                            '${item.date.month}/${item.date.day}\nSales: ${formatKes(item.sales)}\nProfit: ${formatKes(item.profit)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: barHeight,
                              width: 28,
                              decoration: BoxDecoration(
                                color: isHighlight
                                    ? kAccentBlue
                                    : const Color(0xFF8FB9FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('${item.date.month}/${item.date.day}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Daily breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...dailySales.map((item) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Text('${item.date.month}/${item.date.day}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    title: Text('Sales: ${formatKes(item.sales)}'),
                    trailing: Text(formatKes(item.profit),
                        style: const TextStyle(
                            color: kSuccessGreen, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
