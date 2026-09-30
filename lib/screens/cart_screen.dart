import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'order_summary_screen.dart';
import 'order_history_screen.dart';

class CartScreen extends StatefulWidget {
  final CartService cartService;

  const CartScreen({
    super.key,
    required this.cartService,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _busy = false;

  // Open order summary
  Future<void> _checkout() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      final pending = await OrderService().pending();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSummaryScreen(
            cartService: widget.cartService,
            existingOrder: pending,
          ),
        ),
      );

      await widget.cartService.load();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // Show error message
  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Bad state: ', ''),
        ),
      ),
    );
  }

  // Increase quantity
  Future<void> _increase(FoodItem food) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await widget.cartService.increaseQuantity(food);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // Decrease quantity
  Future<void> _decrease(FoodItem food) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await widget.cartService.decreaseQuantity(food);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // Delete food
  Future<void> _delete(FoodItem food) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await widget.cartService.removeFromCart(food);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cartService.cartItems;
    final total = widget.cartService.getTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Order history
          IconButton(
            tooltip: 'Order History',
            icon: const Icon(Icons.history),
            onPressed: _busy
                ? null
                : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderHistoryScreen(
                    cartService: widget.cartService,
                  ),
                ),
              );

              await widget.cartService.load();

              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),

      body: cartItems.isEmpty
          ? const Center(
        child: Text(
          'Your cart is empty',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      )
          : Column(
        children: [
          // Cart items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Food icon
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            size: 32,
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Food details
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.food.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                '₹${item.food.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Quantity controls
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _decrease(
                                      item.food,
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .remove_circle_outline,
                                    ),
                                  ),

                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _increase(
                                      item.food,
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .add_circle_outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Delete button
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _delete(item.food),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom order section
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              15,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                // Total
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Order button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      'Order Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}