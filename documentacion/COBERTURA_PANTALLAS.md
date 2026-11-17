# Cobertura de pantallas y estados

Los componentes reutilizables representan las variantes de formulario, validación, carga, resultados y confirmación del diseño.

| Grupo de Figma | Implementación |
| --- | --- |
| Splash, Inicio Sesión y Error de Acceso | `main.dart`, `pantalla_inicio_sesion.dart`, `servicio_autenticacion.dart` |
| Recuperación, OTP, Nueva contraseña, Contraseña actualizada | `pantalla_recuperacion.dart` y galería |
| Home administrativo, Menú y Cerrar sesión | `pantalla_inicio.dart` y `ManagementMenuPage` |
| Clientes: listado, formulario, edición, detalle, errores, creado y sin resultados | `ModuloGestion.clientes` con listado, formulario, detalle y confirmación |
| Profesionales: listado, creación, edición, estados, validaciones y confirmaciones | `ModuloGestion.profesionales` |
| Servicios: listado, creación, edición, estado, validaciones y confirmaciones | `ModuloGestion.servicios` |
| Especialidades: listado, formulario, detalle, validación y sin resultados | `ModuloGestion.especialidades`; límites de reactivación indicados en README |
| Agenda y reservas: creación, revisión, detalle, edición, cancelación y estados | `ModuloGestion.reservas`; confirmación de asistencia limitada por el servidor |
| Horario semanal, configuración con/sin almuerzo y error | `ModuloGestion.horarios` |
| Inasistencias: listado, día, rango, motivos, error y resultado | `ModuloGestion.inasistencias` |
| Cierres: listado, período, resumen, confirmación, resultado y detalle | `ModuloGestion.cierres` |
| Comisiones: filtros, consolidado, sin resultados y servicios del detalle | `ModuloGestion.comisiones` |
| Profesional: inicio, agenda, servicios, horario, inasistencias y menú | `portal_profesional.dart`, consultas limitadas a su ID |

La entrada `main_vista_previa.dart` permite recorrer las pantallas que necesitan contratos del servidor todavía no confirmados. Todas las rutas de esta entrada se identifican como vista previa y usan memoria local.

## Comprobación realizada

- Compilación de las vistas con el frontend de Flutter.
- 99 capturas renderizadas, incluyendo formularios de edición, errores, estados vacíos y vistas estrechas.
- Flujo de cliente: crear, mostrar en listado, editar, mostrar los cambios, confirmar eliminación y actualizar el listado.
- Flujo de reserva: seleccionar cliente/servicio, elegir fecha/hora, revisar, crear, abrir detalle, cancelar con motivo y actualizar el listado.
- 39 comprobaciones aisladas de API y reglas de formularios.
- Las pruebas no escribieron registros en la API real.

La revisión por nodo se encuentra en `FIGMA_INVENTORY.md`. Se renderizaron las 92 entradas del catálogo, cinco variantes estrechas y los dos puntos de entrada de los flujos comprobados. Los marcos históricos y sus estados comparten pantallas del flujo actual.
