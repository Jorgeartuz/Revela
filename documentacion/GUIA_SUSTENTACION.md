# Guía para entender y sustentar Revela

## 1. Qué hace el proyecto

Revela es una aplicación Flutter para administrar un centro de belleza. Permite consultar y gestionar clientes, profesionales, servicios, especialidades, reservas, horarios, inasistencias, cierres y comisiones, según las funciones disponibles en el servidor.

**Flutter** construye las pantallas. **Dart** es el lenguaje del código. La **API** es el servidor que recibe solicitudes y guarda los datos. **Bruno** sirve para probar esas solicitudes; no es la base de datos ni el servidor.

## 2. Cómo están organizadas las carpetas

Se sigue el esquema por tipo de archivo del proyecto `smartbook_app` del profesor. Las carpetas principales usan los nombres del ejemplo:

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

```text
lib/
  main.dart
  main_vista_previa.dart
  aplicacion.dart
  config/
    configuracion_api.dart
    tema_aplicacion.dart
  models/
    login/                       Solicitud, sesión y rol del usuario.
    inicio/                      Reservas y estados.
    gestion/                     Módulos, campos y preparación de datos.
    profesional/                 Perfil y datos relacionados.
  routes/
    rutas_aplicacion.dart
  screens/
    autenticacion/
    inicio/
    gestion/
    profesional/
    vista_previa/
  services/
    remote/
      cliente_api.dart
      servicio_autenticacion.dart
      servicio_inicio.dart
      servicio_gestion.dart
    local/
      datos_ejemplo.dart
  widgets/
    botones/boton_principal.dart
    campos/campo_texto.dart
    campos/campo_contrasena.dart
    gestion/                     Tarjetas, navegación y secciones compartidas.
recursos/                        Iconos, imágenes y fuentes.
documentacion/                   Guías e inventario de pantallas.
test/                            Pruebas automáticas.
```

Para encontrar un cambio, pregunta qué responsabilidad tiene: una interfaz completa va en `screens`; un control reutilizable, en `widgets`; los datos y reglas, en `models`; las solicitudes al servidor, en `services/remote`.

`lib`, `test`, `android`, `ios`, `web`, `main`, `pubspec.yaml` y los métodos de Flutter conservan sus nombres por las convenciones y herramientas del framework. Los nombres del código propio se escriben en español sin tildes.

## 3. Por dónde empezar a leer

1. `lib/main.dart`: prepara Flutter y abre la pantalla de carga inicial.
2. `lib/aplicacion.dart`: decide entre el acceso y una sesión iniciada.
3. `lib/screens/autenticacion/pantalla_inicio_sesion.dart`: recoge usuario y contraseña.
4. `lib/services/remote/servicio_autenticacion.dart`: envía el acceso al servidor.
5. `lib/services/remote/cliente_api.dart`: explica cómo se construye y se procesa una solicitud HTTP.
6. `lib/screens/gestion/pantalla_formulario.dart`: muestra cómo se valida y se guarda un registro.

## 4. Recorrido completo del inicio de sesión

1. La persona escribe sus datos en `PantallaInicioSesion` y pulsa **Iniciar Sesion**.
2. `_iniciarSesion()` valida los campos y activa `_cargando` para evitar envíos repetidos.
3. `ServicioAutenticacion.iniciarSesion()` utiliza `SolicitudInicioSesion.toJson()` para preparar los datos y llama a `POST api/Sesion` mediante `ClienteApi`.
4. `ClienteApi` convierte los datos de Dart a JSON, espera la respuesta y comprueba el código HTTP.
5. `SesionUsuario.fromJson()` convierte la respuesta en un objeto con token, vencimiento, empresa, usuario y rol.
6. La pantalla avisa a `AplicacionRevela` mediante `alIniciarSesion`.
7. `AplicacionRevela` conserva la sesión en memoria, programa su vencimiento y muestra `PantallaInicio`.
8. La política de roles decide qué interfaz corresponde. El servidor también valida los permisos: mostrar una pantalla no reemplaza esa validación.

Si los datos son rechazados, se muestra un mensaje y se permite reintentar. Al salir o vencer la sesión se regresa al acceso.

## 5. Recorrido completo para registrar un cliente

