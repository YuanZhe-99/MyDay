import 'dart:convert';
import 'dart:io';

class JsonListPreservation {
  final String keyField;
  final JsonPreservationSchema itemSchema;

  const JsonListPreservation({
    required this.keyField,
    required this.itemSchema,
  });
}

class JsonPreservationSchema {
  final Set<String> knownKeys;
  final Map<String, JsonPreservationSchema> objectFields;
  final Map<String, JsonListPreservation> listFields;
  final Map<String, JsonPreservationSchema> keyedObjectFields;

  const JsonPreservationSchema({
    required this.knownKeys,
    this.objectFields = const {},
    this.listFields = const {},
    this.keyedObjectFields = const {},
  });
}

class JsonPreservation {
  const JsonPreservation._();

  static Future<String> encodeForFile({
    required File file,
    required Map<String, dynamic> next,
    required JsonPreservationSchema schema,
  }) async {
    final sources = <Map<String, dynamic>>[];
    try {
      if (await file.exists()) {
        sources.add(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    return jsonEncode(preserve(next: next, sources: sources, schema: schema));
  }

  static String preserveJsonString({
    required String nextJson,
    required Iterable<String?> sourceJsons,
    required JsonPreservationSchema schema,
  }) {
    final next = jsonDecode(nextJson) as Map<String, dynamic>;
    final sources = <Map<String, dynamic>>[];
    for (final sourceJson in sourceJsons) {
      if (sourceJson == null) continue;
      try {
        sources.add(jsonDecode(sourceJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    return jsonEncode(preserve(next: next, sources: sources, schema: schema));
  }

  static Map<String, dynamic> preserve({
    required Map<String, dynamic> next,
    required Iterable<Map<String, dynamic>> sources,
    required JsonPreservationSchema schema,
  }) {
    var result = _copyMap(next);
    for (final source in sources) {
      result = _preserveOne(next: result, source: source, schema: schema);
    }
    return result;
  }

  static Map<String, dynamic> _preserveOne({
    required Map<String, dynamic> next,
    required Map<String, dynamic> source,
    required JsonPreservationSchema schema,
  }) {
    final result = _copyMap(next);

    for (final entry in schema.objectFields.entries) {
      final nextValue = result[entry.key];
      final sourceValue = source[entry.key];
      if (nextValue is Map && sourceValue is Map) {
        result[entry.key] = _preserveOne(
          next: _stringKeyMap(nextValue),
          source: _stringKeyMap(sourceValue),
          schema: entry.value,
        );
      }
    }

    for (final entry in schema.keyedObjectFields.entries) {
      final nextValue = result[entry.key];
      final sourceValue = source[entry.key];
      if (nextValue is Map && sourceValue is Map) {
        result[entry.key] = _preserveKeyedObjects(
          next: _stringKeyMap(nextValue),
          source: _stringKeyMap(sourceValue),
          schema: entry.value,
        );
      }
    }

    for (final entry in schema.listFields.entries) {
      final nextValue = result[entry.key];
      final sourceValue = source[entry.key];
      if (nextValue is List && sourceValue is List) {
        result[entry.key] = _preserveListItems(
          next: nextValue,
          source: sourceValue,
          listSchema: entry.value,
        );
      }
    }

    for (final entry in source.entries) {
      if (schema.knownKeys.contains(entry.key)) continue;
      result[entry.key] = _copyJsonValue(entry.value);
    }

    return result;
  }

  static Map<String, dynamic> _preserveKeyedObjects({
    required Map<String, dynamic> next,
    required Map<String, dynamic> source,
    required JsonPreservationSchema schema,
  }) {
    final result = _copyMap(next);
    for (final entry in result.entries.toList()) {
      final sourceValue = source[entry.key];
      if (entry.value is Map && sourceValue is Map) {
        result[entry.key] = _preserveOne(
          next: _stringKeyMap(entry.value as Map),
          source: _stringKeyMap(sourceValue),
          schema: schema,
        );
      }
    }
    return result;
  }

  static List<dynamic> _preserveListItems({
    required List<dynamic> next,
    required List<dynamic> source,
    required JsonListPreservation listSchema,
  }) {
    final sourceByKey = <Object, Map<String, dynamic>>{};
    for (final item in source) {
      if (item is! Map) continue;
      final itemMap = _stringKeyMap(item);
      final key = itemMap[listSchema.keyField];
      if (key != null) sourceByKey[key] = itemMap;
    }

    return next.map((item) {
      if (item is! Map) return _copyJsonValue(item);
      final itemMap = _stringKeyMap(item);
      final key = itemMap[listSchema.keyField];
      final sourceItem = sourceByKey[key];
      if (sourceItem == null) return _copyMap(itemMap);
      return _preserveOne(
        next: itemMap,
        source: sourceItem,
        schema: listSchema.itemSchema,
      );
    }).toList();
  }

  static Map<String, dynamic> _copyMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, _copyJsonValue(value)));
  }

  static Map<String, dynamic> _stringKeyMap(Map map) {
    return map.map((key, value) => MapEntry(key as String, value));
  }

  static dynamic _copyJsonValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key as String, _copyJsonValue(child)),
      );
    }
    if (value is List) {
      return value.map(_copyJsonValue).toList();
    }
    return value;
  }
}

