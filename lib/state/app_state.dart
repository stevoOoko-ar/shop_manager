import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../screens/reports_screen.dart';
import '../services/backend_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/shop_service.dart';
import '../config.dart';

const bool useBackend = true;

final ShopService dataService =
    useBackend ? BackendService(baseUrl: backendUrl) : DatabaseService.instance;

enum ProductSortOption {
  alphabetical,
  lowStockFirst,
  priceAsc,
  priceDesc,
}

enum ReportPeriod {
  sevenDays,
  thirtyDays,
}

class AppState extends ChangeNotifier {
  final List<Product> products = [];
  final List<Sale> sales = [];
  final List<ReportItem> reports = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController buyingPriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController lowStockController = TextEditingController();
  final TextEditingController categoryController =
      TextEditingController(text: 'General');

  bool isLoading = true;
  bool isSavingProduct = false;
  bool isRecordingSale = false;
  bool hasProductsError = false;
  bool hasReportsError = false;
  bool showOfflineBanner = false;
  String? productFormError;
  String? saleErrorMessage;
  ThemeMode themeMode = ThemeMode.light;
  String productSearch = '';
  ProductSortOption sortOption = ProductSortOption.alphabetical;
  ReportPeriod reportPeriod = ReportPeriod.sevenDays;
  String selectedCategory = 'All';
  int currentIndex = 0;
  int saleQuantity = 1;
  String? selectedProductId;
  final Map<String, String?> fieldErrors = {
    'name': null,
    'buyingPrice': null,
    'sellingPrice': null,
    'quantity': null,
    'lowStockThreshold': null,
  };

  AppState() {
    init();
  }

  Product? get selectedProduct {
    if (products.isEmpty) return null;
    if (selectedProductId == null) return products.first;
    try {
      return products.firstWhere((product) => product.id == selectedProductId);
    } catch (_) {
      return products.first;
    }
  }

  List<Product> get lowStockProducts =>
      products.where((product) => product.isLowStock).toList();

  List<Product> get filteredProducts {
    final filter = productSearch.trim().toLowerCase();
    final categoryFilter = selectedCategory;
    var filtered = products.where((product) => !product.isDeleted).toList();
    if (filter.isNotEmpty) {
      filtered = filtered
          .where((product) => product.name.toLowerCase().contains(filter))
          .toList();
    }
    if (categoryFilter != 'All') {
      filtered = filtered
          .where((product) => product.category == categoryFilter)
          .toList();
    }
    switch (sortOption) {
      case ProductSortOption.alphabetical:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.lowStockFirst:
        filtered.sort((a, b) {
          final lowA = a.isLowStock ? 0 : 1;
          final lowB = b.isLowStock ? 0 : 1;
          return lowA.compareTo(lowB);
        });
        break;
      case ProductSortOption.priceAsc:
        filtered.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case ProductSortOption.priceDesc:
        filtered.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
    }
    return filtered;
  }

  List<ReportItem> get reportItems {
    final days = reportPeriod == ReportPeriod.sevenDays ? 7 : 30;
    return reports.take(days).toList();
  }

