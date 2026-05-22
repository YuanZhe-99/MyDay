import '../models/finance.dart';

/// Purpose: Compare two user-facing account text values case-insensitively.
/// Inputs: `a`, `b`.
/// Returns: The comparison result.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
int _compareAccountText(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());

/// Purpose: Return a valid custom picker order for the current account list.
/// Inputs: `accounts`, `customOrder`.
/// Returns: A normalized list of account ids.
/// Side effects: None.
/// Notes: Missing current accounts are appended in their existing order.
List<String> normalizedAccountPickerOrder(
  List<Account> accounts,
  List<String> customOrder,
) {
  final allIds = accounts.map((account) => account.id).toList();
  final allIdSet = allIds.toSet();
  final seen = <String>{};
  final normalized = <String>[
    for (final id in customOrder)
      if (allIdSet.contains(id) && seen.add(id)) id,
  ];
  for (final id in allIds) {
    if (seen.add(id)) normalized.add(id);
  }
  return normalized;
}

/// Purpose: Remove stale ids and validate account picker settings.
/// Inputs: `settings`, `accounts`.
/// Returns: A normalized `AccountPickerSettings` value.
/// Side effects: None.
/// Notes: Use before saving settings edited by the account picker settings page.
AccountPickerSettings normalizedAccountPickerSettings(
  AccountPickerSettings settings,
  List<Account> accounts,
) {
  final accountIds = accounts.map((account) => account.id).toSet();
  final seenMore = <String>{};
  return settings.copyWith(
    sortMode:
        settings.sortMode == AccountPickerSettings.sortName ||
            settings.sortMode == AccountPickerSettings.sortCustom
        ? settings.sortMode
        : AccountPickerSettings.sortCustom,
    customOrder: normalizedAccountPickerOrder(accounts, settings.customOrder),
    moreAccountIds: [
      for (final id in settings.moreAccountIds)
        if (accountIds.contains(id) && seenMore.add(id)) id,
    ],
  );
}

/// Purpose: Sort accounts for transaction account picker display.
/// Inputs: `accounts`, `settings`.
/// Returns: A sorted account list.
/// Side effects: None.
/// Notes: Type grouping changes the primary comparison key but keeps each group's chosen sort.
List<Account> sortAccountsForPicker(
  List<Account> accounts,
  AccountPickerSettings settings,
) {
  final sorted = List<Account>.of(accounts);
  final originalIndex = <String, int>{
    for (var i = 0; i < accounts.length; i++) accounts[i].id: i,
  };
  final order = normalizedAccountPickerOrder(accounts, settings.customOrder);
  final orderIndex = <String, int>{
    for (var i = 0; i < order.length; i++) order[i]: i,
  };

  sorted.sort((a, b) {
    if (settings.groupByType) {
      final byType = a.type.index.compareTo(b.type.index);
      if (byType != 0) return byType;
    }

    if (settings.sortMode == AccountPickerSettings.sortName) {
      final byName = _compareAccountText(a.name, b.name);
      if (byName != 0) return byName;
      final byBank = _compareAccountText(a.bankOrApp, b.bankOrApp);
      if (byBank != 0) return byBank;
    } else {
      final byOrder = (orderIndex[a.id] ?? order.length).compareTo(
        orderIndex[b.id] ?? order.length,
      );
      if (byOrder != 0) return byOrder;
    }

    return (originalIndex[a.id] ?? accounts.length).compareTo(
      originalIndex[b.id] ?? accounts.length,
    );
  });
  return sorted;
}
