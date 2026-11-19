import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/campos_formulario.dart';
import 'package:revela/models/gestion/opcion_seleccion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class CampoGestion extends StatelessWidget {
  const CampoGestion({
    super.key,
    required this.campo,
    required this.valor,
    required this.controlador,
    required this.opciones,
    required this.bloqueado,
    required this.alCambiar,
    required this.alEscribir,
    this.alDesactivar,
  });
  final CampoFormulario campo;
  final Object? valor;
  final TextEditingController controlador;
  final List<OpcionSeleccion> opciones;
  final bool bloqueado;
  final ValueChanged<Object?> alCambiar;
  final ValueChanged<String> alEscribir;
  final VoidCallback? alDesactivar;

  @override
  Widget build(BuildContext context) {
    final f = campo;
    final input = _entradaCampo(context);
    if (f.kind == TipoCampo.interruptor) return input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${f.label}${f.required ? '*' : ''}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        input,
      ],
    );
  }

  Widget _entradaCampo(BuildContext context) {
    final f = campo;
    if (f.kind == TipoCampo.interruptor) {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(f.label),
        value: valor == true,
        onChanged: bloqueado
            ? null
            : (v) {
                if (!v && alDesactivar != null) {
                  alDesactivar!();
                } else {
                  alCambiar(v);
                }
              },
      );
    }
    if (f.opciones != null &&
        ['dia', 'tipoFecha', 'motivoLabel'].contains(f.key)) {
      return FormField<String>(
        initialValue: valor?.toString(),
        validator: (v) => validarCampo(f, v),
        builder: (estado) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in f.opciones!.entries)
                  ChoiceChip(
                    showCheckmark: false,
                    selectedColor: ColoresAplicacion.principal.withValues(
                      alpha: .25,
                    ),
                    label: Text(
                      f.key == 'dia' ? e.value.substring(0, 3) : e.value,
                    ),
                    selected: valor == e.key,
                    onSelected: bloqueado
                        ? null
                        : (_) {
                            estado.didChange(e.key);
                            alCambiar(e.key);
                          },
                  ),
              ],
            ),
            if (estado.hasError)
              Text(
                estado.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    }

    if (f.kind == TipoCampo.seleccion && f.origen != null) {
      final opciones = this.opciones;
      final actual = valor as int?;
      return DropdownButtonFormField<int>(
        key: ValueKey('${f.key}:$actual:${opciones.length}'),
        initialValue: opciones.any((opcion) => opcion.id == actual)
            ? actual
            : null,
        isExpanded: true,
        hint: Text('Seleccionar ${f.label.toLowerCase()}'),
        items: opciones
            .map(
              (opcion) => DropdownMenuItem<int>(
                value: opcion.id,
                child: Text(opcion.nombre, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: bloqueado ? null : (id) => alCambiar(id),
        validator: (id) => validarCampo(f, id),
      );
    }
    if (f.kind == TipoCampo.seleccion) {
      final opciones =
          f.opciones ??
          {for (final opcion in this.opciones) '${opcion.id}': opcion.nombre};
      final current = valor?.toString();
      return DropdownButtonFormField<String>(
        key: ValueKey('${f.key}:$current:${opciones.length}'),
        initialValue: opciones.containsKey(current) ? current : null,
        isExpanded: true,
        hint: Text('Seleccionar ${f.label.toLowerCase()}'),
        decoration: InputDecoration(labelText: null),
        items: [
          for (final e in opciones.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: bloqueado ? null : (valor) => alCambiar(valor),
        validator: (v) => validarCampo(f, v),
      );
    }
    if (f.kind == TipoCampo.fecha || f.kind == TipoCampo.hora) {
      final raw = valor?.toString();
      final display = raw == null
          ? ''
          : f.kind == TipoCampo.fecha
          ? formatoFecha(raw)
          : minutosDeHora(raw) == null
          ? 'Hora no válida'
          : '${(minutosDeHora(raw)! ~/ 60).toString().padLeft(2, '0')}:${(minutosDeHora(raw)! % 60).toString().padLeft(2, '0')}';
      return FormField<String>(
        initialValue: raw,
        validator: (_) => validarCampo(f, valor),
        builder: (estado) => InkWell(
          onTap: bloqueado
              ? null
              : () async {
                  if (f.kind == TipoCampo.fecha) {
                    final datosIniciales =
                        DateTime.tryParse(raw ?? '') ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      initialDate: datosIniciales.isBefore(DateTime(1900))
                          ? DateTime(1900)
                          : datosIniciales.isAfter(DateTime(2100))
                          ? DateTime(2100)
                          : datosIniciales,
                    );
                    if (date != null && context.mounted) {
                      final seleccionado = DateFormat('yyyy-MM-dd')
                          .format(date);
                      alCambiar(seleccionado);
                      estado.didChange(seleccionado);
                    }
                  } else {
                    final minutes = minutosDeHora(raw) ?? 9 * 60;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: minutes ~/ 60,
                        minute: minutes % 60,
                      ),
                    );
                    if (time != null && context.mounted) {
                      final seleccionado =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                      alCambiar(seleccionado);
                      estado.didChange(seleccionado);
                    }
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: null,
              errorText: estado.errorText,
              suffixIcon: Icon(
                f.kind == TipoCampo.fecha
                    ? Icons.calendar_today_outlined
                    : Icons.schedule,
                size: 20,
              ),
            ),
            child: Text(
              display.isEmpty
                  ? (f.kind == TipoCampo.fecha ? 'dd/mm/aaaa' : 'Elegir hora')
                  : display,
              style: TextStyle(
                color: display.isEmpty
                    ? ColoresAplicacion.textoSecundario
                    : ColoresAplicacion.texto,
              ),
            ),
          ),
        ),
      );
    }
    return TextFormField(
      key: ValueKey(f.key),
      controller: controlador,
      enabled: !bloqueado,
      maxLength: f.maxLength,
      maxLines: f.kind == TipoCampo.textoLargo ? 3 : 1,
      keyboardType: f.kind == TipoCampo.entero
          ? TextInputType.number
          : f.kind == TipoCampo.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.kind == TipoCampo.correo
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: null, hintText: f.hint),
      validator: (v) => validarCampo(f, v),
      onChanged: alEscribir,
    );
  }
}
