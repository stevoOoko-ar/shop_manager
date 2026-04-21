import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../utils/currency_util.dart';

const Color kAccentPurple = Color(0xFF6C63FF);
const Color kDangerRed = Color(0xFFD32F2F);

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _buyingController;
  late final TextEditingController _sellingController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _categoryController;
  String? _formError;

  Product? get product => context
      .read<AppState>()
      .products
      .firstWhere((item) => item.id == widget.productId,
          orElse: () => Product(
                id: '',
                name: '',
                buyingPrice: 0,
                sellingPrice: 0,
                quantity: 0,
                lowStockThreshold: 0,
              ));

  @override
  void initState() {
    super.initState();
    final current = context.read<AppState>().products.firstWhere(
          (item) => item.id == widget.productId,
          orElse: () => Product(
            id: '',
            name: '',
            buyingPrice: 0,
            sellingPrice: 0,
            quantity: 0,
            lowStockThreshold: 0,
          ),
        );
    _nameController = TextEditingController(text: current.name);
    _buyingController =
        TextEditingController(text: current.buyingPrice.toStringAsFixed(2));
    _sellingController =
        TextEditingController(text: current.sellingPrice.toStringAsFixed(2));
    _quantityController =
        TextEditingController(text: current.quantity.toString());
    _thresholdController =
        TextEditingController(text: current.lowStockThreshold.toString());
    _categoryController = TextEditingController(text: current.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyingController.dispose();
    _sellingController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct(AppState state) async {
    final name = _nameController.text.trim();
    final buy = double.tryParse(_buyingController.text.trim()) ?? 0;
    final sell = double.tryParse(_sellingController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? -1;
    final threshold = int.tryParse(_thresholdController.text.trim()) ?? -1;
    final category = _categoryController.text.trim();

    if (name.isEmpty ||
        buy <= 0 ||
        sell <= 0 ||
        quantity < 0 ||
        threshold < 0 ||
        category.isEmpty) {
      setState(() {
        _formError = 'Please enter valid values for all fields.';
      });
      return;
    }
    if (sell <= buy) {
      setState(() {
        _formError = 'Selling price must be greater than buying price.';
      });
      return;
    }

    final updated = Product(
      id: widget.productId,
      name: name,
      buyingPrice: buy,
      sellingPrice: sell,
      quantity: quantity,
      lowStockThreshold: threshold,
      category: category,
    );
    final success = await state.updateProduct(updated);
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product updated successfully.'),
      ));
    } else {
      setState(() {
        _formError = 'Unable to save product. Please try again.';
      });
    }
  }

  Future<void> _confirmDelete(AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove product'),
          content: const Text(
              'Are you sure you want to remove this product and all its data?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kDangerRed, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final success = await state.deleteProduct(widget.productId);
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product deleted.'),
      ));
    } else {
      setState(() {
        _formError = 'Unable to delete product right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final current = state.products.firstWhere(
      (item) => item.id == widget.productId,
      orElse: () => Product(
        id: '',
        name: ''.toString(),
        buyingPrice: 0,
        sellingPrice: 0,
        quantity: 0,
        lowStockThreshold: 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Delete product',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(state),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(current.name,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Stock: ${current.quantity} • ${formatKes(current.sellingPrice)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 24),
              _buildField('Product name', _nameController),
              const SizedBox(height: 14),
              _buildField('Buying price', _buyingController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField('Selling price', _sellingController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField('Stock quantity', _quantityController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField('Low stock threshold', _thresholdController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField('Category', _categoryController),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                Text(_formError!, style: const TextStyle(color: kDangerRed)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveProduct(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Save changes',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
