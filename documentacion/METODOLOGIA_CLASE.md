# Revela con la metodología del material de clase

Revisión y adaptación: 18 de noviembre de 2026.

Este documento relaciona el código de Revela con los tres materiales del profesor: **Introducción a Dart**, **Flutter** y **Consumo de APIS REST v2.2**. Los números de página corresponden a los PDF recibidos.

## 1. La idea que organiza el proyecto

El recorrido de una operación es:

**Pantalla → modelo de datos → servicio → petición HTTP → respuesta → actualización de la pantalla.**

- La pantalla recoge las entradas y muestra los resultados.
- El modelo da nombre y tipo a los datos.
- El servicio realiza la operación, por ejemplo guardar un cliente.
- `ClienteApi` envía HTTP y convierte el texto JSON a mapas, o los mapas a texto JSON.
- La pantalla actualiza su estado o recibe el resultado de un `Future`.

Las carpetas siguen el proyecto de ejemplo del profesor, con los nombres de carpetas del ejemplo:

```text
lib/
  main.dart
  aplicacion.dart
  config/                 URL del servidor y tema visual.
  models/
    login/                       Solicitud de acceso, sesión y rol.
    clientes/                    Modelo Cliente.
    reservas/                    Modelo SolicitudReserva.
    inicio/                      Reserva recibida y resumen del día.
    gestion/                     Módulos, campos y opciones de selección.
    navegacion/                  Argumentos de las rutas de gestión.
    profesional/                 Datos del profesional.
  services/
    remote/                      Acceso, consultas y cambios mediante la API.
    local/                       Datos de ejemplo de la galería.
  screens/                     Interfaces completas.
  routes/                         Nombres, argumentos y construcción de rutas.
  widgets/
    botones/                     BotonPrincipal.
    campos/                      CampoTexto y CampoContrasena.
    estructura/                  BarraAplicacion.
    gestion/                     Tarjetas y secciones compartidas.
```

## 2. Correspondencia con las diapositivas

| Concepto de clase | Material y páginas | Aplicación en Revela |
| --- | --- | --- |
| Tipos y valores que pueden ser `null` | Dart, 2 y 15 | Los modelos usan `String`, `int`, `DateTime` y `?` cuando el dato es opcional. |
| Parámetros nombrados y valores por defecto | Dart, 32-34 | Constructores con `required`, por ejemplo `ArgumentosFormulario`. |
| Enumeraciones | Dart, 35-39 | `ModuloGestion`, `RolUsuario` y `TipoCampo`. |
| Clases, objetos y encapsulamiento | Dart, 47-52 | `Cliente`, `SolicitudReserva` y variables privadas que comienzan por `_`. |
| Listas, búsquedas y filtros | Dart, 54-70 | Catálogos, `where`, `firstOrNull`, `any`, ordenamiento y totales. |
| Mapas | Dart, 71-73 | JSON, filtros, valores de formularios y configuración de módulos. |
| Widgets y composición | Flutter, 17-34 | `MaterialApp`, `Scaffold`, `Column`, `Expanded` y componentes propios. |
| Selectores con objetos e ID | Flutter, 62 | `OpcionSeleccion` y `DropdownButtonFormField<int>`. |
| Navegación y argumentos | Flutter, 70-85 | `RutasAplicacion`, `ArgumentosListado`, `ArgumentosFormulario` y `ArgumentosDetalle`. |
| Estado, controladores y ciclo de vida | Flutter, 88-106 | `setState`, `TextEditingController`, `initState` y `dispose`. |
| Componentes reutilizables | Flutter, 122-127 | Botones, campos y `BarraAplicacion`. |
| Listas desplazables | Flutter, 130-135 | Listados y formularios con `ListView`; contenido dentro de `Expanded`. |
| HTTP, URL, cabeceras y estados | API REST, 28-65 | Métodos de `ClienteApi`, token Bearer y tratamiento de errores. |
| JWT y permisos | API REST, 91-102 | `SesionUsuario`, vencimiento y decisión de interfaz por rol. |
| Modelos y JSON | API REST, 104-117 | `fromJson()` y `toJson()` en modelos de acceso y cliente; solicitud tipada de reserva. |
| Servicios y peticiones asíncronas | API REST, 118-128 | `ServicioAutenticacion`, `ServicioGestion` y `ServicioInicio`. |
| Carga, datos y error | API REST, 129-131 | `FutureBuilder` en listados y vistas de consulta. |

