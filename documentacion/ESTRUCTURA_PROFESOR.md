# Estructura de Revela según el ejemplo del profesor

Referencia revisada: `smartbook_app - Login.zip`, carpeta `smartbook_app/lib`.

| Proyecto del profesor | Revela | Responsabilidad |
| --- | --- | --- |
| `config` | `configuracion` | URL de la API, colores y tema. |
| `models` | `modelos` | Datos y reglas de la aplicación. |
| `routes` | `rutas` | Rutas comunes de navegación. |
| `screens` | `pantallas` | Interfaces completas. |
| `services/remote` | `servicios/remoto` | Consultas y cambios en la API. |
| `services/local` | `servicios/local` | Datos de ejemplo que viven en el dispositivo. |
| `widgets/buttons` | `componentes/botones` | Botón principal reutilizable. |
| `widgets/fields` | `componentes/campos` | Campos de texto y contraseña. |

```text
lib/
  main.dart
  main_vista_previa.dart
  aplicacion.dart
  configuracion/
    configuracion_api.dart
    tema_aplicacion.dart
  modelos/
    login/                       Solicitud, sesión y rol del usuario.
    inicio/                      Reservas y estados.
    gestion/                     Módulos, campos y preparación de datos.
    profesional/                 Perfil y datos relacionados.
  rutas/
    rutas_aplicacion.dart
  pantallas/
    autenticacion/
    inicio/
    gestion/
    profesional/
    vista_previa/
  servicios/
    remoto/
      cliente_api.dart
      servicio_autenticacion.dart
      servicio_inicio.dart
      servicio_gestion.dart
    local/
      datos_ejemplo.dart
  componentes/
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
| `screens/login_screen.dart` | `pantallas/autenticacion/pantalla_inicio_sesion.dart` |
| `models/login/login_request.dart` | `modelos/login/solicitud_inicio_sesion.dart` |
| `models/login/login_response.dart` | `modelos/login/sesion_usuario.dart` |
| `services/remote/login_service.dart` | `servicios/remoto/servicio_autenticacion.dart` |
| `services/remote/api_service.dart` | `servicios/remoto/cliente_api.dart` |
| `routes/app_routes.dart` | `rutas/rutas_aplicacion.dart` |
| `widgets/buttons/primary_button.dart` | `componentes/botones/boton_principal.dart` |
| `widgets/fields/custom_text_field.dart` | `componentes/campos/campo_texto.dart` |
| `widgets/fields/password_field.dart` | `componentes/campos/campo_contrasena.dart` |

La pantalla recoge y valida los datos. El modelo de solicitud los convierte a JSON. El servicio realiza la operación y convierte la respuesta en `SesionUsuario`. La aplicación muestra el inicio correspondiente al rol y gestiona el vencimiento de la sesión.

El ejemplo del profesor también tiene almacenamiento seguro y preferencias. En Revela, la carpeta local contiene los datos de ejemplo y la sesión sigue en memoria. La organización de carpetas no implica haber añadido persistencia de credenciales.

## Encontrar una parte del proyecto

- Cambiar el aspecto de una pantalla: `pantallas`.
- Reutilizar un botón, campo o tarjeta: `componentes`.
- Cambiar URL, colores o fuentes: `configuracion`.
- Consultar el formato de los datos: `modelos`.
- Revisar una solicitud HTTP: `servicios/remoto`.
- Cambiar registros de la galería: `servicios/local`.
- Revisar la ruta común de recuperación: `rutas`.

Los nombres del framework, los métodos HTTP y las claves JSON se conservan como los requieren Flutter y la API.
