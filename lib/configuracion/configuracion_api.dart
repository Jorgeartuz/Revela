/// Dirección del servidor que contiene la información de Revela.
/// Puede cambiarse al ejecutar Flutter con --dart-define=API_BASE_URL=otra_url.
abstract final class ConfiguracionApi {
  static const urlBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ehily.cecar.cloud',
  );
}