const _subTaskSchema = JsonPreservationSchema(
  knownKeys: {'id', 'title', 'isCompleted', 'modifiedAt'},
);

const _recurrenceSchema = JsonPreservationSchema(
  knownKeys: {'type', 'intervalDays', 'dayOfMonth', 'monthOfYear'},
);

const _taskSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'title',
    'note',
    'emoji',
    'type',
    'isCompleted',
    'reminderTime',
    'subtasks',
    'createdDate',
    'completedDate',
    'scheduledDate',
    'deletedDate',
    'startDate',
    'dueDate',
    'recurrence',
    'modifiedAt',
  },
  objectFields: {'recurrence': _recurrenceSchema},
  listFields: {
    'subtasks': JsonListPreservation(
      keyField: 'id',
      itemSchema: _subTaskSchema,
    ),
  },
);

const _todoDataSchema = JsonPreservationSchema(
  knownKeys: {
    'dailyTemplates',
    'oneTimeTasks',
    'dailyLog',
    'morningReminderHour',
    'morningReminderMinute',
    'completionReminderHour',
    'completionReminderMinute',
    'dailyReminderHour',
    'dailyReminderMinute',
    'taskSortModes',
    'taskCustomOrders',
    'settingsModifiedAt',
  },
  listFields: {
    'dailyTemplates': JsonListPreservation(
      keyField: 'id',
      itemSchema: _taskSchema,
    ),
    'oneTimeTasks': JsonListPreservation(
      keyField: 'id',
      itemSchema: _taskSchema,
    ),
  },
);

const _iconRefSchema = JsonPreservationSchema(
  knownKeys: {'codePoint', 'fontFamily'},
);

const _accountSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'type',
    'bankOrApp',
    'name',
    'currency',
    'cardNumber',
    'expiryDate',
    'securityCode',
    'emoji',
    'imagePath',
    'forcedBalance',
    'forcedBalanceDate',
    'modifiedAt',
  },
);

const _categorySchema = JsonPreservationSchema(
  knownKeys: {'id', 'name', 'icon', 'emoji', 'type', 'modifiedAt'},
  objectFields: {'icon': _iconRefSchema},
);

const _transactionSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'type',
    'amount',
    'currency',
    'rateSnapshotId',
    'accountId',
    'toAccountId',
    'toAmount',
    'toCurrency',
    'categoryId',
    'subscriptionId',
    'note',
    'date',
    'modifiedAt',
  },
);

const _subscriptionSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'name',
    'emoji',
    'imagePath',
    'startDate',
    'trialDays',
    'billingCycleType',
    'billingInterval',
    'amount',
    'currency',
    'accountId',
    'categoryId',
    'note',
    'isActive',
    'cancelledAt',
    'cancelType',
    'nextBillingDate',
    'modifiedAt',
  },
);

