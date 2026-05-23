import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';

/// Purpose: Verify intimacy record serialization behavior.
/// Inputs: None.
/// Returns: None.
/// Side effects: Runs test assertions.
/// Notes: Keeps optional thrust-count persistence covered.
void main() {
  test('round-trips optional thrust count and unit', () {
    final record = IntimacyRecord(
      type: 'Regular',
      pleasureLevel: 4,
      duration: const Duration(minutes: 30),
      thrustCount: 250,
      thrustCountUnit: 1,
      datetime: DateTime(2026, 5, 23, 20),
    );

    final json = record.toJson();
    final restored = IntimacyRecord.fromJson(json);

    expect(json['thrustCount'], 250);
    expect(json['thrustCountUnit'], 1);
    expect(restored.thrustCount, 250);
    expect(restored.thrustCountUnit, 1);
  });

  test('omits missing thrust count and defaults unit to x100', () {
    final record = IntimacyRecord(
      type: 'Solo',
      isSolo: true,
      pleasureLevel: 3,
      duration: const Duration(minutes: 15),
      datetime: DateTime(2026, 5, 23, 21),
    );

    final json = record.toJson();
    final restored = IntimacyRecord.fromJson(json);

    expect(json.containsKey('thrustCount'), isFalse);
    expect(json.containsKey('thrustCountUnit'), isFalse);
    expect(restored.thrustCount, isNull);
    expect(restored.thrustCountUnit, 100);
  });
}
