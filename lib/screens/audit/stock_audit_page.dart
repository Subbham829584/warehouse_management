import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_audit.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class StockAuditPage extends StatefulWidget {
  const StockAuditPage({super.key});

  @override
  State<StockAuditPage> createState() => _StockAuditPageState();
}

class _StockAuditPageState extends State<StockAuditPage> {
  final _store = EnterpriseStore.instance;
  int _activeAuditIndex = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final audits = _store.audits;
    final scope = AppScope.of(context);

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Cycle Count & Stock Audit'),
      ),
      body: audits.isEmpty
          ? _buildEmptyState(context, scope)
          : Column(
              children: [
                // Audit Selector & Summary
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(audits.length, (i) {
                                  final a = audits[i];
                                  final isSelected = i == _activeAuditIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(a.auditNumber),
                                      selected: isSelected,
                                      selectedColor: ColorPalette.pacificBlue
                                          .withValues(alpha: 0.2),
                                      onSelected: (_) => setState(
                                          () => _activeAuditIndex = i),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _startNewAudit(context, scope),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Audit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAuditStatsBanner(
                        audits[_activeAuditIndex],
                        currency,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Audit Items Count Sheet
                Expanded(
                  child: _buildCountSheet(
                    context,
                    audits[_activeAuditIndex],
                    currency,
                    scope,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: audits.isNotEmpty &&
              audits[_activeAuditIndex].status == AuditStatus.inProgress
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: () =>
                      _reconcileAudit(context, audits[_activeAuditIndex], scope),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text(
                    'Reconcile & Apply Inventory Adjustments',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppScope scope) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorPalette.pacificBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check,
                size: 64,
                color: ColorPalette.pacificBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Cycle Count Audits Initiated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorPalette.timberGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a physical cycle count audit to verify stock counts, calculate variances, and reconcile discrepancies with one click.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _startNewAudit(context, scope),
              style: FilledButton.styleFrom(
                backgroundColor: ColorPalette.pacificBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start New Cycle Count'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditStatsBanner(StockAudit audit, NumberFormat currency) {
    final isCompleted = audit.status == AuditStatus.completed;
    final netVarVal = audit.netFinancialVariance;
    final varColor = netVarVal < 0
        ? Colors.red
        : netVarVal > 0
            ? Colors.green
            : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.aquaHaze,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildStatCol(
            'Auditor',
            audit.auditorEmail.split('@').first,
            Icons.person_outline,
            Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          _buildStatCol(
            'Discrepancies',
            '${audit.totalDiscrepancies} items',
            Icons.warning_amber_rounded,
            audit.totalDiscrepancies > 0 ? Colors.orange.shade800 : Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatCol(
            'Variance Value',
            (netVarVal > 0 ? '+' : '') + currency.format(netVarVal),
            Icons.account_balance_wallet_outlined,
            varColor,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCompleted ? 'COMPLETED' : 'IN PROGRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCountSheet(
    BuildContext context,
    StockAudit audit,
    NumberFormat currency,
    AppScope scope,
  ) {
    final isLocked = audit.status == AuditStatus.completed;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: audit.items.length,
      itemBuilder: (ctx, i) {
        final item = audit.items[i];
        final variance = item.variance;
        Color varBadgeColor;
        String varBadgeText;
        if (variance == 0) {
          varBadgeColor = Colors.green;
          varBadgeText = 'MATCH (0)';
        } else if (variance < 0) {
          varBadgeColor = Colors.red;
          varBadgeText = '$variance (Missing)';
        } else {
          varBadgeColor = Colors.blue;
          varBadgeText = '+$variance (Surplus)';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                          Text(
                            'SKU: ${item.sku} • Loc: ${item.location}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: varBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        varBadgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: varBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Count: ${item.systemQuantity}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        if (variance != 0)
                          Text(
                            'Value Diff: ${(item.varianceValue > 0 ? '+' : '')}${currency.format(item.varianceValue)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: varBadgeColor,
                            ),
                          ),
                      ],
                    ),
                    if (!isLocked) ...[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.grey.shade700,
                            onPressed: item.countedQuantity > 0
                                ? () => _store.updateCountedQuantity(
                                      auditId: audit.id,
                                      productId: item.productId,
                                      countedQty: item.countedQuantity - 1,
                                    )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ColorPalette.aquaHaze,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${item.countedQuantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: ColorPalette.pacificBlue,
                            onPressed: () => _store.updateCountedQuantity(
                              auditId: audit.id,
                              productId: item.productId,
                              countedQty: item.countedQuantity + 1,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Counted: ${item.countedQuantity} pcs',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startNewAudit(BuildContext context, AppScope scope) async {
    final stream = scope.repo.watchProducts();
    final firstList = await stream.first;
    if (firstList.isEmpty) {
      if (context.mounted) {
        showMessage(context, 'No products found in inventory to audit.');
      }
      return;
    }

    _store.startAudit(firstList, scope.userEmail);
    setState(() => _activeAuditIndex = 0);
    if (context.mounted) {
      showMessage(context, 'New Cycle Count Audit initialized!');
    }
  }

  void _reconcileAudit(
    BuildContext context,
    StockAudit audit,
    AppScope scope,
  ) async {
    final disc = audit.totalDiscrepancies;
    final ok = await confirm(
      context,
      title: 'Reconcile Audit ${audit.auditNumber}?',
      message: disc == 0
          ? 'No discrepancies found. This will close the audit record.'
          : 'Found $disc discrepancy(ies). This will update active inventory stock to match your physical count and generate permanent movement logs.',
      confirmLabel: 'Reconcile & Close',
    );
    if (!ok) return;

    try {
      await _store.reconcileAudit(
        auditId: audit.id,
        repo: scope.repo,
        userEmail: scope.userEmail,
      );
      if (context.mounted) {
        showMessage(context,
            'Audit ${audit.auditNumber} reconciled and inventory updated!');
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, 'Reconciliation failed: $e', error: true);
      }
    }
  }
}
