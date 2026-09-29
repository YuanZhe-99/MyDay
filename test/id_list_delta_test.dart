import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/shared/utils/id_list_delta.dart';

/// A minimal immutable record: identity changes whenever `value` changes.
class _Item {
  final String id;
  final String value;

  /// Purpose: Create a test record.
  /// Inputs: `id`, `value`.
  /// Returns: A new `_Item`.
  /// Side effects: None.
  /// Notes: Test helper only.
  const _Item(this.id, this.value);

  /// Purpose: Render the record for readable failure messages.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Test helper only.
  @override
  String toString() => '$id=$value';
}

/// Purpose: Pin the merge-by-id semantics used by finance/intimacy sub-page saves.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Each case edits a baseline, then replays the edit onto a "fresh" list that
/// another writer changed meanwhile.
void main() {
  String id(_Item i) => i.id;
  String render(List<_Item> items) => items.join(',');

  final a = const _Item('a', '1');
  final b = const _Item('b', '1');
  final c = const _Item('c', '1');
  final r = const _Item('r', 'renewal');

  final cases =
      <
        ({
          String name,
          List<_Item> baseline,
          List<_Item> edited,
          List<_Item> fresh,
          String expected,
        })
      >[
        (
          name: 'no edit returns fresh unchanged',
          baseline: [a, b],
          edited: [a, b],
          fresh: [a, b, r],
          expected: 'a=1,b=1,r=renewal',
        ),
        (
          name: 'concurrent append survives an edit',
          baseline: [a, b],
          edited: [a, const _Item('b', '2')],
          fresh: [a, b, r],
          expected: 'a=1,b=2,r=renewal',
        ),
        (
          name: 'removal drops only the removed id',
          baseline: [a, b, c],
          edited: [a, c],
          fresh: [a, b, c, r],
          expected: 'a=1,c=1,r=renewal',
        ),
        (
          name: 'new item inserts at its edited index',
          baseline: [a, b],
          edited: [const _Item('n', 'new'), a, b],
          fresh: [a, b, r],
          expected: 'n=new,a=1,b=1,r=renewal',
        ),
        (
          name: 'insert index is clamped to the fresh length',
          baseline: [a, b, c],
          edited: [a, b, c, const _Item('n', 'new')],
          fresh: [a],
          expected: 'a=1,n=new',
        ),
        (
          name: 'edit wins over a concurrent delete',
          baseline: [a, b],
          edited: [a, const _Item('b', '2')],
          fresh: [a],
          expected: 'a=1,b=2',
        ),
        (
          name: 'untouched record keeps the fresh value',
          baseline: [a, b],
          edited: [a, const _Item('b', '2')],
          fresh: [const _Item('a', 'remote'), b],
          expected: 'a=remote,b=2',
        ),
        (
          name: 'untouched record deleted elsewhere stays deleted',
          baseline: [a, b],
          edited: [a, const _Item('b', '2')],
          fresh: [const _Item('b', '1')],
          expected: 'b=2',
        ),
      ];

  for (final t in cases) {
    test(t.name, () {
      final baseline = List.of(t.baseline);
      final fresh = List.of(t.fresh);
      final delta = IdListDelta.diff(baseline, t.edited, id);
      expect(render(delta.applyTo(fresh)), t.expected);
      expect(fresh, t.fresh, reason: 'applyTo must not mutate its input');
    });
  }

  test('IdListBaseline yields only each callback\'s own changes', () {
    // Sub-pages mutate and re-send the same list object.
    final shared = [a, b];
    final tracker = IdListBaseline<_Item>(shared, id);

    shared[1] = const _Item('b', '2');
    final first = tracker.take(shared);
    expect(render(first.upserts), 'b=2');

    shared.add(const _Item('n', 'new'));
    final second = tracker.take(shared);
    expect(render(second.upserts), 'n=new');
    expect(second.removedIds, isEmpty);

    expect(tracker.take(shared).isEmpty, isTrue);
  });
}