## 3. Modelos: de mapa a objeto y de objeto a mapa

Archivo: `lib/models/clientes/cliente.dart`.

```dart
final cliente = Cliente.fromJson({
  'documento': '12345',
  'nombres': 'Laura',
  'apellidos': 'Prueba',
});

final datos = cliente.toJson();
```

`Cliente` reúne propiedades con tipos concretos. `fromJson()` toma un mapa y construye el objeto. `toJson()` devuelve un mapa con las claves que espera el servidor.

Estos métodos trabajan con mapas de Dart. El texto que viaja por la red se obtiene con `jsonEncode`; `jsonDecode` realiza la conversión inversa. Esa conversión se hace en `ClienteApi`.

Los contactos opcionales pueden ser `null`. Al editar, un correo o celular vacío se envía como `null` para poder borrarlo.

Para una cita se utiliza `SolicitudReserva`, en `lib/models/reservas/solicitud_reserva.dart`. Sus propiedades son `fecha`, `servicioId`, `clienteId` y el `profesionalId` opcional al editar. Su `toJson()` prepara el contrato de la API. El modelo `Reserva` de `models/inicio` representa los datos recibidos para consultar y mostrar citas.

## 4. Recorrido que puedes sustentar: registrar un cliente

1. `PantallaListado` abre el formulario con `ModuloGestion.clientes`.
2. `PantallaFormulario` recoge el texto en sus controladores y valores.
3. `_guardar()` valida los datos completos, incluidos los campos que quedaron fuera de pantalla al desplazarse.
4. `prepararDatosEnvio()` construye `Cliente` y obtiene su `toJson()`.
5. `ServicioGestion.guardar()` elige `POST` para crear o `PUT` cuando recibe el ID de un registro existente.
6. `ClienteApi` agrega las cabeceras, codifica el mapa con `jsonEncode` y espera la respuesta.
7. Si la operación se acepta, aparece el resultado y se actualiza el listado al volver. Si se rechaza, se conserva lo escrito y se muestra el error.

El profesor usa un servicio de usuarios como ejemplo. Revela comparte `ServicioGestion` entre varios módulos: `ModuloGestion` indica la ruta y los campos cambian según el módulo. Las responsabilidades siguen separadas entre pantalla, modelos y servicio.

## 5. Recorrido que puedes sustentar: crear una cita

1. Se cargan los clientes y servicios disponibles.
2. Cada opción tiene un ID entero y un nombre visible, mediante `OpcionSeleccion`.
3. Al seleccionar una opción, el formulario conserva su ID. El nombre sólo se muestra en pantalla.
4. Se eligen la fecha y la hora.
5. Se comprueba que los datos sean válidos y la cita esté en el futuro.
6. `SolicitudReserva.toJson()` prepara `fecha`, `clienteId` y `servicioId`.
7. La persona revisa y confirma los datos.
8. El servicio envía `POST api/Reservas` y procesa el resultado.

La API de Revela determina la asignación del profesional al crear una reserva. Al editar, el contrato admite `profesionalId`. Las claves y los tipos enviados siguen el contrato de ese servidor.

## 6. Navegación centralizada y argumentos tipados

Archivos:

- `lib/routes/rutas_aplicacion.dart`.
- `lib/models/navegacion/argumentos_gestion.dart`.

