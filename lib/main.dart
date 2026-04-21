import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'screens/add_product_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/sales_screen.dart';
import 'state/app_state.dart';
import 'config.dart';

const Color kAccentPurple = Color(0xFF6C63FF);
const Color kSuccessGreen = Color(0xFF2E7D32);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate backend URL configuration
  validateBackendUrl();

  // Initialize notification service
  await NotificationService().initialize();

  // Log active backend URL for debugging
  debugPrint('Shop Manager starting...');
  debugPrint('Active backend URL: $backendUrl');
  debugPrint('Environment: ${currentEnvironment == Environment.dev ? 'Development' : 'Production'}');

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ShopManagerApp(),
    ),
  );
}

class ShopManagerApp extends StatelessWidget {
  const ShopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Shop Manager',
      theme: ThemeData(
        primaryColor: kAccentPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccentPurple,
          brightness: Brightness.light,
          primary: kAccentPurple,
          secondary: const Color(0xFF3B82F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kAccentPurple, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ).apply(fontFamily: 'Roboto'),
      ),
      darkTheme: ThemeData(
        primaryColor: kAccentPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccentPurple,
          brightness: Brightness.dark,
          primary: kAccentPurple,
          secondary: const Color(0xFF3B82F6),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kAccentPurple, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ).apply(fontFamily: 'Roboto'),
      ),
      themeMode: appState.themeMode,
      home: const ShopManagerHome(),
    );
  }
}

class ShopManagerHome extends StatelessWidget {
  const ShopManagerHome({super.key});

  Future<void> _exportCsv(BuildContext context, AppState appState) async {
    if (!context.mounted) return;
    try {
      final csvData = appState.exportSalesToCsv();
      final now = DateTime.now();
      final fileName =
          'sales_export_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.csv';

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, save to downloads directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(csvData);

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV exported to ${file.path}')),
          );
        }
      } else {
        // For web or other platforms, show the CSV content in a dialog
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sales Export CSV'),
            content: SingleChildScrollView(
              child: SelectableText(csvData),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export CSV')),
      );
    }
  }

  Future<void> _createBackup(BuildContext context, AppState appState) async {
    if (!context.mounted) return;
    try {
      final backupService = BackupService();
      final success = await backupService.createBackup();

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create backup')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create backup')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, AppState appState) async {
    if (!context.mounted) return;
    try {
      final backupService = BackupService();
      final exists = await backupService.backupExists();

      if (!exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup found')),
        );
        return;
      }

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
              'This will replace all current data with the backup. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final success = await backupService.restoreBackup();

      if (!context.mounted) return;
      if (success) {
        await appState.refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore backup')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore backup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final screens = [
      DashboardScreen(
        totalSales: appState.todaySales,
        totalProfit: appState.todayProfit,
        lowStockProducts: appState.lowStockProducts,
        onAddSale: () => appState.setCurrentIndex(3),
        onAddProduct: () => appState.setCurrentIndex(2),
        onRetry: appState.refreshData,
        isLoading: appState.isLoading,
        isOffline: appState.showOfflineBanner,
        errorMessage:
            appState.hasProductsError ? 'Unable to load dashboard data.' : null,
      ),
      ProductsScreen(
        products: appState.filteredProducts,
        searchText: appState.productSearch,
        onSearchChanged: appState.setSearchText,
        sortOption: appState.sortOption,
        onSortOptionChanged: appState.setSortOption,
        onProductTap: (product) {
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ));
        },
        onDelete: (product) => appState.deleteProduct(product.id),
        isLoading: appState.isLoading,
        hasError: appState.hasProductsError,
        onRetry: appState.refreshData,
      ),
      AddProductScreen(
        nameController: appState.nameController,
        buyingController: appState.buyingPriceController,
        sellingController: appState.sellingPriceController,
        quantityController: appState.quantityController,
        lowStockController: appState.lowStockController,
        categoryController: appState.categoryController,
        onSave: () => appState.addProduct(),
        onClear: appState.clearProductForm,
        fieldErrors: appState.fieldErrors,
        generalError: appState.productFormError,
        isSaving: appState.isSavingProduct,
        showPriceWarning: appState.showPriceWarning,
      ),
      SalesScreen(
        products: appState.products,
        selectedProduct: appState.selectedProduct,
        saleQuantity: appState.saleQuantity,
        onProductChange: appState.setSelectedProduct,
        onIncreaseQuantity: appState.increaseSaleQuantity,
        onDecreaseQuantity: appState.decreaseSaleQuantity,
        onRecordSale: () => appState.recordSale(),
        onReset: appState.resetSaleForm,
        isProcessing: appState.isRecordingSale,
        errorMessage: appState.saleErrorMessage,
      ),
      ReportsScreen(
        dailySales: appState.reportItems,
        selectedPeriod: appState.reportPeriod,
        onPeriodChanged: appState.setReportPeriod,
        bestSellers: appState.bestSellers,
        isLoading: appState.isLoading,
        errorMessage:
            appState.hasReportsError ? 'Unable to load report data.' : null,
        onRetry: appState.refreshData,
        onExportCsv: () {
          if (!context.mounted) return;
          _exportCsv(context, appState);
        },
      ),
      const SalesHistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Manager'),
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(appState.themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: appState.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (!context.mounted) return;
              switch (value) {
                case 'backup':
                  _createBackup(context, appState);
                  break;
                case 'restore':
                  _restoreBackup(context, appState);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup),
                    SizedBox(width: 8),
                    Text('Create Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Restore Backup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: appState.currentIndex, children: screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appState.currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kAccentPurple,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        elevation: 12,
        onTap: appState.setCurrentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
