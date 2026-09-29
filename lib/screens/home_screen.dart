import 'package:flutter/material.dart';

import '../services/food_service.dart';
import '../services/cart_service.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CartService cartService = CartService();

  @override
  Widget build(BuildContext context) {
    final foodItems = FoodService.getFoodItems();

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ---------------- APP BAR ----------------

      appBar: AppBar(
        title: const Text(
          'QuickEats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: false,

        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(
                    cartService: cartService,
                  ),
                ),
              );

              setState(() {});
            },

            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ---------------- BODY ----------------

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          // Greeting
          const Text(
            'What are you craving?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Find your favourite food',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- SEARCH ----------------

          TextField(
            decoration: InputDecoration(
              hintText: 'Search food...',

              prefixIcon: const Icon(
                Icons.search,
              ),

              filled: true,

              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ---------------- CATEGORIES ----------------

          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 100,

            child: ListView(
              scrollDirection: Axis.horizontal,

              children: [
                categoryItem(
                  Icons.lunch_dining,
                  'Burger',
                ),

                categoryItem(
                  Icons.local_pizza,
                  'Pizza',
                ),

                categoryItem(
                  Icons.ramen_dining,
                  'Noodles',
                ),

                categoryItem(
                  Icons.fastfood,
                  'Biryani',
                ),

                categoryItem(
                  Icons.local_dining,
                  'Fries',
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ---------------- POPULAR FOOD ----------------

          const Text(
            'Popular Food',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // ---------------- FOOD CARDS ----------------

          ...foodItems.map(
                (food) {
              return FoodCard(
                food: food,

                onAdd: () {
                  setState(() {
                    cartService.addToCart(food);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${food.name} added to cart',
                      ),

                      duration: const Duration(
                        seconds: 1,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- CATEGORY WIDGET ----------------

  Widget categoryItem(
      IconData icon,
      String name,
      ) {
    return Container(
      width: 85,

      margin: const EdgeInsets.only(
        right: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),

            blurRadius: 5,
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.orange,
          ),

          const SizedBox(height: 8),

          Text(
            name,

            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}