class ApiConstants {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String login = '/auth/login';
  static const String customers = '/customers';
  static const String pools = '/pools';
  static const String lanes = '/pools/{poolId}/lanes';
  static const String bookingTypes = '/bookingtypes';
  static const String bookings = '/bookings';
  static const String mirrorView = '/bookings/mirror';
  static const String slotStatus = '/bookings/slot-status';
  static const String pricing = '/pricing/{activityId}';
  static const String payments = '/payments';
  static const String dashboard = '/dashboard';

  static const String hubs = 'http://localhost:5000/hubs/bookings';
}
