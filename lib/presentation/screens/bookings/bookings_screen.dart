import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/models/booking_list_model.dart';

final bookingsProvider = FutureProvider.autoDispose<List<BookingListModel>>((ref) {
  return BookingRepository().getAll();
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Bookings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(bookingsProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_online, size: 64, color: AppTheme.primaryGreen.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No bookings yet', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Use the Mirror View to create bookings', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      final isPaid = b.paymentStatus == 'Paid';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPaid ? AppTheme.primaryGreen.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            child: Text(b.customerName.isNotEmpty ? b.customerName[0] : '?', style: TextStyle(color: isPaid ? AppTheme.primaryGreen : Colors.orange)),
                          ),
                          title: Text(b.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Lane ${b.laneNumber} · ${b.slotTime} · ${b.bookingType}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${b.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Chip(
                                label: Text(isPaid ? 'Paid' : b.paymentStatus, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: isPaid ? AppTheme.primaryGreen : Colors.orange,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
