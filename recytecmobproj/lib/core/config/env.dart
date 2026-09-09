class Env {
  // Override with:
  // flutter run --dart-define=RECYTECH_API_BASE_URL=https://<host>/api
  //
  // Render is the shared authoritative backend. A local override is valid only
  // when it points to a local copy of that same web backend.
  static const String baseUrl = String.fromEnvironment(
    'RECYTECH_API_BASE_URL',
    defaultValue: 'https://recytech-web.onrender.com/api',
  );
}
