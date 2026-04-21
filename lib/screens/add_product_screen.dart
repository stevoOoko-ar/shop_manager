import 'package:flutter/material.dart';

const Color kAccentPurple = Color(0xFF6C63FF);
const Color kWarningOrange = Color(0xFFF57C00);

class AddProductScreen extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController buyingController;
  final TextEditingController sellingController;
  final TextEditingController quantityController;
  final TextEditingController lowStockController;
  final TextEditingController categoryController;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final Map<String, String?> fieldErrors;
  final String? generalError;
  final bool isSaving;
  final bool showPriceWarning;

  const AddProductScreen({
    super.key,
    required this.nameController,
    required this.buyingController,
    required this.sellingController,
    required this.quantityController,
    required this.lowStockController,
    required this.categoryController,
    required this.onSave,
    required this.onClear,
    required this.fieldErrors,
    this.generalError,
    this.isSaving = false,
    this.showPriceWarning = false,
  });

  InputDecoration _fieldDecoration(String label, String? error) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
            const Text('Add product',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Product name', fieldErrors['name']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: buyingController,
              keyboardType: TextInputType.number,
              decoration:
                  _fieldDecoration('Buying price', fieldErrors['buyingPrice']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sellingController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                  'Selling price', fieldErrors['sellingPrice']),
            ),
            if (showPriceWarning)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: kWarningOrange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selling price should be greater than buying price.',
                        style: TextStyle(color: kWarningOrange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration:
                  _fieldDecoration('Stock quantity', fieldErrors['quantity']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lowStockController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                  'Low stock threshold', fieldErrors['lowStockThreshold']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Category', null),
            ),
            const SizedBox(height: 16),
            if (generalError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(generalError!,
                    style: const TextStyle(
                        color: kWarningOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Product',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClear,
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