const _financeDataSchema = JsonPreservationSchema(
  knownKeys: {
    'accounts',
    'categories',
    'transactions',
    'subscriptions',
    'defaultCurrency',
    'settingsModifiedAt',
    'subscriptionReminderHour',
    'subscriptionReminderMinute',
    'subscriptionSortMode',
    'subscriptionCustomOrder',
    'accountSortModes',
    'accountCustomOrders',
  },
  listFields: {
    'accounts': JsonListPreservation(
      keyField: 'id',
      itemSchema: _accountSchema,
    ),
    'categories': JsonListPreservation(
      keyField: 'id',
      itemSchema: _categorySchema,
    ),
    'transactions': JsonListPreservation(
      keyField: 'id',
      itemSchema: _transactionSchema,
    ),
    'subscriptions': JsonListPreservation(
      keyField: 'id',
      itemSchema: _subscriptionSchema,
    ),
  },
);

const _rateSnapshotSchema = JsonPreservationSchema(
  knownKeys: {'id', 'rates', 'createdAt'},
);

const _exchangeRateDataSchema = JsonPreservationSchema(
  knownKeys: {'currentSnapshotId', 'snapshots', 'lastFetchedAt'},
  keyedObjectFields: {'snapshots': _rateSnapshotSchema},
);

const _partnerSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'name',
    'emoji',
    'imagePath',
    'startDate',
    'endDate',
    'modifiedAt',
  },
);

const _toySchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'name',
    'emoji',
    'imagePath',
    'purchaseDate',
    'retiredDate',
    'purchaseLink',
    'price',
    'modifiedAt',
  },
);

const _positionSchema = JsonPreservationSchema(
  knownKeys: {'id', 'name', 'emoji', 'modifiedAt'},
);

const _intimacyRecordSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'type',
    'location',
    'isSolo',
    'partnerId',
    'toyIds',
    'positionIds',
    'pleasureLevel',
    'duration',
    'datetime',
    'notes',
    'hadOrgasm',
    'watchedPorn',
    'modifiedAt',
  },
);

const _timerHistorySchema = JsonPreservationSchema(
  knownKeys: {'start', 'durationMs', 'end'},
);

const _intimacyDataSchema = JsonPreservationSchema(
  knownKeys: {
    'partners',
    'toys',
    'positions',
    'records',
    'timerHistory',
    'timerHistoryRetentionDays',
    'partnerSortModes',
    'partnerCustomOrders',
    'toySortModes',
    'toyCustomOrders',
    'settingsModifiedAt',
  },
  listFields: {
    'partners': JsonListPreservation(
      keyField: 'id',
      itemSchema: _partnerSchema,
    ),
    'toys': JsonListPreservation(keyField: 'id', itemSchema: _toySchema),
    'positions': JsonListPreservation(
      keyField: 'id',
      itemSchema: _positionSchema,
    ),
    'records': JsonListPreservation(
      keyField: 'id',
      itemSchema: _intimacyRecordSchema,
    ),
    'timerHistory': JsonListPreservation(
      keyField: 'start',
      itemSchema: _timerHistorySchema,
    ),
  },
);

const _weightRecordSchema = JsonPreservationSchema(
  knownKeys: {'id', 'weight', 'bodyFat', 'datetime', 'notes', 'modifiedAt'},
);

const _weightDataSchema = JsonPreservationSchema(
  knownKeys: {
    'height',
    'records',
    'reminderMode',
    'morningHour',
    'morningMinute',
    'eveningHour',
    'eveningMinute',
    'reminderGraceMinutes',
    'settingsModifiedAt',
  },
  listFields: {
    'records': JsonListPreservation(
      keyField: 'id',
      itemSchema: _weightRecordSchema,
    ),
  },
);

const dataFilePreservationSchemas = {
  'todo_data.json': _todoDataSchema,
  'finance_data.json': _financeDataSchema,
  'exchange_rates.json': _exchangeRateDataSchema,
  'intimacy_data.json': _intimacyDataSchema,
  'weight_data.json': _weightDataSchema,
};
