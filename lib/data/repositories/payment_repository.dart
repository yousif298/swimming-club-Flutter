import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final ApiClient _client = ApiClient();

  Future<List<PaymentListModel>> getAll() async {
    final response = await _client.get(ApiConstants.payments);
    return (response.data as List).map((e) => PaymentListModel.fromJson(e)).toList();
  }

  Future<void> create({
    required String customerId,
    double amount = 0,
    required String paymentMethod,
    String? notes,
  }) async {
    await _client.post(
      ApiConstants.payments,
      data: {
        'customerId': customerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'Paid',
        'notes': notes,
      },
    );
  }
}
