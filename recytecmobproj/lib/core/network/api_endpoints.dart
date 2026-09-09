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
  static const String binLocations = '/bin-locations';
  static String publicBinByQrCode(String qrCode) =>
      '/bin-locations/public/qr/${Uri.encodeComponent(qrCode)}';
  static const String partnerBins = '/partner/bins';
  static String partnerBinById(String id) => '/partner/bins/$id';
  static const String partnerCollectionRequests =
      '/partner/collection-requests';
  static String partnerCollectionRequestById(String id) =>
      '/partner/collection-requests/$id';
  static const String partnerOrganizationMe = '/partner-organizations/me';
  static const String partnerOrganizationBins =
      '/partner-organizations/my-bins';
  static const String partnerOrganizationStats = '/partner-organizations/stats';
  static const String sensorReports = '/sensor-reports';
  static const String sensorReportsMyReports = '/sensor-reports/my-reports';
  static String partnerOrganizationBinStatus(String id) =>
      '/partner-organizations/bins/$id/status';
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
  static const String collectorsMe = '/collectors/me';
  static const String collectorsStatus = '/collectors/status';
  static const String collectorsJobs = '/collectors/jobs';
  static const String collectorsStats = '/collectors/stats';
  static String collectorCollectionReportById(String id) =>
      '/collector/collection-reports/$id';
  static const String binDropoffs = '/bin-dropoffs';
  static const String publicBinDropoffs = '/bin-dropoffs/public';
  static String binDropoffById(String id) =>
      '/bin-dropoffs/${Uri.encodeComponent(id)}';
  static String validateBinDropoff(String id) =>
      '/bin-dropoffs/${Uri.encodeComponent(id)}/validate';
  static const String rewardPoints = '/reward-points';
  static String rewardPointById(String id) =>
      '/reward-points/${Uri.encodeComponent(id)}';
  static const String userProfile = '/users/profile';
  static const String changePassword = '/users/change-password';

  // requests
  static const String requests = '/requests';
  static const String myRequests = '/requests/me';
  static String requestById(String id) => '/requests/$id';
  static String completeRequest(String id) => '/requests/$id/complete';
  static String requestPayout(String id) => '/requests/$id/payout';
  static String confirmDropoff(String id) => '/requests/$id/dropoff-confirmed';
  static String releasePayout(String id) => '/requests/$id/release-payout';
  static const String pendingPayouts = '/requests/pending-payouts';
  static const String activeWasteCategories =
      '/exchange-rates/active-categories';
  static const String myTransactions = '/transactions/my';

  // contributions
  static const String contributions = '/contributions';

  // centers (optional)
  static const String centers = '/centers';

  // notifications (optional)
  static const String notifications = '/notifications';
}
