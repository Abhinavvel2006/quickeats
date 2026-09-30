import 'package:flutter/material.dart';
import '../models/order_record.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';
import 'order_summary_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final CartService cartService;
  const OrderHistoryScreen({super.key, required this.cartService});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}
class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<OrderRecord>> _orders;
  @override
  void initState() { super.initState(); _orders = OrderService().history(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold))),
    body: FutureBuilder<List<OrderRecord>>(future: _orders, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: TextButton(
        onPressed: () => setState(() { _orders = OrderService().history(); }),
        child: const Text('Could not load orders. Retry')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.isEmpty) return const Center(child: Text('No orders yet'));
      return ListView(padding: const EdgeInsets.all(16), children: snapshot.data!.map((order) =>
        Card(child: ListTile(
          title: Text('Order ${order.id.substring(0, 8)}'),
          subtitle: Text(order.confirmed
            ? (order.paid ? 'Paid (test mode)' : 'Cash on delivery')
            : 'Pending - tap to resume'),
          trailing: Text(money(order.totalPaise)),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => order.confirmed
              ? OrderConfirmationScreen(order: order)
              : OrderSummaryScreen(cartService: widget.cartService, existingOrder: order)));
            if (mounted) setState(() { _orders = OrderService().history(); });
          },
        ))).toList());
    }),
  );
}
