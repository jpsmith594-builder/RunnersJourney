/// Build-time configuration. Values come from `--dart-define-from-file=env.json`
/// (see env.example.json). Never hard-code keys in source.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Optional MapTiler key for a nicer map style; without it a free default map is used.
  static const mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
  static const mapStyle =
      String.fromEnvironment('MAP_STYLE', defaultValue: 'outdoor-v2');

  /// RevenueCat public SDK key (Android) for subscriptions. Optional while testing.
  static const revenueCatKey = String.fromEnvironment('REVENUECAT_KEY');

  /// Optional links shown in Settings (hidden while empty).
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
