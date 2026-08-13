class Env {
  // Override with:
  // flutter run --dart-define=RECYTECH_API_BASE_URL=http://<host>:5000/api
  //
  // Defaults to Android emulator localhost. Physical devices and deployed
  // backends should be configured through the dart-define above.
  static const String baseUrl = String.fromEnvironment(
    'RECYTECH_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
}
