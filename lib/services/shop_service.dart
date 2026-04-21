
import '../models/product.dart';
import '../models/sale.dart';
import '../screens/reports_screen.dart';

abstract class ShopService {
  Future<void> initDB();
  Future<List<Product>> getProducts();
  Future<List<Sale>> getSales();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<void> recordSale(Sale sale);
  Future<void> seedProducts(List<Product> products);
  Future<List<ReportItem>> getReports(int days);
}
