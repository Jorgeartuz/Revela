# Revela

Aplicación Flutter/Dart del curso de Programación y Tecnología Móvil de CECAR.
Gestión administrativa de un centro de belleza.

## Primera implementación

- Proyecto generado para Android, iOS y web.
- Inicio de sesión basado en Figma, nodo `7:9`, con logo, iconos y fuentes locales.
- Validación de campos, visibilidad de contraseña y controles accesibles.
- Tema oscuro compartido y textos en español.
- Cliente HTTP con tiempo límite y manejo de errores, preparado para un contrato de API real.

Los botones de acceso y recuperación muestran un aviso de conexión pendiente.
Todavía no autentican ni almacenan credenciales. No se han supuesto endpoints.
Las barras del sistema las dibuja el sistema operativo, no una imagen del prototipo.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome
```

Para Android, conectar un dispositivo o iniciar un emulador y ejecutar `flutter run`.
iOS requiere macOS y Xcode para compilar.

## Verificar

```sh
flutter analyze
flutter test
```

## Organización

`lib/core/theme`: colores y tema compartido.
`lib/core/network`: cliente de API.
`lib/features/auth/presentation`: formulario de acceso.
`assets`: recursos originales de Figma y fuentes con sus licencias.

## Siguiente etapa

Incorporar la colección de Bruno o documentación de API para confirmar URL base,
rutas, cuerpos, respuestas y autenticación. Después conectar el acceso por rol
y desarrollar inicio, agenda, catálogos, horarios, cierres y comisiones.

Diseño: https://www.figma.com/design/bTwBhqV1HM08EjdRs2ikVQ/Proyecto_Revela

## Estado de verificación inicial

Dependencias resueltas y código formateado. Análisis estático completado sin diagnósticos mediante el servidor de análisis de Dart.
Las pruebas se intentaron, pero el entorno de este chat bloqueó el lanzamiento de procesos auxiliares de Flutter (Acceso denegado). No se ha verificado todavía la ejecución visual ni la compilación para dispositivos.
