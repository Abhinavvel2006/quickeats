import '../models/food_item.dart';

class FoodService {
  static List<FoodItem> getFoodItems() {
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