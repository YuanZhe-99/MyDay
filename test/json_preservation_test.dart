import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/shared/utils/json_preservation.dart';

void main() {
  test('preserves unknown fields without restoring removed known fields', () {
    final schema = dataFilePreservationSchemas['weight_data.json']!;
    final existing = {
      'height': 180,
      'futureTopLevel': {'enabled': true},
      'records': [
        {
          'id': 'record-1',
          'weight': 70,
          'datetime': '2026-04-29T08:00:00.000',
          'notes': 'old note',
          'modifiedAt': '2026-04-29T08:00:00.000',
          'futureRecordField': ['keep', 'me'],
        },
      ],
    };
    final next = {
      'records': [
        {
          'id': 'record-1',
          'weight': 71,
          'datetime': '2026-04-30T08:00:00.000',
          'modifiedAt': '2026-04-30T08:00:00.000',
        },
      ],
      'reminderMode': 'none',
      'reminderGraceMinutes': 180,
      'settingsModifiedAt': '2026-04-30T08:00:00.000Z',
    };

    final preserved = JsonPreservation.preserve(
      next: next,
      sources: [existing],
      schema: schema,
    );
    final record = (preserved['records'] as List).single as Map;

    expect(preserved['futureTopLevel'], {'enabled': true});
    expect(record['futureRecordField'], ['keep', 'me']);
    expect(preserved.containsKey('height'), isFalse);
    expect(record.containsKey('notes'), isFalse);
  });
}
