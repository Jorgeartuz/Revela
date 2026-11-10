import 'package:flutter_test/flutter_test.dart';

import 'support/client_registration_checks.dart';

void main() {
  test('Handles customer persistence and confirmed duplicates', () async {
    expect(await runClientRegistrationChecks(), 17);
  });
}
