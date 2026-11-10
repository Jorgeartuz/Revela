# Revela

Aplicación Flutter/Dart para administrar un centro de belleza, basada en el proyecto Figma del curso de Programación y Tecnología Móvil de CECAR.

## Ejecutar la aplicación

```powershell
flutter pub get
flutter run -d chrome
```

También funciona en Flutter Phone Preview, desde la carpeta raíz del proyecto.
Después de estos cambios conviene detener e iniciar la vista previa para recargar todos los recursos.
El inicio de sesión usa el botón único «Iniciar Sesion». Las credenciales se ingresan manualmente; no están incluidas en el código.

## Recorrer las pantallas de diseño

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

En VS Code también se puede seleccionar «Revela · Vista de diseño» en Ejecutar y depurar.
La galería contiene listados, detalles, formularios, edición, estados vacíos y validaciones de los nueve módulos, además de recuperación, perfil profesional y confirmaciones.
Usa datos de ejemplo y no se conecta al servidor. Las operaciones de esa entrada modifican solamente su memoria local.
La vista de OTP utiliza el código de ejemplo `123456`; nunca modifica una contraseña real.

## Pantallas y operaciones

- Splash, acceso real, errores de autenticación y cierre de sesión.
- Inicio administrativo por rol, accesos rápidos y resumen diario.
- Clientes: listado, búsqueda, creación, detalle, edición y eliminación.
- Profesionales: listado, filtros, creación, detalle, edición, estado y accesos a horarios e inasistencias.
- Servicios y especialidades: listado, filtros, formularios, detalle y eliminación. Servicios incluye cambio de estado.
- Reservas: agenda, filtros, nueva reserva, revisión de datos, consulta de disponibilidad, detalle, reagendamiento y cancelación con motivo y confirmación.
- Horarios: listado por profesional, jornada, almuerzo, edición y eliminación.
- Inasistencias: día o rango, motivo, observación, edición y eliminación.
- Cierres: período, revisión, creación, listado, detalle y acceso a comisiones.
- Comisiones: filtros, consolidado por registro y detalle de servicios asociados.
- Profesional: inicio, agenda, servicios/comisiones, horario, inasistencias y menú personal de consulta.
- Recuperación: correo/usuario, OTP, código inválido, nueva contraseña y resultado de ejemplo.

## API y límites conocidos

Base: `https://api.ehily.cecar.cloud`.
Documentación: https://api.ehily.cecar.cloud/swagger/index.html
Diseño: https://www.figma.com/design/bTwBhqV1HM08EjdRs2ikVQ/Proyecto_Revela

Las operaciones disponibles se conectan a los contratos de Swagger. Los formularios validan los datos y muestran el rechazo del servicio antes de informar éxito.
Las pruebas de escritura se ejecutaron con datos simulados, sin crear ni eliminar registros del servidor.

| Función | Estado del contrato |
| --- | --- |
| Acceso de Gestor | Conectado. El token permanece en memoria y se elimina al salir o vencer. |
| Perfil profesional real | Pantallas creadas. Falta confirmar el nombre del rol y el claim con su ID antes de habilitar el acceso. |
| Recuperación / OTP / nueva contraseña | Pantallas creadas y recorrido de ejemplo disponible. Swagger no publica endpoints para efectuar la operación real. |
| Confirmar asistencia | Diálogo creado. El servidor no documenta una ruta para cambiar ese estado; no se envía una solicitud inventada. |
| Estados de reservas | Sus números no tienen equivalencia documentada. Se muestran nombres e indicadores solamente con valores confirmados. |
| Crear horarios | Formulario y contrato creados. Guardar requiere confirmar la equivalencia numérica de los días. Edición de jornadas existentes usa su ID. |
| Guardar inasistencias | Formularios y contrato creados. Requiere confirmar los códigos de los motivos. |
| Reactivar especialidades | La API permite editar el nombre y eliminar; no documenta la reactivación. |
| Medio de pago | La API de reservas no incluye ese dato; no se informa como registrado. |

## Configuración del servidor

La URL base puede sustituirse con `--dart-define=API_BASE_URL=https://servidor`.
Cuando el responsable del servidor confirme los valores, pueden establecerse:

- `PROFESSIONAL_ROLE`: nombre exacto del rol profesional.
- `PROFESSIONAL_ID_CLAIM`: claim del JWT que contiene el ID profesional.
- `WEEKDAY_MAP`: JSON que relaciona domingo/lunes/martes/miercoles/jueves/viernes/sabado con sus códigos confirmados.
- `ABSENCE_HEALTH`, `ABSENCE_FAMILY`, `ABSENCE_OTHER`: códigos confirmados de motivos.
- `RESERVA_PROGRAMADA`, `RESERVA_CONFIRMADA`, `RESERVA_ATENDIDA`, `RESERVA_CANCELADA`: códigos confirmados de estado.

Los valores de demostración se usan exclusivamente en la galería. No se adoptan como contratos reales.

## Verificación

```powershell
flutter analyze
flutter test
```

Se verificaron 39 casos de contratos, permisos, formularios y persistencia simulada.
Se compilaron y renderizaron 64 pantallas/estados con el motor de Flutter, incluyendo anchos de 393 y 320 px.
Se ejecutaron los flujos de crear/editar/eliminar cliente y crear/revisar/cancelar reserva, sin modificar el servidor.
El comando habitual `flutter test` está sujeto a las restricciones de procesos del entorno del asistente; la verificación de renderizado se ejecutó mediante el compilador y el motor de Flutter directamente.

## Organización

`lib/features/auth`: acceso, sesión, splash y recuperación.
`lib/features/home`: inicio administrativo y resumen diario.
`lib/features/management`: módulos, repositorio, formularios, detalles y confirmaciones.
`lib/features/professional`: portal personal de consulta.
`lib/features/preview`: galería independiente con datos de ejemplo.
`lib/core`: tema, configuración y cliente HTTP.
`assets`: recursos locales de Figma y fuentes con sus licencias.

## Revisión completa del archivo Figma

El inventario de los 92 marcos está en `docs/FIGMA_INVENTORY.md`. Incluye variantes y versiones anteriores. En la entrada de diseño, el botón **Ver los 92 marcos de Figma** permite abrir cada equivalente actual por su nombre y nodo. Se añadieron vistas específicas para la agenda, el horario semanal, las inasistencias, los servicios personales y el consolidado de comisiones.
