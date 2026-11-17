import 'package:flutter_test/flutter_test.dart';

import 'soporte/comprobaciones_clientes.dart';

void main() {
  test(
    'Guarda clientes y diferencia duplicados confirmados de errores generales',
    () async {
      expect(await comprobarRegistroClientes(), 17);
    },
  );
}
