class SupplierResult {
  final int rank;
  final String storeName;
  final String location;
  final String distance;
  final double price;
  final String unit;
  final double rating;
  final int ratingCount;
  final String stockBadge;
  final bool inStock;
  final bool isBestPrice;

  const SupplierResult({
    required this.rank,
    required this.storeName,
    required this.location,
    required this.distance,
    required this.price,
    required this.unit,
    required this.rating,
    required this.ratingCount,
    required this.stockBadge,
    required this.inStock,
    this.isBestPrice = false,
  });

  String get priceLabel => '৳${price.toStringAsFixed(0)} / $unit';

  double get priceDiffFromBest => price - _bestPrice;

  static const double _bestPrice = 64;

  String get diffLabel =>
      priceDiffFromBest == 0 ? '' : '+৳${priceDiffFromBest.toStringAsFixed(0)} vs best';

  static List<SupplierResult> mockForProduct(String product) {
    return const [
      SupplierResult(
        rank: 1,
        storeName: 'Manik Wholesale',
        location: 'Mirpur-10',
        distance: '1.4 km',
        price: 64,
        unit: 'kg',
        rating: 4.8,
        ratingCount: 120,
        stockBadge: 'In stock',
        inStock: true,
        isBestPrice: true,
      ),
      SupplierResult(
        rank: 2,
        storeName: 'New Bazar Store',
        location: 'Kazipara',
        distance: '2.3 km',
        price: 67,
        unit: 'kg',
        rating: 4.6,
        ratingCount: 85,
        stockBadge: 'In stock',
        inStock: true,
      ),
      SupplierResult(
        rank: 3,
        storeName: 'Alauddin Traders',
        location: 'Shewrapara',
        distance: '3.1 km',
        price: 69,
        unit: 'kg',
        rating: 4.5,
        ratingCount: 64,
        stockBadge: '2 left',
        inStock: true,
      ),
      SupplierResult(
        rank: 4,
        storeName: 'Khan Brothers',
        location: 'Kafrul',
        distance: '3.8 km',
        price: 71,
        unit: 'kg',
        rating: 4.4,
        ratingCount: 41,
        stockBadge: 'In stock',
        inStock: true,
      ),
    ];
  }

  @override
  String toString() => 'SupplierResult($rank, $storeName, ৳$price)';
}