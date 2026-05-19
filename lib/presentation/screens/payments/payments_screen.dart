import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/customer_provider.dart';

final paymentsProvider = FutureProvider.autoDispose<List<PaymentListModel>>((ref) {
  return PaymentRepository().getAll();
});

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  final PaymentRepository _paymentRepo = PaymentRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(customerListProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Payments', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(customerListProvider);
                    ref.invalidate(paymentsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Debtors'),
                Tab(text: 'History'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDebtorsTab(customersAsync),
                  _buildHistoryTab(paymentsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtorsTab(AsyncValue<List> customersAsync) {
    return customersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (customers) {
        final debtors = customers.where((c) => c.currentBalance > 0).toList();
        if (debtors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppTheme.slotAvailable.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No outstanding balances', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: debtors.length,
          itemBuilder: (context, i) {
            final c = debtors[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(c.fullName[0])),
                title: Text(c.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.phone),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (c.currentBalance / 500).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.red,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${c.currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Debt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onTap: () => _showPaymentDialog(context, c),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<PaymentListModel>> paymentsAsync) {
    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No payments recorded yet', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, i) {
            final p = payments[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.paymentStatus == 'Paid' ? AppTheme.primaryGreen.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  child: Text(p.customerName.isNotEmpty ? p.customerName[0] : '?', style: TextStyle(color: p.paymentStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange)),
                ),
                title: Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${p.paymentMethod} · ${DateFormat('MMM d, h:mm a').format(p.createdAt)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Chip(
                      label: Text(p.paymentStatus, style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: p.paymentStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, customer) {
    final amountCtrl = TextEditingController();
    String selectedMethod = 'Cash';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Payment - ${customer.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Balance: \$${customer.currentBalance.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                items: const ['Cash', 'Card', 'Transfer', 'Credit'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setDialogState(() => selectedMethod = v!),
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || amount <= 0) return;
                      setDialogState(() => saving = true);
                      try {
                        await _paymentRepo.create(
                          customerId: customer.id,
                          amount: amount,
                          paymentMethod: selectedMethod,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment recorded'), backgroundColor: Colors.green),
                          );
                          ref.invalidate(customerListProvider);
                          ref.invalidate(paymentsProvider);
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
