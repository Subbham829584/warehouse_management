import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_management/models/app_user.dart';
import 'package:warehouse_management/models/cycle_count.dart';
import 'package:warehouse_management/models/grn.dart';
import 'package:warehouse_management/models/pick_list.dart';

void main() {
  group('GRN & Put-away logic', () {
    test('calculates variance and discrepancy correctly', () {
      const item1 = GrnLineItem(
        productId: 'p1',
        productName: 'Bearing',
        sku: 'SKU-1',
        orderedQty: 100,
        receivedQty: 90,
        discrepancyReason: 'Damaged in transit',
        putAwayBin: 'A-01-S1',
      );

      expect(item1.variance, -10);
      expect(item1.hasDiscrepancy, isTrue);
      expect(item1.discrepancyReason, 'Damaged in transit');
      expect(item1.putAwayBin, 'A-01-S1');
    });

    test('GRN detects item discrepancies across order', () {
      final grn = GoodsReceivedNote(
        id: 'grn_1',
        grnNumber: 'GRN-2026-001',
        poId: 'po_1',
        poNumber: 'PO-100',
        supplierId: 's1',
        supplierName: 'Apex Supplies',
        receivedBy: 'ravi@warehouse.io',
        receivedAt: DateTime.now(),
        items: const [
          GrnLineItem(
            productId: 'p1',
            productName: 'Bearing',
            sku: 'SKU-1',
            orderedQty: 50,
            receivedQty: 50,
          ),
          GrnLineItem(
            productId: 'p2',
            productName: 'Seal',
            sku: 'SKU-2',
            orderedQty: 20,
            receivedQty: 15,
            discrepancyReason: 'Short shipped',
          ),
        ],
      );

      expect(grn.totalOrdered, 70);
      expect(grn.totalReceived, 65);
      expect(grn.hasDiscrepancies, isTrue);
    });
  });

  group('Cycle count & Variance approval', () {
    test('flags items exceeding tolerance threshold', () {
      const item = CycleCountItem(
        productId: 'p1',
        productName: 'Motor',
        sku: 'SKU-M1',
        location: 'A-01-S1',
        abcClass: 'A',
        systemQty: 100,
        countedQty: 92,
        unitCost: 100.0,
      );

      expect(item.variance, -8);
      expect(item.isCounted, isTrue);
      expect(item.hasDiscrepancy, isTrue);
      expect(item.varianceValue, -800.0);
    });

    test('CycleCount tracks total variance and items requiring approval', () {
      final count = CycleCount(
        id: 'cc_1',
        countNumber: 'CC-2026-001',
        createdBy: 'picker@warehouse.io',
        createdAt: DateTime.now(),
        items: const [
          CycleCountItem(
            productId: 'p1',
            productName: 'Motor',
            sku: 'SKU-M1',
            location: 'A-01-S1',
            abcClass: 'A',
            systemQty: 100,
            countedQty: 92,
            unitCost: 100.0,
            reasonCode: VarianceReason.theft,
          ),
        ],
      );

      expect(count.discrepancyItems, 1);
      expect(count.netVarianceValue, -800.0);
      expect(count.requiresApproval, isTrue);
    });
  });

  group('Role-Based Access Control (RBAC)', () {
    test('Picker cannot edit prices or delete catalog products', () {
      expect(Permissions.canDeleteProduct(UserRole.picker), isFalse);
      expect(Permissions.canEditProduct(UserRole.picker), isFalse);
      expect(Permissions.canManageUsers(UserRole.picker), isFalse);
      expect(Permissions.canApproveCycleCount(UserRole.picker), isFalse);
    });

    test('Manager can manage inventory operations but cannot delete products or users', () {
      expect(Permissions.canDeleteProduct(UserRole.manager), isFalse);
      expect(Permissions.canManageUsers(UserRole.manager), isFalse);
      expect(Permissions.canReceiveStock(UserRole.manager), isTrue);
      expect(Permissions.canManagePO(UserRole.manager), isTrue);
      expect(Permissions.canRunCycleCount(UserRole.manager), isTrue);
    });

    test('Admin has unrestricted access', () {
      expect(Permissions.canDeleteProduct(UserRole.admin), isTrue);
      expect(Permissions.canEditProduct(UserRole.admin), isTrue);
      expect(Permissions.canManageUsers(UserRole.admin), isTrue);
      expect(Permissions.canApproveCycleCount(UserRole.admin), isTrue);
    });
  });

  group('Bin-sequenced pick lists', () {
    test('sorts lines by bin code for efficient pick walks', () {
      final pl = PickList(
        id: 'pl_1',
        pickNumber: 'PICK-1',
        orderId: 'ORD-1',
        customerName: 'Customer A',
        assignedTo: 'picker@warehouse.io',
        createdAt: DateTime(2026),
        items: const [
          PickLineItem(productId: '3', productName: 'Item C', sku: 'S3', zone: 'A', binCode: 'A-03-S1', qtyRequired: 2),
          PickLineItem(productId: '1', productName: 'Item A', sku: 'S1', zone: 'A', binCode: 'A-01-S1', qtyRequired: 5),
          PickLineItem(productId: '2', productName: 'Item B', sku: 'S2', zone: 'A', binCode: 'A-02-S2', qtyRequired: 1),
        ],
      );

      final walkOrder = pl.sortedByBin;
      expect(walkOrder[0].binCode, 'A-01-S1');
      expect(walkOrder[1].binCode, 'A-02-S2');
      expect(walkOrder[2].binCode, 'A-03-S1');
    });
  });
}