Siguiendo las páginas 80-83 de Flutter, una clase describe los datos que necesita cada destino:

```dart
final argumentos = ArgumentosFormulario(
  modulo: ModuloGestion.clientes,
  servicio: servicio,
);

Navigator.push<bool>(
  context,
  RutasAplicacion.formulario(argumentos),
);
```

Las rutas comunes de listado, formulario y detalle se construyen en un lugar. El resultado `true` indica que hubo cambios y que la pantalla anterior debe actualizarse.

También se admite la navegación nombrada enseñada en clase:

```dart
Navigator.pushNamed<bool>(
  context,
  RutasAplicacion.formularioGestion,
  arguments: argumentos,
);
```

`MaterialApp.onGenerateRoute` llama a `RutasAplicacion.generarRuta()`. Se comprueba el tipo de los argumentos y se construye el destino. Si no corresponden, se muestra una pantalla con un mensaje comprensible.

Las pantallas principales usan las fábricas centralizadas con `Navigator.push`. Los diálogos y vistas particulares pueden seguir usando `MaterialPageRoute` directamente, como la navegación imperativa de la página 73. El acceso y la salida siguen dependiendo de la sesión en `aplicacion.dart`.

## 7. Estado y peticiones asíncronas

`StatefulWidget` tiene un objeto `State` para los valores que cambian. Al modificar esos valores dentro de `setState`, Flutter reconstruye la interfaz. Un `StatelessWidget` recibe datos y no administra estado mutable propio; puede reconstruirse si cambia su padre.

En `PantallaFormulario`:

- `initState()` prepara campos, controladores y consultas iniciales.
- `_cargando` indica que se están obteniendo las opciones.
- `_guardando` bloquea acciones repetidas mientras se guarda.
- `_error` contiene el mensaje que se muestra.
- `dispose()` libera los controladores y el desplazamiento.

`await` espera el resultado de un `Future` sin detener la respuesta de la interfaz. Después de una espera se comprueba `mounted` antes de actualizar una pantalla que pudo cerrarse.

En `PantallaListado`, `_consulta` conserva el `Future` que observa `FutureBuilder`. La consulta se inicia en `initState` o al actualizar; `build` representa los estados de carga, error y datos. Una consulta exitosa sin registros muestra una lista vacía. Un fallo se presenta como error y permite reintentar.

## 8. Componentes reutilizables

- `BotonPrincipal`, en `widgets/botones`: texto, acción y carga. Se utiliza al entrar y al guardar formularios.
- `CampoTexto` y `CampoContrasena`, en `widgets/campos`: entradas que reutilizan configuración y comportamiento.
- `BarraAplicacion`, en `widgets/estructura`: implementa `PreferredSizeWidget` para poder usarse como `Scaffold.appBar`, como en la página 127 de Flutter.

Las pantallas conservan las reglas de sus operaciones. Un botón reutilizable sabe mostrar carga y recibir una acción; el servicio sabe guardar datos.

## 9. Orden recomendado para estudiar

1. `models/clientes/cliente.dart`: atributos, constructor y JSON.
2. `models/login/solicitud_inicio_sesion.dart`: datos de una solicitud sencilla.
3. `services/remote/servicio_autenticacion.dart`: `Future`, `await` y manejo de errores.
4. `screens/autenticacion/pantalla_inicio_sesion.dart`: controladores, validación y `setState`.
5. `widgets/botones/boton_principal.dart`: widget reutilizable.
6. `routes/rutas_aplicacion.dart`: constantes, `switch`, argumentos y destinos.
7. `screens/gestion/pantalla_listado.dart`: consulta conservada y `FutureBuilder`.
8. `models/gestion/datos_para_api.dart` y `services/remote/servicio_gestion.dart`: preparación y envío de datos.

El código propio conserva nombres en español. Flutter, los métodos HTTP y las claves JSON mantienen sus nombres requeridos por las herramientas y el servidor.
