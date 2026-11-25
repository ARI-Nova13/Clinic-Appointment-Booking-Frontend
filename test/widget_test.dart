import 'package:flutter_test/flutter_test.dart';
import 'package:medicare_app/theme/app_theme.dart';

void main() {
  test('MediCare uses Material 3 and the shared primary palette', () {
    final theme = AppTheme.lightTheme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTheme.primary);
    expect(theme.scaffoldBackgroundColor, AppTheme.background);
  });
}
