class FoodItem {
  final int id;
  final String name;
  final String description;
  final double price;

  int get pricePaise => (price * 100).round();

  factory FoodItem.fromMap(Map<String, Object?> row) => FoodItem(
    id: row['id'] as int,
    name: row['name'] as String,
    description: row['description'] as String,
    price: (row['price_paise'] as int) / 100,
  );

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}
