import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../models/order_record.dart';
import 'database_service.dart';

class OrderService {
  Future<OrderRecord> _read(DatabaseExecutor db, String id) async {
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Order not found.');
    final lines = await db.query('order_items', where: 'order_id = ?',
      whereArgs: [id], orderBy: 'food_id');
    return OrderRecord.fromMap(rows.first, lines.map(OrderLine.fromMap).toList());
  }

  Future<OrderRecord> get(String id) async =>
    _read(await DatabaseService.instance.database, id);

  Future<List<OrderRecord>> history() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('orders', orderBy: 'created_at DESC');
    final result = <OrderRecord>[];
    for (final row in rows) { result.add(await _read(db, row['id'] as String)); }
    return result;
  }

  Future<OrderRecord?> pending() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('orders', where: 'status = ?',
      whereArgs: ['pending'], limit: 1);
    if (rows.isEmpty) return null;
    return _read(db, rows.first['id'] as String);
  }

  // One active snapshot. Repeated taps and app restarts reuse it.
  Future<OrderRecord> create(String method) async {
    if (!['cod', 'razorpay'].contains(method)) throw ArgumentError('Payment method');
    final db = await DatabaseService.instance.database;
    return db.transaction((tx) async {
      final existing = await tx.query('orders', where: 'status = ?',
        whereArgs: ['pending'], limit: 1);
      if (existing.isNotEmpty) {
        final order = await _read(tx, existing.first['id'] as String);
        if (order.method != method) throw StateError('Resume the pending order first.');
        return order;
      }
      final rows = await tx.rawQuery('''SELECT m.*, c.quantity FROM cart_items c
        JOIN menu_items m ON m.id = c.food_id ORDER BY m.id''');
      if (rows.isEmpty) throw StateError('Your cart is empty.');
      final total = rows.fold<int>(0, (sum, r) =>
        sum + (r['price_paise'] as int) * (r['quantity'] as int));
      final random = Random.secure();
      final id = List.generate(16, (_) => random.nextInt(256)
        .toRadixString(16).padLeft(2, '0')).join();
      await tx.insert('orders', {'id': id, 'created_at': DateTime.now().toUtc().toIso8601String(),
        'total_paise': total, 'method': method, 'status': 'pending'});
      for (final row in rows) {
        await tx.insert('order_items', {'order_id': id, 'food_id': row['id'],
          'name': row['name'], 'price_paise': row['price_paise'], 'quantity': row['quantity']});
      }
      return _read(tx, id);
    });
  }

  Future<void> attachGateway(String id, String gatewayId, String keyId) async {
    final db = await DatabaseService.instance.database;
    await db.update('orders', {'razorpay_order_id': gatewayId, 'key_id': keyId},
      where: 'id = ? AND status = ?', whereArgs: [id, 'pending']);
  }

  Future<void> saveReceipt(String id, String paymentId, String signature) async {
    final db = await DatabaseService.instance.database;
    await db.update('orders', {'payment_id': paymentId, 'signature': signature},
      where: 'id = ? AND status = ?', whereArgs: [id, 'pending']);
  }

  // Called only for COD or after the server verifies a captured Razorpay payment.
  Future<OrderRecord> confirm(String id, {String? verifiedPaymentId}) async {
    final db = await DatabaseService.instance.database;
    return db.transaction((tx) async {
      final order = await _read(tx, id);
      if (order.confirmed) return order;
      if (order.method == 'razorpay' &&
          (verifiedPaymentId == null || verifiedPaymentId.isEmpty)) {
        throw StateError('Payment verification is required.');
      }
      await tx.update('orders', {'status': 'confirmed',
        if (verifiedPaymentId != null) 'payment_id': verifiedPaymentId},
        where: 'id = ?', whereArgs: [id]);
      await tx.delete('cart_items');
      return _read(tx, id);
    });
  }
}
