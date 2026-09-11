import 'package:flutter_test/flutter_test.dart';

import 'package:camscannerall/l10n/strings.dart';

void main() {
  test('AppStrings falls back to English for a missing Arabic entry', () {
    final ar = AppStrings('ar');
    final en = AppStrings('en');
    expect(ar.t('appName'), 'سكانر المستندات');
    expect(en.t('appName'), 'Doc Scanner');
  });
}
