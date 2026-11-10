import 'package:flutter/material.dart';

import 'figma_catalog.dart';

import '../management/domain/module.dart';
import '../management/data/management_repository.dart';
import '../management/data/preview_data.dart';
import '../management/presentation/module_list.dart';
import '../management/presentation/record_form.dart';
import '../management/presentation/record_detail.dart';
import '../management/presentation/shared.dart';
import '../auth/presentation/recovery_screen.dart';
import '../professional/presentation/professional_portal.dart';

class DesignGallery extends StatefulWidget {
  const DesignGallery({super.key});
  @override
  State<DesignGallery> createState() => _DesignGalleryState();
}

class _DesignGalleryState extends State<DesignGallery> {
  final repo = ManagementRepository.preview();
  Map<String, dynamic> _example(Module module) {
    if (repo.memory[module]!.isEmpty) {
      repo.memory[module]!.add(previewData()[module]!.first);
    }
    return Map<String, dynamic>.from(repo.memory[module]!.first);
  }

  void _open(Widget page) => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Pantallas de Revela',
    preview: true,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        infoBox(
          'Esta entrada contiene datos de ejemplo. Ninguna acción modifica registros ni cuentas del servidor.',
        ),
        FilledButton.icon(
          onPressed: () => _open(const FigmaCatalog()),
          icon: const Icon(Icons.grid_view),
          label: const Text('Ver los 92 marcos de Figma'),
        ),
        const SizedBox(height: 16),
        section('MÓDULOS ADMINISTRATIVOS'),
        for (final module in Module.values)
          ExpansionTile(
            title: Text(module.title),
            children: [
              ListTile(
                title: const Text('Listado, búsqueda y filtros'),
                onTap: () =>
                    _open(ModuleListPage(module: module, repository: repo)),
              ),
              if (module.canCreate)
                ListTile(
                  title: Text('Crear ${module.singular.toLowerCase()}'),
                  onTap: () =>
                      _open(RecordFormPage(module: module, repository: repo)),
                ),
              ListTile(
                title: const Text('Detalle y acciones'),
                onTap: () => _open(
                  RecordDetailPage(
                    module: module,
                    row: _example(module),
                    repository: repo,
                  ),
                ),
              ),
              if (module.canEdit)
                ListTile(
                  title: const Text('Formulario de edición'),
                  onTap: () => _open(
                    RecordFormPage(
                      module: module,
                      repository: repo,
                      initial: _example(module),
                      editing: true,
                    ),
                  ),
                ),
              ListTile(
                title: const Text('Estado sin resultados'),
                onTap: () => _open(
                  ModuleListPage(
                    module: module,
                    repository: repo,
                    initialFilters: const {'previewEmpty': '1'},
                  ),
                ),
              ),
              if (module.canCreate)
                ListTile(
                  title: const Text('Errores de validación'),
                  onTap: () => _open(
                    RecordFormPage(
                      module: module,
                      repository: repo,
                      showErrors: true,
                    ),
                  ),
                ),
            ],
          ),
        section('ACCESO Y RECUPERACIÓN'),
        ListTile(
          title: const Text('Splash'),
          onTap: () => _open(
            SplashGate(
              child: Scaffold(
                appBar: AppBar(title: const Text('Splash completado')),
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final stage in {
          0: 'Recuperar acceso',
          1: 'Verificación OTP y código inválido',
          2: 'Nueva contraseña y validación',
          3: 'Contraseña actualizada (ejemplo)',
        }.entries)
          ListTile(
            title: Text(stage.value),
            onTap: () =>
                _open(RecoveryScreen(preview: true, initialStage: stage.key)),
          ),
        section('PERFIL PROFESIONAL'),
        ListTile(
          title: const Text(
            'Inicio, agenda, servicios, horario e inasistencias',
          ),
          onTap: () => _open(
            ProfessionalPortal(
              repository: repo,
              professionalId: 1,
              username: 'Camilo',
              onLogout: () => Navigator.pop(context),
            ),
          ),
        ),
        section('ESTADOS Y CONFIRMACIONES'),
        ListTile(
          title: const Text('Operación exitosa'),
          onTap: () => _open(
            const OperationSuccessPage(
              title: 'Registro guardado',
              message: 'Ejemplo visual de operación exitosa.',
            ),
          ),
        ),
        ListTile(
          title: const Text('Reserva cancelada'),
          onTap: () => _open(
            RecordDetailPage(
              module: Module.reservations,
              row: {...repo.memory[Module.reservations]!.first, 'estado': 3},
              repository: repo,
            ),
          ),
        ),
        ListTile(
          title: const Text('Reserva atendida'),
          onTap: () => _open(
            RecordDetailPage(
              module: Module.reservations,
              row: {...repo.memory[Module.reservations]!.first, 'estado': 2},
              repository: repo,
            ),
          ),
        ),
      ],
    ),
  );
}