  double get todaySales {
    final now = DateTime.now();
    return sales
        .where((sale) =>
            sale.date.year == now.year &&
            sale.date.month == now.month &&
            sale.date.day == now.day)
        .map((sale) {
      final product = products.firstWhere(
        (product) => product.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: '',
          buyingPrice: 0,
          sellingPrice: 0,
          quantity: 0,
          lowStockThreshold: 0,
        ),
      );
      return sale.quantity * product.sellingPrice;
    }).fold<double>(0, (prev, value) => prev + value);
  }

  double get todayProfit {
    final now = DateTime.now();
    return sales
        .where((sale) =>
            sale.date.year == now.year &&
            sale.date.month == now.month &&
            sale.date.day == now.day)
        .map((sale) {
      final product = products.firstWhere(
        (product) => product.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: '',
          buyingPrice: 0,
          sellingPrice: 0,
          quantity: 0,
          lowStockThreshold: 0,
        ),
      );
      return sale.quantity * (product.sellingPrice - product.buyingPrice);
    }).fold<double>(0, (prev, value) => prev + value);
  }

  List<Product> get bestSellers {
    final totals = <String, double>{};
    for (final sale in sales) {
      final product = products.firstWhere(
        (product) => product.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: '',
          buyingPrice: 0,
          sellingPrice: 0,
          quantity: 0,
          lowStockThreshold: 0,
        ),
      );
      totals[product.name] =
          (totals[product.name] ?? 0) + sale.quantity * product.sellingPrice;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((entry) => Product(
              id: entry.key,
              name: entry.key,
              buyingPrice: 0,
              sellingPrice: entry.value,
              quantity: 0,
              lowStockThreshold: 0,
            ))
        .take(3)
        .toList();
  }

  bool get isProductFormValid =>
      fieldErrors.values.every((value) => value == null) &&
      productFormError == null;

  bool get isSaleAvailable =>
      selectedProduct != null && selectedProduct!.quantity > 0;

  bool get showPriceWarning {
    final buy = double.tryParse(buyingPriceController.text.trim()) ?? 0;
    final sell = double.tryParse(sellingPriceController.text.trim()) ?? 0;
    return buy > 0 && sell > 0 && sell <= buy;
  }

  Future<void> init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchedProducts = await dataService.getProducts();
      if (fetchedProducts.isEmpty) {
        await dataService.seedProducts([
          Product(
            id: 'p1',
            name: 'Tea bags',
            buyingPrice: 15,
            sellingPrice: 25,
            quantity: 10,
            lowStockThreshold: 5,
            category: 'Beverages',
          ),
          Product(
            id: 'p2',
            name: 'Sugar 1kg',
            buyingPrice: 40,
            sellingPrice: 55,
            quantity: 4,
            lowStockThreshold: 5,
            category: 'Pantry',
          ),
          Product(
            id: 'p3',
            name: 'Chips',
            buyingPrice: 10,
            sellingPrice: 20,
            quantity: 1,
            lowStockThreshold: 3,
            category: 'Snacks',
          ),
          Product(
            id: 'p4',
            name: 'eggs',
            buyingPrice: 450,
            sellingPrice: 528,
            quantity: 25,
            lowStockThreshold: 5,
            category: 'Dairy',
          ),
          Product(
            id: 'p5',
            name: 'flour',
            buyingPrice: 95,
            sellingPrice: 125,
            quantity: 184,
            lowStockThreshold: 15,
            category: 'Pantry',
          ),
          Product(
            id: 'p6',
            name: 'soap',
            buyingPrice: 650,
            sellingPrice: 800,
            quantity: 1,
            lowStockThreshold: 2,
            category: 'Household',
          ),
        ]);
      }
      await refreshData();
    } catch (_) {
      hasProductsError = true;
      isLoading = false;
      notifyListeners();
    }
  }

  void _checkLowStockNotifications() {
    final notificationService = NotificationService();
    for (final product in products) {
      if (product.isLowStock) {
        notificationService.showLowStockNotification(
            product.name, product.quantity);
      }
    }
  }

  Future<void> refreshData() async {
    try {
      final fetchedProducts = await dataService.getProducts();
      final fetchedSales = await dataService.getSales();
      final fetchedReports = await dataService
          .getReports(reportPeriod == ReportPeriod.sevenDays ? 7 : 30);
      products
        ..clear()
        ..addAll(fetchedProducts);
      sales
        ..clear()
        ..addAll(fetchedSales);
      reports
        ..clear()
        ..addAll(fetchedReports);
      if (products.isNotEmpty && selectedProductId == null) {
        selectedProductId = products.first.id;
      }
      isLoading = false;
      hasProductsError = false;
      hasReportsError = false;

      // Check for low stock notifications
      _checkLowStockNotifications();
    } catch (_) {
      hasProductsError = true;
      hasReportsError = true;
    }
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSearchText(String value) {
    productSearch = value;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    sortOption = option;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  List<String> get categories {
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  void setReportPeriod(ReportPeriod period) async {
    reportPeriod = period;
    isLoading = true;
    notifyListeners();
    await refreshData();
  }

  void setSelectedProduct(Product? product) {
    selectedProductId = product?.id;
    if (product != null && saleQuantity > product.quantity) {
      saleQuantity = product.quantity > 0 ? 1 : 0;
    }
    notifyListeners();
  }

  void increaseSaleQuantity() {
    if (selectedProduct != null && saleQuantity < selectedProduct!.quantity) {
      saleQuantity++;
      notifyListeners();
    }
  }

  void decreaseSaleQuantity() {
    if (saleQuantity > 1) {
      saleQuantity--;
      notifyListeners();
    }
  }

  void resetSaleForm() {
    saleQuantity = 1;
    selectedProductId = products.isNotEmpty ? products.first.id : null;
    saleErrorMessage = null;
    notifyListeners();
  }

  bool _validateProduct() {
    final name = nameController.text.trim();
    final buy = double.tryParse(buyingPriceController.text.trim()) ?? 0;
    final sell = double.tryParse(sellingPriceController.text.trim()) ?? 0;
    final quantity = int.tryParse(quantityController.text.trim()) ?? -1;
    final threshold = int.tryParse(lowStockController.text.trim()) ?? -1;

    fieldErrors.updateAll((key, value) => null);
    productFormError = null;

    if (name.isEmpty) {
      fieldErrors['name'] = 'Product name is required';
    }
    if (buy <= 0) {
      fieldErrors['buyingPrice'] = 'Enter a valid buying price';
    }
    if (sell <= 0) {
      fieldErrors['sellingPrice'] = 'Enter a valid selling price';
    }
    if (quantity < 0) {
      fieldErrors['quantity'] = 'Stock quantity must be zero or more';
    }
    if (threshold < 0) {
      fieldErrors['lowStockThreshold'] =
          'Low stock threshold must be zero or more';
    }
    if (sell <= buy && sell > 0 && buy > 0) {
      fieldErrors['sellingPrice'] =
          'Selling price should be greater than buying price';
    }
    if (products
        .any((product) => product.name.toLowerCase() == name.toLowerCase())) {
      productFormError = 'Product name already exists';
    }

    notifyListeners();
    return isProductFormValid;
  }

  void clearProductForm() {
    nameController.clear();
    buyingPriceController.clear();
    sellingPriceController.clear();
    quantityController.clear();
    lowStockController.clear();
    categoryController.text = 'General';
    fieldErrors.updateAll((key, value) => null);
    productFormError = null;
    notifyListeners();
  }

  Future<bool> addProduct() async {
    if (!_validateProduct()) return false;

    setStateSave(true);
    try {
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        buyingPrice: double.parse(buyingPriceController.text.trim()),
        sellingPrice: double.parse(sellingPriceController.text.trim()),
        quantity: int.parse(quantityController.text.trim()),
        lowStockThreshold: int.parse(lowStockController.text.trim()),
        category: categoryController.text.trim().isEmpty
            ? 'General'
            : categoryController.text.trim(),
      );
      await dataService.addProduct(product);
      await refreshData();
      clearProductForm();
      return true;
    } catch (_) {
      productFormError = 'Could not save product. Try again.';
      return false;
    } finally {
      setStateSave(false);
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await dataService.updateProduct(product);
      await refreshData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await dataService.deleteProduct(id);
      await refreshData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordSale() async {
    final selected = selectedProduct;
    if (selected == null) {
      saleErrorMessage = 'Select a product first.';
      notifyListeners();
      return false;
    }
    if (saleQuantity <= 0) {
      saleErrorMessage = 'Sale quantity must be at least 1.';
      notifyListeners();
      return false;
    }
    if (saleQuantity > selected.quantity) {
      saleErrorMessage = 'Not enough stock for this sale.';
      notifyListeners();
      return false;
    }

    isRecordingSale = true;
    saleErrorMessage = null;
    notifyListeners();
    try {
      final sale = Sale(
        productId: selected.id,
        date: DateTime.now(),
        quantity: saleQuantity,
      );
      await dataService.recordSale(sale);
      await refreshData();
      resetSaleForm();
      return true;
    } catch (_) {
      saleErrorMessage = 'Failed to record sale. Please retry.';
      return false;
    } finally {
      isRecordingSale = false;
      notifyListeners();
    }
  }

  void setStateSave(bool value) {
    isSavingProduct = value;
    notifyListeners();
  }

  String exportSalesToCsv() {
    final List<List<String>> csvData = [
      ['Date', 'Product', 'Quantity', 'Unit Price', 'Total Sales', 'Profit']
    ];

    for (final sale in sales) {
      final product = products.firstWhere(
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

      final saleDate = sale.date;
      final totalSales = sale.quantity * product.sellingPrice;
      final profit =
          sale.quantity * (product.sellingPrice - product.buyingPrice);

      csvData.add([
        '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}',
        product.name,
        sale.quantity.toString(),
        product.sellingPrice.toStringAsFixed(2),
        totalSales.toStringAsFixed(2),
        profit.toStringAsFixed(2),
      ]);
    }

    return csvData.map((row) => row.map(_escapeCsvField).join(',')).join('\n');
  }

  String _escapeCsvField(String field) {
    final escaped = field.replaceAll('"', '""');
    final needsQuotes = field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  @override
  void dispose() {
    nameController.dispose();
    buyingPriceController.dispose();
    sellingPriceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}