1. `PantallaListado` abre `PantallaFormulario` con `modulo: ModuloGestion.clientes`.
2. `camposFormulario()` indica qué campos debe mostrar: documento, nombres, apellidos, fecha de nacimiento y contacto.
3. Los controladores guardan el texto visible; `_valores` reúne los datos que se preparan para enviar.
4. Al pulsar **Guardar cliente**, `_guardar()` pide al formulario que valide sus campos.
5. `validarCampo()` devuelve `null` cuando el valor es válido, o un mensaje cuando hay un problema.
6. `prepararDatosEnvio()` transforma los valores al formato requerido. Para clientes utiliza `Cliente.fromJson()` y `Cliente.toJson()`; para citas construye `SolicitudReserva`.
7. `ServicioGestion.guardar()` utiliza `POST` para crear y `PUT` cuando recibe el identificador de un registro existente.
8. `ClienteApi` realiza la solicitud con el token de la sesión.
9. Si el servidor acepta la operación, se abre `PantallaOperacionExitosa` y se actualiza el listado al volver.

Ante un error se conservan los datos escritos. Un rechazo no se considera automáticamente un duplicado: para afirmarlo, se comprueba que exista un cliente con el mismo documento.

## 6. Por qué se reutilizan pantallas

`ModuloGestion` identifica cada sección y su ruta. `CampoFormulario` describe una entrada: tipo, etiqueta, obligatoriedad y límites.

Por eso `PantallaFormulario` puede atender distintos módulos sin repetir toda la lógica de validación, guardado y errores. Las diferencias se definen en `campos_formulario.dart` y `datos_para_api.dart`.

Las pantallas con necesidades especiales, como agenda, horario y comisiones, tienen sus vistas de gestión. Los servicios y la navegación del profesional se encuentran en archivos propios. La revisión de datos, el resultado exitoso y las secciones del detalle también están separados.

## 7. Conceptos de Dart y Flutter que debes poder explicar

| Concepto | Explicación en este proyecto |
| --- | --- |
| `class` | Agrupa datos y funciones relacionados. Ejemplo: `SesionUsuario`. |
| `final` | Una variable sólo se asigna una vez. El objeto al que apunta puede ser modificable. |
| `const` | Un valor que Dart puede conocer al compilar. |
| `List` | Una lista; por ejemplo, las reservas del día. |
| `Map<String, dynamic>` | Datos organizados por claves, como un registro JSON de la API. |
| `enum` | Un conjunto de opciones: módulos, roles o tipos de campo. |
| `Future` | Un resultado que estará disponible después, como una respuesta del servidor. |
| `async` / `await` | Permiten esperar ese resultado sin bloquear la interfaz. |
| `try` / `catch` / `finally` | Intentar una operación, atender su error y ejecutar la limpieza final. |
| `null` y `?` | Representan un dato que puede faltar. |
| `_nombre` | Identifica un elemento privado de una biblioteca de Dart. |
| `StatelessWidget` | Un componente que no administra estado mutable propio. |
| `StatefulWidget` y `State` | Un componente y el objeto que administra sus cambios. |
| `initState()` | Se ejecuta al crear el estado; inicia controladores y consultas. |
| `build()` | Describe los widgets de la interfaz. Puede ejecutarse muchas veces. |
| `setState()` | Avisa a Flutter que cambió el estado y debe reconstruir la interfaz. |
| `dispose()` | Libera controladores, conexiones y otros recursos. |
| `mounted` | Indica si el estado todavía pertenece a una pantalla activa. |
| `Navigator` | Abre y cierra pantallas. |
| `FutureBuilder` | Muestra carga, datos o error según el resultado de una consulta. |

Los nombres de estos métodos se mantienen en inglés porque los define Flutter.

## 8. Variables importantes del formulario

| Variable | Para qué sirve |
| --- | --- |
| `_claveFormulario` | Permite pedir la validación de todo el formulario. |
| `_controladores` | Administran el texto de los campos. |
| `_valores` | Contienen los datos que se prepararán para enviar. |
| `_opciones` | Guardan las listas de los selectores. |
| `_cargando` | Indica que se están consultando las opciones iniciales. |
| `_guardando` | Bloquea envíos repetidos y muestra que la operación está en curso. |
| `_hayCambios` | Permite advertir si se intenta salir sin guardar. |
| `_error` | Contiene el mensaje que debe mostrar la pantalla. |
| `_desplazamiento` | Controla el movimiento del contenido del formulario. |

## 9. Qué hace ClienteApi

Los nombres `get`, `post`, `put` y `delete` corresponden a los métodos HTTP:

- `get`: consulta información.
- `post`: crea un registro o inicia una operación.
- `put`: actualiza información existente.
- `delete`: solicita eliminar o cancelar, según la ruta.

Cada llamada une la URL base con una ruta, agrega el token si corresponde, convierte el cuerpo a JSON y procesa la respuesta. `body` significa cuerpo de la solicitud; `statusCode` es el código HTTP.

