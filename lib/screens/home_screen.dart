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
  bool _loading = true;
  bool _adding = false;
  String? _loadError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      await FoodService.initialize();
      await cartService.load();
    } catch (_) {
      _loadError = 'Could not open local data. Please retry.';
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message), duration: const Duration(seconds: 2)));
  }


  @override
  Widget build(BuildContext context) {
    final foodItems = FoodService.getFoodItems().where((food) =>
      '${food.name} ${food.description}'.toLowerCase().contains(_query));

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
            onPressed: _loading || _loadError != null || _adding ? null : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(
                    cartService: cartService,
                  ),
                ),
              );

              try { await cartService.load(); }
              catch (_) { _message('Could not refresh the saved cart. Please reopen the app.'); }
              if (mounted) setState(() {});
            },

            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ---------------- BODY ----------------

      body: _loading ? const Center(child: CircularProgressIndicator())
          : _loadError != null ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text(_loadError!), TextButton(
                onPressed: _initialize, child: const Text('Retry'))]))
          : ListView(
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
            onChanged: (value) => setState(() { _query = value.trim().toLowerCase(); }),
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

                onAdd: () async {
                  if (_adding) return;
                  setState(() { _adding = true; });
                  try {
                    await cartService.addToCart(food);
                    if (!mounted) return;
                    setState(() {});
                    _message('${food.name} added to cart');
                  } catch (error) {
                    _message(error.toString().replaceFirst('Bad state: ', ''));
                  } finally { if (mounted) setState(() { _adding = false; }); }
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