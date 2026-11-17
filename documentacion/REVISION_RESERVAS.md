# Revisión del registro de citas — 17 de noviembre de 2026

## Fallo reproducido

En una pantalla de 320 × 480, desplazar el formulario hasta Confirmar Reserva podía desmontar los selectores de cliente y servicio. FormState.validate() sólo validaba los controles montados y permitía abrir la confirmación con esos datos faltantes. Una prueba automatizada reprodujo el problema antes de corregirlo.

## Cambios

- El formulario revisa todos los valores activos antes de confirmar, incluidos los campos fuera del área visible. También comprueba que las selecciones existan en las opciones cargadas.
- Los errores de validación y disponibilidad desplazan el contenido hasta el mensaje.
- Una reserva sin fecha u hora válidas devuelve un mensaje comprensible en lugar de una excepción de conversión de tipos.
- Se conserva el motivo legible de una respuesta con success=false, incluso si el código HTTP es 200.
- Los errores del servidor conservan los datos de la cita para permitir reintentar.

## Verificación

- Análisis estático sin observaciones.
- 37 pruebas aprobadas de acceso, sesión, API, roles, formularios, filtros y navegación.
- 283 comprobaciones de vistas completadas con el motor de Flutter. Incluyen el catálogo de diseño en tres tamaños y los flujos de clientes y reservas.

Las pruebas nuevas comprueban campos fuera de pantalla, fecha y hora faltantes, rechazo de una cita, conservación de sus valores, reintento, solicitud JSON y regreso después del resultado exitoso.

Las solicitudes de prueba utilizan MockClient: no registran citas reales ni comprueban la disponibilidad de los profesionales del servidor. La compilación web por el comando habitual encontró una restricción de permisos al lanzar Git desde Flutter en el entorno de herramientas; el análisis y las comprobaciones de interfaz se ejecutaron directamente con las herramientas del SDK y el motor de Flutter.
