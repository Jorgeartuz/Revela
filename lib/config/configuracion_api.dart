abstract final class ConfiguracionApi {
  static const urlBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ehily.cecar.cloud',
  );
}
