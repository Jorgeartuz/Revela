# Estructura de Revela según el ejemplo del profesor

Referencia revisada: `smartbook_app - Login.zip`, carpeta `smartbook_app/lib`.

| Proyecto del profesor | Revela | Responsabilidad |
| --- | --- | --- |
| `config` | `config` | URL de la API, colores y tema. |
| `models` | `models` | Datos y reglas de la aplicación. |
| `routes` | `routes` | Rutas comunes de navegación. |
| `screens` | `screens` | Interfaces completas. |
| `services/remote` | `services/remote` | Consultas y cambios en la API. |
| `services/local` | `services/local` | Datos de ejemplo que viven en el dispositivo. |
| `widgets/buttons` | `widgets/botones` | Botón principal reutilizable. |
| `widgets/fields` | `widgets/campos` | Campos de texto y contraseña. |

```text
lib/
  main.dart
  main_vista_previa.dart
  aplicacion.dart
  config/
    configuracion_api.dart
    tema_aplicacion.dart
  models/
    login/                       Solicitud, sesión y rol del usuario.
    inicio/                      Reservas y estados.
    gestion/                     Módulos, campos y preparación de datos.
    profesional/                 Perfil y datos relacionados.
  routes/
    rutas_aplicacion.dart
  screens/
    autenticacion/
    inicio/
    gestion/
    profesional/
    vista_previa/
  services/
    remote/
      cliente_api.dart
      servicio_autenticacion.dart
      servicio_inicio.dart
      servicio_gestion.dart
    local/
      datos_ejemplo.dart
  widgets/
    botones/boton_principal.dart
    campos/campo_texto.dart
    campos/campo_contrasena.dart
    gestion/                     Tarjetas, navegación y secciones compartidas.
recursos/                        Iconos, imágenes y fuentes.
documentacion/                   Guías e inventario de pantallas.
test/                            Pruebas automáticas.
```

## Cómo explicar un inicio de sesión

| Ejemplo del profesor | Archivo equivalente de Revela |
| --- | --- |
| `screens/login_screen.dart` | `screens/autenticacion/pantalla_inicio_sesion.dart` |
| `models/login/login_request.dart` | `models/login/solicitud_inicio_sesion.dart` |
| `models/login/login_response.dart` | `models/login/sesion_usuario.dart` |
| `services/remote/login_service.dart` | `services/remote/servicio_autenticacion.dart` |
| `services/remote/api_service.dart` | `services/remote/cliente_api.dart` |
| `routes/app_routes.dart` | `routes/rutas_aplicacion.dart` |
| `widgets/buttons/primary_button.dart` | `widgets/botones/boton_principal.dart` |
| `widgets/fields/custom_text_field.dart` | `widgets/campos/campo_texto.dart` |
| `widgets/fields/password_field.dart` | `widgets/campos/campo_contrasena.dart` |

La pantalla recoge y valida los datos. El modelo de solicitud los convierte a JSON. El servicio realiza la operación y convierte la respuesta en `SesionUsuario`. La aplicación muestra el inicio correspondiente al rol y gestiona el vencimiento de la sesión.

El ejemplo del profesor también tiene almacenamiento seguro y preferencias. En Revela, la carpeta local contiene los datos de ejemplo y la sesión sigue en memoria. La organización de carpetas no implica haber añadido persistencia de credenciales.

## Encontrar una parte del proyecto

- Cambiar el aspecto de una pantalla: `screens`.
- Reutilizar un botón, campo o tarjeta: `widgets`.
- Cambiar URL, colores o fuentes: `config`.
- Consultar el formato de los datos: `models`.
- Revisar una solicitud HTTP: `services/remote`.
- Cambiar registros de la galería: `services/local`.
- Revisar rutas de recuperación, listado, formulario y detalle: `routes` y `models/navegacion`.

Los nombres del framework, los métodos HTTP y las claves JSON se conservan como los requieren Flutter y la API.

La aplicación al material de los tres PDF está detallada en [Metodología de clase](METODOLOGIA_CLASE.md).
