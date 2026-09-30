import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/order_record.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'order_confirmation_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final CartService cartService;
  final OrderRecord? existingOrder;
  const OrderSummaryScreen({super.key, required this.cartService, this.existingOrder});
  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _orders = OrderService();
  final _payments = PaymentService();
  late final Razorpay _razorpay;
  OrderRecord? _order;
  bool _busy = false;
  bool _verifying = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _order = widget.existingOrder;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _success);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _failure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _wallet);
  }

  @override
  void dispose() { _razorpay.clear(); super.dispose(); }

  void _error(Object error) {
    if (mounted) setState(() {
      _busy = false;
      _message = error.toString().replaceFirst('Bad state: ', '');
    });
  }

  Future<void> _showConfirmed(OrderRecord order) async {
    await widget.cartService.load();
    if (!mounted) return;
    setState(() { _busy = false; });
    await Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => OrderConfirmationScreen(order: order)));
  }

  Future<bool> _acceptVerified(Map<String, dynamic> response) async {
    final order = _order!;
    if (response['client_order_id'] != order.id ||
        response['amount'] != order.totalPaise || response['currency'] != 'INR' ||
        response['razorpay_order_id'] != order.razorpayOrderId) {
      throw StateError('Order details did not match. Payment has not been confirmed.');
    }
    if (response['state'] != 'paid') return false;
    final paymentId = response['payment_id'];
    if (paymentId is! String || paymentId.isEmpty) throw StateError('Missing payment receipt.');
    final confirmed = await _orders.confirm(order.id, verifiedPaymentId: paymentId);
    await _showConfirmed(confirmed);
    return true;
  }

  Future<void> _cash() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      _order ??= await _orders.create('cod');
      await _showConfirmed(await _orders.confirm(_order!.id));
    } catch (error) { _error(error); }
  }

  Future<void> _pay() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      _payments.checkConfiguration();
      _order ??= await _orders.create('razorpay');
      final prepared = await _payments.prepare(_order!);
      final gatewayId = prepared['razorpay_order_id'];
      final keyId = prepared['key_id'];
      if (prepared['amount'] != _order!.totalPaise || prepared['currency'] != 'INR' ||
          gatewayId is! String || keyId is! String || !keyId.startsWith('rzp_test_')) {
        throw StateError('Payment configuration or order amount did not match.');
      }
      await _orders.attachGateway(_order!.id, gatewayId, keyId);
      _order = await _orders.get(_order!.id);
      final state = _order!.signature == null
        ? await _payments.status(_order!) : await _payments.verify(_order!);
      if (await _acceptVerified(state)) return;
      if (_order!.paymentId != null || state['state'] == 'processing') {
        throw StateError('Payment is being checked. Tap Resume / Check Payment later; do not pay again.');
      }
      if (!mounted) return;
      _razorpay.open({
        'key': keyId, 'order_id': gatewayId,
        'amount': _order!.totalPaise, 'currency': 'INR',
        'name': 'QuickEats', 'description': 'Food order (test mode)',
        'theme': {'color': '#FF9800'},
      });
      // Busy stays true until a plugin callback; back navigation is blocked meanwhile.
    } catch (error) { _error(error); }
  }

  Future<void> _success(PaymentSuccessResponse response) async {
    if (_verifying || _order == null || !mounted) return;
    _verifying = true;
    try {
      if (response.orderId != _order!.razorpayOrderId || response.paymentId == null ||
          response.signature == null) throw StateError('Incomplete payment receipt. Resume to check the order.');
      await _orders.saveReceipt(_order!.id, response.paymentId!, response.signature!);
      _order = await _orders.get(_order!.id);
      final verified = await _payments.verify(_order!);
      if (!await _acceptVerified(verified)) {
        throw StateError('Payment confirmation is pending. Resume to check again.');
      }
    } catch (error) { _error(error); }
    finally { _verifying = false; }
  }

  void _failure(PaymentFailureResponse response) {
    _error(StateError('Payment cancelled or failed. Your cart is saved. Tap Resume / Check Payment to retry.'));
  }
  void _wallet(ExternalWalletResponse response) {
    _error(StateError('Return from the wallet, then tap Resume / Check Payment.'));
  }

  @override
  Widget build(BuildContext context) {
    final lines = _order?.items ?? widget.cartService.cartItems.map((item) => OrderLine(
      foodId: item.food.id, name: item.food.name, pricePaise: item.food.pricePaise,
      quantity: item.quantity)).toList();
    final total = _order?.totalPaise ?? widget.cartService.totalPaise;
    return PopScope(canPop: !_busy, child: Scaffold(
      appBar: AppBar(title: const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ...lines.map((line) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          title: Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${money(line.pricePaise)} × ${line.quantity}'),
          trailing: Text(money(line.totalPaise))))),
        const SizedBox(height: 16),
        Text('Total: ${money(total)}', style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
        const Text('No additional delivery fee or tax in this mini project.'),
        const SizedBox(height: 24),
        if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 16),
          child: Text(_message!, style: const TextStyle(color: Colors.red))),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_order == null || _order!.method == 'cod')
          ElevatedButton(onPressed: _busy || lines.isEmpty ? null : _cash,
            child: const Text('Place Order - Cash on Delivery')),
        if (_order == null || _order!.method == 'razorpay')
          ElevatedButton(onPressed: _busy || lines.isEmpty ? null : _pay,
            child: Text(_order == null ? 'Pay with Razorpay (Test)' : 'Resume / Check Payment')),
        if (_order != null) const Padding(padding: EdgeInsets.only(top: 12),
          child: Text('This order is saved. You can resume it from My Cart or Order History.')),
      ]),
    ));
  }
}
