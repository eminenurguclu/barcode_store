import 'package:flutter/material.dart';
import 'product_model.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Store Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  Future<void> _refreshProductList() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  void _handleSearch() async {
    String barcode = _searchController.text.trim();
    if (barcode.isEmpty) {
      _refreshProductList();
      return;
    }

    Product? product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (product != null) {
      setState(() {
        _products = [product];
      });
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Product not found"),
          content: const Text("Would you like to add a new product?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showProductForm(context, initialBarcode: barcode);
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      );
    }
  }

  void _calculatePrice(
      TextEditingController unitPriceCtrl,
      TextEditingController taxCtrl,
      TextEditingController totalCtrl,
      ) {
    double unit = double.tryParse(unitPriceCtrl.text) ?? 0.0;
    int tax = int.tryParse(taxCtrl.text) ?? 0;
    double total = unit + (unit * (tax / 100));
    totalCtrl.text = total.toStringAsFixed(2);
  }

  void _showProductForm(BuildContext context, {Product? product, String? initialBarcode}) {
    final formKey = GlobalKey<FormState>();
    final barcodeCtrl = TextEditingController(text: product?.barcodeNo ?? initialBarcode ?? '');
    final nameCtrl = TextEditingController(text: product?.productName ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final unitPriceCtrl = TextEditingController(text: product?.unitPrice.toString() ?? '');
    final taxCtrl = TextEditingController(text: product?.taxRate.toString() ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockInfo?.toString() ?? '');

    bool isEdit = product != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Barcode No'),
                  enabled: !isEdit,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: unitPriceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price',
                          errorMaxLines: 1,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final number = double.tryParse(value);
                          if (number == null) return 'Invalid';
                          if (number < 0) return 'Min 0';
                          return null;
                        },
                        onChanged: (_) => _calculatePrice(unitPriceCtrl, taxCtrl, priceCtrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: taxCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tax Rate (%)',
                          errorMaxLines: 1,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final number = int.tryParse(value);
                          if (number == null) return 'Invalid';
                          if (number < 0) return 'Min 0';
                          return null;
                        },
                        onChanged: (_) => _calculatePrice(unitPriceCtrl, taxCtrl, priceCtrl),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Total Price (Auto)'),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(labelText: 'Stock Info (Optional)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final number = int.tryParse(value);
                    if (number == null) return 'Invalid';
                    if (number < 0) return 'Min 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newProduct = Product(
                  barcodeNo: barcodeCtrl.text,
                  productName: nameCtrl.text,
                  category: categoryCtrl.text,
                  unitPrice: double.parse(unitPriceCtrl.text),
                  taxRate: int.parse(taxCtrl.text),
                  price: double.parse(priceCtrl.text),
                  stockInfo: stockCtrl.text.isEmpty ? null : int.parse(stockCtrl.text),
                );

                if (isEdit) {
                  await DatabaseHelper.instance.updateProduct(newProduct);
                } else {
                  var existing = await DatabaseHelper.instance.getProductByBarcode(newProduct.barcodeNo);
                  if (existing != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barcode already exists!')),
                    );
                    return;
                  }
                  await DatabaseHelper.instance.insertProduct(newProduct);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _refreshProductList();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteProduct(barcode);
              if (context.mounted) {
                Navigator.pop(context);
                _refreshProductList();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Store")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Enter Barcode",
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _handleSearch,
                  icon: const Icon(Icons.search),
                  label: const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? const Center(child: Text("No products found."))
                  : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          p.productName.isNotEmpty ? p.productName.substring(0, 1).toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Category: ${p.category}"),
                          Text("Price: \$${p.price.toStringAsFixed(2)} (Tax: ${p.taxRate}%)"),
                          Text("Stock: ${p.stockInfo ?? 'N/A'}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductForm(context, product: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(p.barcodeNo),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}