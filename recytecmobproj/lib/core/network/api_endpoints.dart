class ApiEndpoints {
  // auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyPin = '/auth/verify-pin';
  static const String resetPassword = '/auth/reset-password';
  static const String publicBins = '/public/bins';
  static const String partnerBins = '/partner/bins';
  static String partnerBinById(String id) => '/partner/bins/$id';
  static const String partnerCollectionRequests =
      '/partner/collection-requests';
  static String partnerCollectionRequestById(String id) =>
      '/partner/collection-requests/$id';
  static const String collectorQueue = '/collector/queue';
  static const String collectorCurrentJob = '/collector/current-job';
  static String collectorCollectionRequestById(String id) =>
      '/collector/collection-requests/$id';
  static String startCollectionRequest(String id) =>
      '/collector/collection-requests/$id/start';
  static String completeCollectionRequest(String id) =>
      '/collector/collection-requests/$id/complete';
  static const String startNextCollection = '/collector/queue/start-next';
  static const String collectorHistory = '/collector/history';
  static const String collectorCollectionReports =
      '/collector/collection-reports';
  static String collectorCollectionReportById(String id) =>
      '/collector/collection-reports/$id';
  static const String householdDropOffs = '/household/drop-offs';
  static const String validateBinQr = '/household/drop-offs/validate-bin-qr';
  static String householdDropOffById(String id) => '/household/drop-offs/$id';
  static const String householdPoints = '/household/points';
  static const String householdRewards = '/household/rewards';
  static String redeemHouseholdReward(String id) =>
      '/household/rewards/$id/redeem';
  static const String householdRewardRedemptions =
      '/household/reward-redemptions';
  static const String partnerRewards = '/partner/rewards';
  static String partnerRewardById(String id) => '/partner/rewards/$id';
  static const String partnerRewardRedemptions = '/partner/reward-redemptions';
  static String fulfillPartnerRedemption(String id) =>
      '/partner/reward-redemptions/$id/fulfill';
  static String cancelPartnerRedemption(String id) =>
      '/partner/reward-redemptions/$id/cancel';

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
