import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/shared/services/sync_merge.dart';
import 'package:my_day/shared/utils/json_preservation.dart';

/// Purpose: Build an intimacy data JSON string for merge tests.
/// Inputs: Optional partners, cycle records, user body, and timestamps.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Keeps the settings timestamp fixed so settings LWW stays neutral.
String _intimacyJson({
  List<Partner> partners = const [],
  List<CycleRecord> cycleRecords = const [],
  BodyProfile? userBody,
  DateTime? userBodyModifiedAt,
}) => jsonEncode(
  IntimacyData(
    partners: partners,
    toys: [],
    records: [],
    cycleRecords: cycleRecords,
    userBody: userBody,
    userBodyModifiedAt: userBodyModifiedAt,
    settingsModifiedAt: DateTime.utc(2026, 1, 1),
  ).toJson(),
);

void main() {
  group('cycleRecords merge', () {
    test('adds on both sides union without conflict', () {
      final localRecord = CycleRecord(
        id: 'local-1',
        date: '2026-07-01',
        modifiedAt: DateTime.utc(2026, 7, 1),
      );
      final remoteRecord = CycleRecord(
        id: 'remote-1',
        personId: 'partner-a',
        date: '2026-07-02',
        modifiedAt: DateTime.utc(2026, 7, 2),
      );
      final base = _intimacyJson();
      final result = mergeIntimacyData(
        _intimacyJson(cycleRecords: [localRecord]),
        _intimacyJson(cycleRecords: [remoteRecord]),
        base,
      );
      expect(result.hasConflicts, isFalse);
      expect(
        result.cycleRecordsMerged.map((c) => c.id).toSet(),
        {'local-1', 'remote-1'},
      );
      final remoteMerged = result.cycleRecordsMerged.firstWhere(
        (c) => c.id == 'remote-1',
      );
      expect(remoteMerged.personId, 'partner-a');
      expect(remoteMerged.date, '2026-07-02');
    });

    test('deletion on one side syncs instead of resurrecting', () {
      final record = CycleRecord(
        id: 'cycle-1',
        date: '2026-06-15',
        modifiedAt: DateTime.utc(2026, 6, 15),
      );
      final base = _intimacyJson(cycleRecords: [record]);
      final result = mergeIntimacyData(
        _intimacyJson(), // deleted locally
        base, // unchanged remotely
        base,
      );
      expect(result.hasConflicts, isFalse);
      expect(result.cycleRecordsMerged, isEmpty);
    });

    test('buildResolved keeps merged cycle records', () {
      final record = CycleRecord(
        id: 'cycle-1',
        date: '2026-06-15',
        modifiedAt: DateTime.utc(2026, 6, 15),
      );
      final result = mergeIntimacyData(
        _intimacyJson(cycleRecords: [record]),
        _intimacyJson(cycleRecords: [record]),
        null,
      );
      final resolved = result.buildResolved({});
      expect(resolved.cycleRecords.single.id, 'cycle-1');
      expect(resolved.cycleRecords.single.personId, isNull);
    });
  });

  group('userBody merge', () {
    const localBody = BodyProfile(underbustCm: 70, braStandard: 'eu');
    const remoteBody = BodyProfile(underbustCm: 72, braStandard: 'jp');

    test('newer local userBody wins', () {
      final result = mergeIntimacyData(
        _intimacyJson(
          userBody: localBody,
          userBodyModifiedAt: DateTime.utc(2026, 7, 10),
        ),
        _intimacyJson(
          userBody: remoteBody,
          userBodyModifiedAt: DateTime.utc(2026, 7, 5),
        ),
        null,
      );
      expect(result.userBody?.underbustCm, 70);
      expect(result.userBody?.braStandard, 'eu');
      expect(result.userBodyModifiedAt, DateTime.utc(2026, 7, 10));
    });

    test('newer remote userBody wins', () {
      final result = mergeIntimacyData(
        _intimacyJson(
          userBody: localBody,
          userBodyModifiedAt: DateTime.utc(2026, 7, 1),
        ),
        _intimacyJson(
          userBody: remoteBody,
          userBodyModifiedAt: DateTime.utc(2026, 7, 8),
        ),
        null,
      );
      expect(result.userBody?.underbustCm, 72);
      expect(result.userBody?.braStandard, 'jp');
      final resolved = result.buildResolved({});
      expect(resolved.userBody?.underbustCm, 72);
      expect(resolved.userBodyModifiedAt, DateTime.utc(2026, 7, 8));
    });
  });

  group('partner body merge', () {
    test('body travels with its partner record through LWW', () {
      final base = Partner(
        id: 'p1',
        name: 'A',
        modifiedAt: DateTime.utc(2026, 1, 1),
      );
      final localEdited = Partner(
        id: 'p1',
        name: 'A',
        body: const BodyProfile(waistCm: 60, hipCm: 90, cycleEnabled: true),
        modifiedAt: DateTime.utc(2026, 7, 10),
      );
      final result = mergeIntimacyData(
        _intimacyJson(partners: [localEdited]),
        _intimacyJson(partners: [base]),
        _intimacyJson(partners: [base]),
      );
      expect(result.hasConflicts, isFalse);
      final merged = result.partnersMerged.single;
      expect(merged.body?.waistCm, 60);
      expect(merged.body?.hipCm, 90);
      expect(merged.body?.cycleEnabled, isTrue);
    });
  });

  group('new model defaults', () {
    test('cycle record timestamps default to UTC', () {
      final record = CycleRecord(date: '2026-07-16');
      expect(record.modifiedAt.isUtc, isTrue);
      expect(record.day, DateTime(2026, 7, 16));
    });

    test('empty body profile is omitted from partner JSON', () {
      final partner = Partner(name: 'A', body: const BodyProfile());
      expect(partner.toJson().containsKey('body'), isFalse);
    });

    test('old-format intimacy JSON loads with new defaults', () {
      final data = IntimacyData.fromJson({
        'partners': [
          {'id': 'p1', 'name': 'A', 'modifiedAt': '2026-01-01T00:00:00.000Z'},
        ],
        'toys': [],
        'positions': [],
        'records': [],
      });
      expect(data.userBody, isNull);
      expect(data.cycleRecords, isEmpty);
      expect(data.userBodyModifiedAt.millisecondsSinceEpoch, 0);
      expect(data.partners.single.body, isNull);
      // Untouched data must serialize without any of the new keys.
      final json = data.toJson();
      expect(json.containsKey('userBody'), isFalse);
      expect(json.containsKey('userBodyModifiedAt'), isFalse);
      expect(json.containsKey('cycleRecords'), isFalse);
    });
  });

  group('preservation schema coverage', () {
    test('new known keys are not resurrected and unknown keys survive', () {
      final schema = dataFilePreservationSchemas['intimacy_data.json']!;
      final existing = {
        'partners': [
          {
            'id': 'p1',
            'name': 'A',
            'body': {'waistCm': 61.0, 'futureBodyField': 'keep'},
            'modifiedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
        'toys': <Object>[],
        'positions': <Object>[],
        'records': <Object>[],
        'timerHistory': <Object>[],
        'userBody': {'underbustCm': 71.0, 'futureBodyField': 'keep'},
        'userBodyModifiedAt': '2026-07-01T00:00:00.000Z',
        'cycleRecords': [
          {
            'id': 'c1',
            'date': '2026-06-01',
            'modifiedAt': '2026-06-01T00:00:00.000Z',
            'futureCycleField': 'keep',
          },
        ],
        'futureTopLevel': {'x': 1},
        'settingsModifiedAt': '2026-01-01T00:00:00.000Z',
      };
      final next = {
        'partners': [
          {
            'id': 'p1',
            'name': 'A',
            // body intentionally removed by the newer save
            'modifiedAt': '2026-07-01T00:00:00.000Z',
          },
        ],
        'toys': <Object>[],
        'positions': <Object>[],
        'records': <Object>[],
        'timerHistory': <Object>[],
        // userBody + cycleRecords intentionally removed by the newer save
        'settingsModifiedAt': '2026-07-01T00:00:00.000Z',
      };
      final preserved = JsonPreservation.preserve(
        next: next,
        sources: [existing],
        schema: schema,
      );
      // Known keys removed in next must stay removed.
      expect(preserved.containsKey('userBody'), isFalse);
      expect(preserved.containsKey('cycleRecords'), isFalse);
      final partner =
          (preserved['partners'] as List).single as Map<String, dynamic>;
      expect(partner.containsKey('body'), isFalse);
      // Unknown keys must survive.
      expect(preserved['futureTopLevel'], {'x': 1});
    });

    test('unknown keys inside kept body objects survive', () {
      final schema = dataFilePreservationSchemas['intimacy_data.json']!;
      final existing = {
        'partners': <Object>[],
        'toys': <Object>[],
        'positions': <Object>[],
        'records': <Object>[],
        'timerHistory': <Object>[],
        'userBody': {'underbustCm': 71.0, 'futureBodyField': 'keep'},
        'cycleRecords': [
          {
            'id': 'c1',
            'date': '2026-06-01',
            'modifiedAt': '2026-06-01T00:00:00.000Z',
            'futureCycleField': 'keep',
          },
        ],
        'settingsModifiedAt': '2026-01-01T00:00:00.000Z',
      };
      final next = {
        'partners': <Object>[],
        'toys': <Object>[],
        'positions': <Object>[],
        'records': <Object>[],
        'timerHistory': <Object>[],
        'userBody': {'underbustCm': 72.0},
        'cycleRecords': [
          {
            'id': 'c1',
            'date': '2026-06-01',
            'modifiedAt': '2026-06-02T00:00:00.000Z',
          },
        ],
        'settingsModifiedAt': '2026-07-01T00:00:00.000Z',
      };
      final preserved = JsonPreservation.preserve(
        next: next,
        sources: [existing],
        schema: schema,
      );
      final userBody = preserved['userBody'] as Map<String, dynamic>;
      expect(userBody['underbustCm'], 72.0);
      expect(userBody['futureBodyField'], 'keep');
      final cycle =
          (preserved['cycleRecords'] as List).single as Map<String, dynamic>;
      expect(cycle['modifiedAt'], '2026-06-02T00:00:00.000Z');
      expect(cycle['futureCycleField'], 'keep');
    });
  });
}
