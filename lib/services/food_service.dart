import '../models/food_item.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class FoodService {
  static List<FoodItem> _foods = [];
  static List<FoodItem> getFoodItems() => List.unmodifiable(_foods);

  static Future<void> initialize() async {
    final db = await DatabaseService.instance.database;
    await db.transaction((tx) async {
      for (final food in _seedItems()) {
        await tx.insert('menu_items', {
          'id': food.id, 'name': food.name,
          'description': food.description, 'price_paise': food.pricePaise,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
    _foods = (await db.query('menu_items', orderBy: 'id'))
      .map(FoodItem.fromMap).toList();
  }

  static List<FoodItem> _seedItems() {
    return [
      FoodItem(
        id: 1,
        name: 'Chicken Burger',
        description: 'Juicy chicken burger with fresh vegetables',
        price: 120,
      ),

      FoodItem(
        id: 2,
        name: 'Cheese Pizza',
        description: 'Hot and cheesy vegetable pizza',
        price: 180,
      ),

      FoodItem(
        id: 3,
        name: 'Chicken Biryani',
        description: 'Aromatic basmati rice with chicken',
        price: 200,
      ),

      FoodItem(
        id: 4,
        name: 'French Fries',
        description: 'Crispy golden potato fries',
        price: 80,
      ),

      FoodItem(
        id: 5,
        name: 'Chicken Noodles',
        description: 'Stir-fried noodles with chicken',
        price: 150,
      ),

      FoodItem(
        id: 6,
        name: 'Veg Sandwich',
        description: 'Fresh vegetables with toasted bread',
        price: 100,
      ),
    ];
  }
}
