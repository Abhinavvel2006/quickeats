import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  Future<Database>? _opening;
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    try {
      return await openDatabase(
        join(await getDatabasesPath(), 'quickeats.db'), version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE menu_items (
            id INTEGER PRIMARY KEY, name TEXT NOT NULL,
            description TEXT NOT NULL,
            price_paise INTEGER NOT NULL CHECK(price_paise > 0))''');
          await db.execute('''CREATE TABLE cart_items (
            food_id INTEGER PRIMARY KEY REFERENCES menu_items(id),
            quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 99))''');
          await db.execute('''CREATE TABLE orders (
            id TEXT PRIMARY KEY, created_at TEXT NOT NULL,
            total_paise INTEGER NOT NULL CHECK(total_paise > 0),
            method TEXT NOT NULL, status TEXT NOT NULL,
            razorpay_order_id TEXT UNIQUE, key_id TEXT,
            payment_id TEXT UNIQUE, signature TEXT)''');
          await db.execute('''CREATE TABLE order_items (
            order_id TEXT NOT NULL REFERENCES orders(id),
            food_id INTEGER NOT NULL, name TEXT NOT NULL,
            price_paise INTEGER NOT NULL CHECK(price_paise > 0),
            quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 99),
            PRIMARY KEY(order_id, food_id))''');
        },
      );
    } catch (_) { _opening = null; rethrow; }
  }
}
