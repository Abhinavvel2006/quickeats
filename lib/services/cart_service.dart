import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartService {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(FoodItem food) {
    // Check whether the food is already in the cart
    for (CartItem item in _cartItems) {
      if (item.food.id == food.id) {
        item.quantity++;
        return;
      }
    }

    // If food is not already in cart, add a new CartItem
    _cartItems.add(
      CartItem(
        food: food,
        quantity: 1,
      ),
    );
  }

  void removeFromCart(FoodItem food) {
    _cartItems.removeWhere(
          (item) => item.food.id == food.id,
    );
  }

  double getTotal() {
    double total = 0;

    for (CartItem item in _cartItems) {
      total += item.food.price * item.quantity;
    }

    return total;
  }
}