# Revisión de Revela

Fecha: 10 de noviembre de 2026.

Se revisaron los módulos de acceso, sesión, inicio administrativo, portal profesional, clientes, profesionales, servicios, especialidades, reservas, horarios, inasistencias, cierres, comisiones y galería de diseño.

## Correcciones

- Los filtros de profesional, cierre y período también se aplican a los registros recibidos. La galería respeta los mismos filtros.
- Los módulos con vistas específicas dejaron de cargar listados duplicados en segundo plano.
- Al actualizar una pantalla se recargan los datos auxiliares de filtros, lo que permite recuperarse de errores de conexión.
- Editar un cliente permite borrar explícitamente datos opcionales, como el correo, en lugar de conservar accidentalmente el valor anterior.
- La edición de inasistencias recupera el motivo y el rango de fechas guardados.
- Las horas se validan y comparan como horas. Una configuración de días inválida ya no puede romper las pantallas.
- La confirmación de reservas queda protegida frente a pulsaciones repetidas. Las acciones de cancelación y asistencia también protegen sus diálogos.
- El inicio profesional carga el perfil vinculado a su ID y muestra próximas citas futuras. Permite actualizar y reintentar la carga.
- La galería conserva el historial al cancelar reservas y persiste la confirmación de asistencia. Sus consultas entregan copias para evitar cambios involuntarios sobre los ejemplos.
- La galería puede abrir los estados de una reserva después de vaciar su listado, sin fallar por acceder al primer elemento de una lista vacía.
- Se habilitó el arrastre con ratón en las pantallas y se mantuvo accesible el guardado de clientes.
- Se ajustaron los importes, los indicadores de agenda, el selector de días y los títulos de recuperación para pantallas estrechas y texto ampliado.
- Las selecciones usan la paleta de Revela y las confirmaciones de éxito permiten desplazamiento en orientación horizontal.

## Verificación

- Suite completa: **33 pruebas aprobadas**. Incluye pruebas de autenticación, API, roles, formularios, edición, desplazamiento, filtros y persistencia simulada.
- **92 entradas del catálogo renderizadas en tres formatos:** 393 × 852, 320 × 740 con texto ampliado y 740 × 393. Son **276 comprobaciones de renderizado**; los marcos incluyen variantes y versiones anteriores, no 92 páginas independientes.
- Revisión visual de formularios, agenda, comisiones, horarios, servicios personales, detalles, acceso y recuperación.
- Flujos comprobados: crear, editar y eliminar clientes; crear, revisar y cancelar reservas; confirmar asistencia en la galería.
- Análisis de Dart sin diagnósticos y formato comprobado.
- Las pruebas se ejecutaron con el compilador y el motor de Flutter, usando respuestas simuladas. No modificaron registros de la API real.

## Límites que continúan vigentes

La recuperación de contraseña, la confirmación real de asistencia y el registro del pago de reservas necesitan soporte del servidor. El rol y el ID del profesional, los estados de reservas y los códigos de días y motivos requieren los valores confirmados del contrato. La revisión no inventa esas equivalencias ni comunica operaciones reales exitosas desde la galería.

No se realizaron compilaciones nativas de Android/iOS ni pruebas de escritura contra el servidor de producción. Los cambios quedaron guardados en la carpeta local del proyecto.
