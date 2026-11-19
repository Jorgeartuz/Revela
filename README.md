# Revela

Aplicación Flutter y Dart para administrar un centro de belleza, desarrollada para el curso de Programación y Tecnología Móvil de CECAR.

## Ejecutar

```powershell
flutter pub get
flutter run -d chrome
```

La entrada de la aplicación es `lib/main.dart`.

## Estructura

- `lib/config`: URL de la API y tema.
- `lib/models`: modelos de datos y validaciones.
- `lib/routes`: rutas y navegación.
- `lib/screens`: pantallas de la aplicación.
- `lib/services/remote`: comunicación con la API.
- `lib/services/local`: carpeta reservada para servicios locales.
- `lib/widgets`: componentes de interfaz reutilizables.
- `recursos`: fuentes, iconos e imágenes utilizados por la aplicación.

## API

La aplicación utiliza `https://api.ehily.cecar.cloud`. La dirección se configura en `lib/config/configuracion_api.dart`.

Las credenciales se introducen en el inicio de sesión. El token se conserva en memoria y se envía en las consultas autenticadas.

El acceso profesional requiere confirmar `PROFESSIONAL_ROLE` y `PROFESSIONAL_ID_CLAIM`. Los códigos del servidor se configuran con `WEEKDAY_MAP`, `ABSENCE_HEALTH`, `ABSENCE_FAMILY`, `ABSENCE_OTHER`, `RESERVA_PROGRAMADA`, `RESERVA_CONFIRMADA`, `RESERVA_ATENDIDA` y `RESERVA_CANCELADA` mediante `--dart-define`.

La recuperación automática de contraseña, la confirmación de asistencia, el registro de pagos y la reactivación de especialidades requieren soporte del servidor. La aplicación no simula operaciones exitosas para estas funciones.

El formulario de reservas consulta los horarios reales de la API y permite elegir uno. Las reservas con estado sin identificar no ofrecen edición ni cancelación. Los formularios de horarios e inasistencias indican cuándo falta su configuración.

## Publicar en Android

La ejecución habitual con `flutter run` utiliza la firma de desarrollo. Para generar una versión de publicación se deben definir `REVELA_KEYSTORE_PATH`, `REVELA_KEYSTORE_PASSWORD`, `REVELA_KEY_ALIAS` y `REVELA_KEY_PASSWORD` con una clave de firma propia. Las contraseñas no se guardan en el código.

## Verificar

```powershell
flutter analyze
```
