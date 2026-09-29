/// The edits one sub-page made to a record list, expressed by record id so they can be
/// replayed onto a freshly loaded copy of the list instead of overwriting it whole.
///
/// A sub-page (accounts, subscriptions, partners, ...) receives a list, edits it, and hands
/// the whole list back. Writing that list as-is loses anything another writer (the renewal
/// loop, the local API, a sync) changed in the meantime. `IdListDelta` records only what the
/// sub-page changed relative to the list it started from, then `applyTo` merges those
/// changes into the current on-disk list.
class IdListDelta<T> {
  /// Items the sub-page added or replaced, in the edited list's order.
  final List<T> upserts;

  /// Each upsert's index in the edited list, used as the insert position for new ids.
  final List<int> upsertIndexes;

  /// Ids present in the baseline but absent from the edited list.
  final Set<String> removedIds;

  final String Function(T item) _idOf;

  /// Purpose: Create a delta from already computed parts.
  /// Inputs: `upserts`, `upsertIndexes`, `removedIds`, `idOf`.
  /// Returns: A new `IdListDelta`.
  /// Side effects: None.
  /// Notes: Prefer `IdListDelta.diff`; this constructor exists for it and for tests.
  IdListDelta({
    required this.upserts,
    required this.upsertIndexes,
    required this.removedIds,
    required String Function(T item) idOf,
  }) : assert(upserts.length == upsertIndexes.length),
       _idOf = idOf;

  /// Purpose: Compute what changed between `baseline` and `edited`.
  /// Inputs: `baseline` — a copy of the list the sub-page started from; `edited` — the list
  /// it handed back; `idOf` — the record id accessor.
  /// Returns: `IdListDelta<T>`.
  /// Side effects: None.
  /// Notes: Change detection is by object identity: models are immutable, so an edit always
  /// produces a new object. `baseline` must be a copy (`List.of`) because sub-pages mutate
  /// and return the very list they were given.
  factory IdListDelta.diff(
    List<T> baseline,
    List<T> edited,
    String Function(T item) idOf,
  ) {
    final baselineById = <String, T>{};
    for (final item in baseline) {
      baselineById.putIfAbsent(idOf(item), () => item);
    }
    final upserts = <T>[];
    final upsertIndexes = <int>[];
    final editedIds = <String>{};
    for (var i = 0; i < edited.length; i++) {
      final item = edited[i];
      final id = idOf(item);
      editedIds.add(id);
      final before = baselineById[id];
      if (before == null || !identical(before, item)) {
        upserts.add(item);
        upsertIndexes.add(i);
      }
    }
    final removedIds = {
      for (final id in baselineById.keys)
        if (!editedIds.contains(id)) id,
    };
    return IdListDelta<T>(
      upserts: upserts,
      upsertIndexes: upsertIndexes,
      removedIds: removedIds,
      idOf: idOf,
    );
  }

  /// Purpose: Report whether the sub-page changed nothing.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: A pure reorder of unchanged items is not captured, by design.
  bool get isEmpty => upserts.isEmpty && removedIds.isEmpty;

  /// Purpose: Replay this delta onto a freshly loaded list.
  /// Inputs: `fresh` — the current list from disk.
  /// Returns: A new `List<T>`; `fresh` is not modified.
  /// Side effects: None.
  /// Notes: Removed ids are dropped; an upsert whose id is in `fresh` replaces it in place;
  /// any other upsert is inserted at min(its edited index, length). An upsert whose id was
  /// deleted concurrently is re-added: the user's edit wins over a concurrent delete.
  /// Records the sub-page did not touch keep their fresh value, including new ones.
  List<T> applyTo(List<T> fresh) {
    if (isEmpty) return List<T>.of(fresh);
    final result = [
      for (final item in fresh)
        if (!removedIds.contains(_idOf(item))) item,
    ];
    for (var i = 0; i < upserts.length; i++) {
      final item = upserts[i];
      final id = _idOf(item);
      final existing = result.indexWhere((e) => _idOf(e) == id);
      if (existing >= 0) {
        result[existing] = item;
      } else {
        final at = upsertIndexes[i];
        result.insert(at < result.length ? at : result.length, item);
      }
    }
    return result;
  }
}

/// The list a sub-page last reported, kept so each callback yields only its own changes.
class IdListBaseline<T> {
  List<T> _baseline;
  final String Function(T item) _idOf;

  /// Purpose: Start tracking from the list handed to a sub-page.
  /// Inputs: `initial` — the list the sub-page opens with; `idOf` — record id accessor.
  /// Returns: A new `IdListBaseline`.
  /// Side effects: None.
  /// Notes: Copies `initial` because sub-pages mutate the list they were given.
  IdListBaseline(List<T> initial, String Function(T item) idOf)
    : _baseline = List<T>.of(initial),
      _idOf = idOf;

  /// Purpose: Diff a sub-page callback's list against the previous one, then advance.
  /// Inputs: `edited` — the list the sub-page just reported.
  /// Returns: `IdListDelta<T>` holding only this callback's changes.
  /// Side effects: Replaces the stored baseline with a copy of `edited`.
  /// Notes: Call exactly once per callback, synchronously, before any await.
  IdListDelta<T> take(List<T> edited) {
    final delta = IdListDelta<T>.diff(_baseline, edited, _idOf);
    _baseline = List<T>.of(edited);
    return delta;
  }
}
