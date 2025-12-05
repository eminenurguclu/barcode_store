class Product {
  final String barcodeNo;
  final String productName;
  final String category;
  final double unitPrice;
  final int taxRate;
  final double price;
  final int? stockInfo;

  Product({
    required this.barcodeNo,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.taxRate,
    required this.price,
    this.stockInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'BarcodeNo': barcodeNo,
      'ProductName': productName,
      'Category': category,
      'UnitPrice': unitPrice,
      'TaxRate': taxRate,
      'Price': price,
      'Stockinfo': stockInfo,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcodeNo: map['BarcodeNo'],
      productName: map['ProductName'],
      category: map['Category'],
      unitPrice: map['UnitPrice'],
      taxRate: map['TaxRate'],
      price: map['Price'],
      stockInfo: map['Stockinfo'],
    );
  }
}