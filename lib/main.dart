import 'package:flutter/material.dart';
import 'product_model.dart';

import 'package:provider/provider.dart';
import 'product_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider()
        ..loadAllProducts()
        ..loadHistory(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Store Manager',
      themeMode: ThemeMode.system, 
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
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
  final FocusNode _searchFocus = FocusNode();
  bool _showHistory = false;

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

  Future<void> _handleSearch() async {
    final provider = context.read<ProductProvider>();
    String term = _searchController.text.trim();

    if (term.isEmpty) {
      await provider.loadAllProducts();
      return;
    }

    await provider.searchProducts(term);
    await provider.addToHistory(term); // Add to history

    if (provider.products.isEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Not Found"),
          content: const Text("No products found. Add new?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Only pre-fill barcode if it looks like a number
                final isNumeric = double.tryParse(term) != null;
                _showProductForm(context, initialBarcode: isNumeric ? term : null);
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      );
    }
  }

// main.dart içindeki _showProductForm metodunun güncel hali
  void _showProductForm(BuildContext context, {Product? product, String? initialBarcode}) {
    final provider = context.read<ProductProvider>();
    final formKey = GlobalKey<FormState>();

    final List<String> categories = ['Electronics', 'Food', 'Clothes', 'Other'];

    // Barkod otomatik oluşturma
    String finalBarcode = product?.barcodeNo ??
        (initialBarcode ?? DateTime.now().millisecondsSinceEpoch.toString());

    final nameCtrl = TextEditingController(text: product?.productName ?? '');
    final unitPriceCtrl = TextEditingController(text: product?.unitPrice.toString() ?? '');
    final taxCtrl = TextEditingController(text: product?.taxRate.toString() ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockInfo?.toString() ?? '');

    // Manuel kategori girişi için controller
    final otherCategoryCtrl = TextEditingController(
        text: (product != null && !categories.contains(product.category)) ? product.category : ''
    );

    String? selectedCategory = product?.category;
    // Eğer veritabanındaki kategori listede yoksa veya 'Other' ise true yap
    bool isOtherSelected = (product != null && !categories.contains(product.category)) || selectedCategory == 'Other';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(product != null ? 'Edit Product' : 'Add Product'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: finalBarcode,
                      decoration: const InputDecoration(labelText: 'Barcode No (Auto)', filled: true),
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),

                    // Manual Category Entry
                    DropdownButtonFormField<String>(
                      value: categories.contains(selectedCategory) ? selectedCategory : 'Other',
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val;
                          isOtherSelected = (val == 'Other');
                        });
                      },
                    ),

                    if (isOtherSelected) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: otherCategoryCtrl,
                        decoration: const InputDecoration(labelText: 'Write Category Name'),
                        validator: (v) => v!.isEmpty ? 'Enter category name' : null,
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: unitPriceCtrl,
                            decoration: const InputDecoration(labelText: 'Unit Price'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _calculatePrice(unitPriceCtrl, taxCtrl, priceCtrl),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: taxCtrl,
                            decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculatePrice(unitPriceCtrl, taxCtrl, priceCtrl),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Total Price (Auto)', filled: true),
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock Info (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // Kategori belirleme mantığı
                    String categoryToSave = isOtherSelected ? otherCategoryCtrl.text : selectedCategory!;

                    final newProduct = Product(
                      barcodeNo: finalBarcode,
                      productName: nameCtrl.text,
                      category: categoryToSave,
                      unitPrice: double.parse(unitPriceCtrl.text),
                      taxRate: int.parse(taxCtrl.text),
                      price: double.parse(priceCtrl.text),
                      stockInfo: stockCtrl.text.isEmpty ? null : int.parse(stockCtrl.text),
                    );

                    if (product != null) {
                      await provider.updateProduct(newProduct);
                    } else {
                      await provider.addProduct(newProduct);
                    }

                    if (!context.mounted) return; // 'BuildContext across async gaps' uyarısını çözer
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String barcode) {
    final provider = context.read<ProductProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteProduct(barcode);
              if (mounted) {
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully.'),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int? stock) {
    if (stock == null) {
      return const Text("Stock: N/A");
    }

    Color bg;
    String text;

    if (stock == 0) {
      bg = Colors.red.shade100;
      text = "Out of stock";
    } else if (stock < 5) {
      bg = Colors.orange.shade100;
      text = "Low: $stock";
    } else {
      bg = Colors.green.shade100;
      text = "Stock: $stock";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined,
            size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text(
          "No products yet",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Tap + button to add your first product.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _searchFocus.addListener(() {
      setState(() {
        _showHistory =
            _searchFocus.hasFocus && _searchController.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;
    final isLoading = provider.isLoading;

    // const categories = ['All', 'Electronics', 'Food', 'Clothes', 'Other'];


    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Store"),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add Example Data',
            onPressed: () async {
               await provider.seedDatabase();
               if (!mounted) return; // Widget ağaçtan ayrıldıysa işlemi durdur
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Added example products!')),
               );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              provider.sortBy(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'name_asc',
                child: Text('Name A–Z'),
              ),
              PopupMenuItem(
                value: 'name_desc',
                child: Text('Name Z–A'),
              ),
              PopupMenuItem(
                value: 'price_asc',
                child: Text('Price Low–High'),
              ),
              PopupMenuItem(
                value: 'price_desc',
                child: Text('Price High–Low'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      labelText: "Search Name or Barcode",
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () async {
                          _searchController.clear();
                          await provider.clearSearch();
                        },
                      )
                          : null,
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: const Row( // const eklendi
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 18),
                      SizedBox(width: 4),
                      Text("Search"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = provider.categories[index];
                  final isSelected = provider.selectedCategory == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (_) => provider.setCategory(c),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _showHistory
                      ? _buildHistoryList(provider)
                      : RefreshIndicator(
                          onRefresh: provider.loadAllProducts,
                          child: products.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(child: _buildEmptyState(context)),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final p = products[index];

                                    final isSearchedItem =
                                        provider.lastSearchedBarcode !=
                                                null &&
                                            p.barcodeNo ==
                                                provider.lastSearchedBarcode;

                                    return Card(
                                      elevation: 3,
                                      color: isSearchedItem
                                          ? Colors.blue.shade50
                                          : null,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.blue.shade100,
                                          child: Text(
                                            p.productName.isNotEmpty
                                                ? p.productName
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          p.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text("Barcode: ${p.barcodeNo}"),
                                            Text("Category: ${p.category}"),
                                            Text(
                                              "Price: \$${p.price.toStringAsFixed(2)} "
                                              "(Tax: ${p.taxRate}%)",
                                            ),
                                            const SizedBox(height: 4),
                                            _buildStockBadge(p.stockInfo),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _showProductForm(context,
                                                      product: p),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _confirmDelete(p.barcodeNo),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
  Widget _buildHistoryList(ProductProvider provider) {
    if (provider.history.isEmpty) {
      return Center(
        child: Text(
          "No search history",
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextButton(
                onPressed: provider.clearHistoryList,
                child: const Text("Clear"),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final term = provider.history[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(term),
                onTap: () {
                  _searchController.text = term;
                  _handleSearch();
                  _searchFocus.unfocus(); // Close history
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
