import 'package:flutter/material.dart';
import '../models/order_record.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderRecord order;
  const OrderConfirmationScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order Confirmation',
      style: TextStyle(fontWeight: FontWeight.bold))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.check_circle, color: Colors.orange, size: 80),
      const SizedBox(height: 16),
      const Text('Order confirmed!', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Text(order.paid ? 'Razorpay test payment verified.' : 'Pay cash when your order arrives.',
        textAlign: TextAlign.center),
      const SizedBox(height: 24),
      SelectableText('Order ID: ${order.id}'),
      Text('Placed: ${DateTime.parse(order.createdAt).toLocal().toString().split('.').first}'),
      if (order.paymentId != null) SelectableText('Payment ID: ${order.paymentId}'),
      const SizedBox(height: 16),
      ...order.items.map((item) => Card(child: ListTile(
        title: Text(item.name),
        subtitle: Text('${money(item.pricePaise)} × ${item.quantity}'),
        trailing: Text(money(item.totalPaise))))),
      const SizedBox(height: 16),
      Text('Total: ${money(order.totalPaise)}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
      Text(order.paid ? 'Payment: Paid (test mode)' : 'Payment: Cash on delivery - unpaid'),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        child: const Text('Back to Menu')),
    ]),
  );
}
