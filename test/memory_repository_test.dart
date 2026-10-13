import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';
import 'package:warehouse_management/repositories/memory_inventory_repository.dart';

void main() {
  late MemoryInventoryRepository repo;

  setUp(() => repo = MemoryInventoryRepository(seed: false));

  Future<String> addBolt({int qty = 10}) => repo.addProduct(
        Product(
            name: 'Bolt',
            group: 'Hardware',
            quantity: qty,
            sku: 'B1',
            barcode: '123',),
        userEmail: 't@t.com',
      );

  test('groups: no duplicates (case-insensitive)', () async {
    expect(await repo.addGroup('Tools'), isTrue);
    expect(await repo.addGroup('tools'), isFalse);
    expect(await repo.addGroup('   '), isFalse);
    expect(await repo.watchGroups().first, ['Tools']);
  });

  test('cannot delete a group that still has products', () async {
    await repo.addGroup('Hardware');
    await addBolt();
    expect(() => repo.deleteGroup('Hardware'), throwsStateError);
  });

  test('opening stock creates a movement', () async {
    final id = await addBolt(qty: 7);
    final moves = await repo.watchMovements(productId: id).first;
    expect(moves, hasLength(1));
    expect(moves.first.change, 7);
    expect(moves.first.type, MovementType.stockIn);
  });

  test('stock in / out update quantity and log history', () async {
    final id = await addBolt();
    await repo.adjustStock(
        productId: id, type: MovementType.stockIn, amount: 5, userEmail: 'u',);
    await repo.adjustStock(
        productId: id, type: MovementType.stockOut, amount: 8, userEmail: 'u',);
    final p = (await repo.watchProducts().first).single.product;
    expect(p.quantity, 7);
    final moves = await repo.watchMovements(productId: id).first;
    expect(moves.map((m) => m.change), [-8, 5, 10]);
    expect(moves.first.quantityAfter, 7);
  });

  test('stock out beyond available throws and changes nothing', () async {
    final id = await addBolt(qty: 3);
    expect(
      () => repo.adjustStock(
          productId: id,
          type: MovementType.stockOut,
          amount: 4,
          userEmail: 'u',),
      throwsA(isA<InsufficientStockException>()),
    );
    expect((await repo.watchProducts().first).single.product.quantity, 3);
  });

  test('stock take sets the counted quantity', () async {
    final id = await addBolt();
    await repo.adjustStock(
        productId: id,
        type: MovementType.adjustment,
        amount: 4,
        userEmail: 'u',);
    final item = (await repo.watchProducts().first).single;
    expect(item.product.quantity, 4);
    final last = (await repo.watchMovements(productId: id).first).first;
    expect(last.change, -6);
  });

  test('zero / negative stock-in is rejected', () async {
    final id = await addBolt();
    expect(
        () => repo.adjustStock(
            productId: id,
            type: MovementType.stockIn,
            amount: 0,
            userEmail: 'u',),
        throwsArgumentError,);
  });

  test('editing a product never overwrites its quantity', () async {
    final id = await addBolt();
    await repo.updateProduct(id, const Product(name: 'Bolt v2', quantity: 999));
    final p = (await repo.watchProducts().first).single.product;
    expect(p.name, 'Bolt v2');
    expect(p.quantity, 10);
  });

  test('findByCode matches barcode and SKU', () async {
    final id = await addBolt();
    expect((await repo.findByCode('123'))?.id, id);
    expect((await repo.findByCode('B1'))?.id, id);
    expect(await repo.findByCode('nope'), isNull);
    expect(await repo.findByCode(''), isNull);
  });

  test('search is case-insensitive across name/company/sku/barcode', () async {
    await addBolt();
    for (final q in ['BOL', 'b1', '12']) {
      expect(await repo.searchProducts(q).first, hasLength(1), reason: q);
    }
    expect(await repo.searchProducts('zzz').first, isEmpty);
    expect(await repo.searchProducts('bolt', group: 'Other').first, isEmpty);
  });

  test('watchProducts emits updates after a change', () async {
    final stream = repo.watchProducts();
    final expectation = expectLater(
      stream.map((l) => l.length),
      emitsInOrder([0, 1]),
    );
    await Future<void>.delayed(Duration.zero);
    await addBolt();
    await expectation;
  });
}
