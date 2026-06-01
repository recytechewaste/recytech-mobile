class ApiEndpoints {
  // auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyPin = '/auth/verify-pin';
  static const String resetPassword = '/auth/reset-password';

  // requests
  static const String requests = '/requests';
  static const String myRequests = '/requests/me';
  static String requestById(String id) => '/requests/$id';
  static String requestPayout(String id) => '/requests/$id/payout';
  static String confirmDropoff(String id) => '/requests/$id/dropoff-confirmed';
  static String releasePayout(String id) => '/requests/$id/release-payout';
  static const String pendingPayouts = '/requests/pending-payouts';
  static const String activeWasteCategories =
      '/exchange-rates/active-categories';
  static const String myTransactions = '/transactions/me';

  // contributions
  static const String contributions = '/contributions';

  // centers (optional)
  static const String centers = '/centers';

  // notifications (optional)
  static const String notifications = '/notifications';
}
