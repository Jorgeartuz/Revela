# Cobertura de pantallas y estados

Los componentes reutilizables representan las variantes de formulario, validación, carga, resultados y confirmación del diseño.

| Grupo de Figma | Implementación |
| --- | --- |
| Splash, Inicio Sesión y Error de Acceso | `main.dart`, `login_screen.dart`, `auth_repository.dart` |
| Recuperación, OTP, Nueva contraseña, Contraseña actualizada | `recovery_screen.dart` y galería |
| Home administrativo, Menú y Cerrar sesión | `home_screen.dart` y `ManagementMenuPage` |
| Clientes: listado, formulario, edición, detalle, errores, creado y sin resultados | `Module.customers` con listado, formulario, detalle y confirmación |
| Profesionales: listado, creación, edición, estados, validaciones y confirmaciones | `Module.professionals` |
| Servicios: listado, creación, edición, estado, validaciones y confirmaciones | `Module.services` |
| Especialidades: listado, formulario, detalle, validación y sin resultados | `Module.specialties`; límites de reactivación indicados en README |
| Agenda y reservas: creación, revisión, detalle, edición, cancelación y estados | `Module.reservations`; confirmación de asistencia limitada por el servidor |
| Horario semanal, configuración con/sin almuerzo y error | `Module.schedules` |
| Inasistencias: listado, día, rango, motivos, error y resultado | `Module.absences` |
| Cierres: listado, período, resumen, confirmación, resultado y detalle | `Module.closures` |
| Comisiones: filtros, consolidado, sin resultados y servicios del detalle | `Module.commissions` |
| Profesional: inicio, agenda, servicios, horario, inasistencias y menú | `professional_portal.dart`, consultas limitadas a su ID |

La entrada `main_preview.dart` permite recorrer las pantallas que necesitan contratos del servidor todavía no confirmados. Todas las rutas de esta entrada se identifican como vista previa y usan memoria local.

## Comprobación realizada

- Compilación de las vistas con el frontend de Flutter.
- 99 capturas renderizadas, incluyendo formularios de edición, errores, estados vacíos y vistas estrechas.
- Flujo de cliente: crear, mostrar en listado, editar, mostrar los cambios, confirmar eliminación y actualizar el listado.
- Flujo de reserva: seleccionar cliente/servicio, elegir fecha/hora, revisar, crear, abrir detalle, cancelar con motivo y actualizar el listado.
- 39 comprobaciones aisladas de API y reglas de formularios.
- Las pruebas no escribieron registros en la API real.

La revisión por nodo se encuentra en `FIGMA_INVENTORY.md`. Se renderizaron las 92 entradas del catálogo, cinco variantes estrechas y los dos puntos de entrada de los flujos comprobados. Los marcos históricos y sus estados comparten pantallas del flujo actual.