Ejemplos: `201` indica una creación aceptada, `400` una solicitud rechazada y `401` un problema de autorización. El código concreto y el contrato de cada endpoint determinan cómo interpretar el resultado; un `400` por sí solo no demuestra que un cliente esté duplicado.

Los nombres y claves del JSON, como `accessToken`, `empresaId` o `success`, se conservan tal como los espera la API. Traducir esas cadenas rompería la comunicación.

## 10. Aplicación real y galería de ejemplo

```powershell
flutter run -d chrome
```

Abre la aplicación conectada a la API.

```powershell
flutter run -d chrome -t lib/main_vista_previa.dart
```

Abre la galería. `ServicioGestion.vistaPrevia()` utiliza registros en memoria y no modifica el servidor. Sirve para recorrer las pantallas aunque algunas operaciones reales no estén disponibles.

La recuperación de contraseña, la asistencia real y el registro del pago de reservas dependen de endpoints que todavía no están documentados. Los códigos de días, motivos, estados y el rol profesional necesitan sus valores confirmados. En la sustentación conviene distinguir una pantalla diseñada de una operación real habilitada en el servidor.

## 11. Propuesta de sustentación de cinco minutos

1. **Objetivo:** explicar qué administra Revela y quién la utiliza.
2. **Estructura:** mostrar `config`, `models`, `routes`, `screens`, `services` y `widgets`, comparándolos con el ejemplo del profesor.
3. **Acceso:** seguir el recorrido desde `PantallaInicioSesion` hasta `SolicitudInicioSesion`, `ServicioAutenticacion`, `SesionUsuario` y `AplicacionRevela`.
4. **Clientes:** mostrar el formulario, su validación y el método `guardar` del servicio.
5. **Calidad y alcance:** explicar las pruebas y cuáles operaciones dependen todavía del servidor.

No es necesario memorizar todas las líneas. Sí es importante localizar una función, explicar sus entradas, el resultado que produce y qué ocurre cuando falla.

## 12. Preguntas que pueden hacerte

**¿Por qué hay servicios?** Para que las pantallas no tengan que construir solicitudes HTTP ni interpretar directamente todos los errores del servidor.

**¿Dónde se guarda definitivamente un cliente?** En el servidor de la API. La aplicación conserva valores temporalmente para mostrarlos y enviarlos.

**¿Por qué usar `await`?** Porque una consulta tarda y la interfaz debe seguir respondiendo mientras llega el resultado.

**¿Cómo cambia la interfaz?** Cambian las variables del estado y se llama a `setState`; Flutter vuelve a ejecutar `build`.

**¿Cómo evitas guardar dos veces?** El estado de guardado bloquea el botón y el método comprueba si ya hay una operación en curso.

**¿El token decide por sí solo todos los permisos?** El cliente lo usa para presentar la interfaz y enviarlo en las solicitudes. El servidor debe validar el token y autorizar cada operación.

**¿Qué prueban las pruebas automáticas?** Que se respeten los contratos esperados, las validaciones, los filtros, el acceso por rol y los flujos comprobados. Las pruebas con respuestas simuladas no demuestran por sí solas que una operación de producción funcione en el servidor.

## 13. Comparación del acceso con el ejemplo del profesor

El recorrido es el mismo: **pantalla → modelo de solicitud → servicio → API → modelo de respuesta**.

En Revela, `pantalla_inicio_sesion.dart` recoge los datos; `SolicitudInicioSesion` prepara el JSON; `ServicioAutenticacion` envía la solicitud mediante `ClienteApi`; `SesionUsuario` representa la respuesta con el token y el vencimiento.

`BotonPrincipal`, `CampoTexto` y `CampoContrasena` están en `widgets` y son utilizados por la pantalla de acceso. `CampoContrasena` se encarga de mostrar u ocultar el texto; la pantalla conserva la validación de acceso y la llamada al servicio.

`RutasAplicacion` centraliza recuperación, listados, formularios y detalles y está conectada al `MaterialApp`. Las clases `ArgumentosListado`, `ArgumentosFormulario` y `ArgumentosDetalle` describen qué recibe cada destino. El cambio entre acceso e inicio depende de la sesión en `aplicacion.dart`.

`services/local/datos_ejemplo.dart` prepara los registros de la galería; no guarda una sesión entre ejecuciones. La sesión real continúa en memoria mientras se usa la aplicación.

## 14. Estudiar con las diapositivas

La [guía de metodología de clase](METODOLOGIA_CLASE.md) relaciona el código con las páginas del material de Dart, Flutter y API REST. Empieza por el modelo `Cliente`, sigue la solicitud de acceso y termina con los argumentos de navegación y la creación de una reserva.
