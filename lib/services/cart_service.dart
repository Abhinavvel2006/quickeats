import '../models/cart_item.dart';
import '../models/food_item.dart';
import 'database_service.dart';

class CartService {
  final List<CartItem> _cartItems = [];

  // Get cart items
  List<CartItem> get cartItems => _cartItems;

  // Load cart from SQLite database
  Future<void> load() async {
    final db = await DatabaseService.instance.database;

    final rows = await db.rawQuery('''
      SELECT m.*, c.quantity
      FROM cart_items c
      JOIN menu_items m ON m.id = c.food_id
      ORDER BY m.id
    ''');

    _cartItems
      ..clear()
      ..addAll(
        rows.map(
              (row) => CartItem(
            food: FoodItem.fromMap(row),
            quantity: row['quantity'] as int,
          ),
        ),
      );
  }

  // Add food to cart
  Future<void> addToCart(FoodItem food) async {
    final db = await DatabaseService.instance.database;

    final existing = await db.query(
      'cart_items',
      where: 'food_id = ?',
      whereArgs: [food.id],
    );

    if (existing.isEmpty) {
      await db.insert(
        'cart_items',
        {
          'food_id': food.id,
          'quantity': 1,
        },
      );
    } else {
      final currentQuantity = existing.first['quantity'] as int;

      if (currentQuantity < 99) {
        await db.update(
          'cart_items',
          {
            'quantity': currentQuantity + 1,
          },
          where: 'food_id = ?',
          whereArgs: [food.id],
        );
      }
    }

    await load();
  }

  // Increase quantity
  Future<void> increaseQuantity(FoodItem food) async {
    final db = await DatabaseService.instance.database;

    final existing = await db.query(
      'cart_items',
      where: 'food_id = ?',
      whereArgs: [food.id],
    );

    if (existing.isNotEmpty) {
      final currentQuantity = existing.first['quantity'] as int;

      if (currentQuantity < 99) {
        await db.update(
          'cart_items',
          {
            'quantity': currentQuantity + 1,
          },
          where: 'food_id = ?',
          whereArgs: [food.id],
        );
      }
    }

    await load();
  }

  // Decrease quantity
  Future<void> decreaseQuantity(FoodItem food) async {
    final db = await DatabaseService.instance.database;

    final existing = await db.query(
      'cart_items',
      where: 'food_id = ?',
      whereArgs: [food.id],
    );

    if (existing.isNotEmpty) {
      final currentQuantity = existing.first['quantity'] as int;

      if (currentQuantity > 1) {
        await db.update(
          'cart_items',
          {
            'quantity': currentQuantity - 1,
          },
          where: 'food_id = ?',
          whereArgs: [food.id],
        );
      } else {
        await db.delete(
          'cart_items',
          where: 'food_id = ?',
          whereArgs: [food.id],
        );
      }
    }

    await load();
  }

  // Remove item completely
  Future<void> removeFromCart(FoodItem food) async {
    final db = await DatabaseService.instance.database;

    await db.delete(
      'cart_items',
      where: 'food_id = ?',
      whereArgs: [food.id],
    );

    await load();
  }

  // Total in paise
  int get totalPaise {
    int total = 0;

    for (final item in _cartItems) {
      total += item.food.pricePaise * item.quantity;
    }

    return total;
  }

  // Total in rupees
  double getTotal() {
    return totalPaise / 100;
  }

  // Clear cart
  Future<void> clearCart() async {
    final db = await DatabaseService.instance.database;

    await db.delete('cart_items');

    _cartItems.clear();
  }
}