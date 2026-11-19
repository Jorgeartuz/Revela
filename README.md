# Revela

Aplicación Flutter y Dart para administrar un centro de belleza. Proyecto del curso de Programación y Tecnología Móvil de CECAR.

## Empezar a entender el código

La [guía de sustentación](documentacion/GUIA_SUSTENTACION.md) explica la estructura, los archivos principales y el recorrido completo del acceso y del registro de clientes. Incluye conceptos de Dart y Flutter y preguntas de práctica.

Las carpetas principales de lib siguen el ejemplo del profesor: config, models, routes, screens, services y widgets. Los archivos y nombres propios del código conservan el español. Se conservaron los nombres de Flutter, de los métodos HTTP y de las claves JSON que exige el servidor.

## Metodología de clase

La adaptación al material de Dart, Flutter y API REST está explicada en [METODOLOGIA_CLASE.md](documentacion/METODOLOGIA_CLASE.md), con referencias a las páginas de los PDF y ejemplos reales de Revela. Incluye modelos `fromJson`/`toJson`, servicios asíncronos, selectores con ID entero, argumentos de navegación y componentes reutilizables.

## Ejecutar

Desde la carpeta del proyecto:

```powershell
flutter pub get
flutter run -d chrome
```

Para recorrer las pantallas con datos locales de ejemplo:

```powershell
flutter run -d chrome -t lib/main_vista_previa.dart
```

En VS Code están las configuraciones «Revela · Aplicación» y «Revela · Vista de diseño».
Después del cambio de estructura hay que detener la ejecución anterior e iniciarla de nuevo para que Flutter cargue todos los imports y recursos nuevos.

## Organización

Revela sigue la organización por tipo de archivo del ejemplo `smartbook_app` del profesor, con los nombres de carpetas del ejemplo:

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

Las pantallas y los modelos se agrupan por tema dentro de su carpeta. El acceso usa `SolicitudInicioSesion`, `ServicioAutenticacion`, `SesionUsuario` y los componentes de botón y campos.

Ver [comparación con el proyecto del profesor](documentacion/ESTRUCTURA_PROFESOR.md) y [guía de sustentación](documentacion/GUIA_SUSTENTACION.md).

## API

La URL está en `lib/config/configuracion_api.dart`. Puede sustituirse al ejecutar Flutter:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://servidor
```

- Base actual: `https://api.ehily.cecar.cloud`.
- [Documentación del servidor](https://api.ehily.cecar.cloud/swagger/index.html).
- [Diseño del proyecto](https://www.figma.com/design/bTwBhqV1HM08EjdRs2ikVQ/Proyecto_Revela).

`ServicioAutenticacion` envía el acceso y crea `SesionUsuario`. `ServicioGestion` usa la sesión para operar sobre los módulos. `ClienteApi` es el único responsable de la comunicación HTTP.

Las credenciales se escriben manualmente y el token se conserva en memoria. Las pruebas utilizan respuestas simuladas.

## Vista previa y límites del servidor

`ServicioGestion.vistaPrevia()` utiliza memoria local y no escribe en el servidor. El catálogo tiene 92 entradas, incluidas variantes, diálogos y versiones anteriores; no son 92 páginas independientes. El OTP de ejemplo es `123456`.

| Función | Situación |
| --- | --- |
| Acceso Gestor | Conectado a la API. |
| Recuperación y cambio de contraseña | Pantallas disponibles; faltan endpoints para la operación real. |
| Confirmación de asistencia | Funciona en la galería; falta una ruta documentada para el servidor real. |
| Rol e ID del profesional | Requieren el nombre del rol y el claim confirmados del servidor. |
| Días, motivos y estados | Requieren sus códigos confirmados. Los ejemplos no se adoptan como contrato real. |
| Reactivar especialidades | La API no documenta esta operación. |
| Medio de pago de reservas | La API no incluye este campo. |

Cuando el responsable del servidor los confirme, pueden configurarse `PROFESSIONAL_ROLE`, `PROFESSIONAL_ID_CLAIM`, `WEEKDAY_MAP`, `ABSENCE_HEALTH`, `ABSENCE_FAMILY`, `ABSENCE_OTHER`, `RESERVA_PROGRAMADA`, `RESERVA_CONFIRMADA`, `RESERVA_ATENDIDA` y `RESERVA_CANCELADA` mediante `--dart-define`.

## Verificar

```powershell
flutter analyze
flutter test
```

La suite comprende 60 pruebas de acceso, sesión, formularios, filtros y flujos de gestión. También se han comprobado las pantallas mediante el motor de Flutter, con datos de ejemplo y distintos tamaños. Las pruebas no modifican registros de producción.

Más información: [inventario de Figma](documentacion/INVENTARIO_FIGMA.md), [cobertura de pantallas](documentacion/COBERTURA_PANTALLAS.md) y [revisión de código](documentacion/REVISION_CODIGO.md).
