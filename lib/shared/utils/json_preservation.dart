/// Purpose: MyDay's unknown-JSON-field preservation schemas.
/// Inputs: None (declarations only).
/// Returns: N/A.
/// Side effects: None.
/// Notes: The generic engine — `JsonPreservation`, `JsonPreservationSchema`,
/// and `JsonListPreservation` — moved to the `myapps_data` package and is
/// re-exported here so every existing import keeps working (I7).
/// The field schemas below stay app-side by design: they name MyDay's own data
/// fields, which the shared package must never know about. They are handed to
/// the sync engine through `lib/app/data_modules.dart`.
library;

export 'package:myapps_data/myapps_data.dart'
    show JsonListPreservation, JsonPreservation, JsonPreservationSchema;

import 'package:myapps_data/myapps_data.dart';

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

const _dailyScoreEntrySchema = JsonPreservationSchema(
  knownKeys: {'score', 'modifiedAt'},
);

const _todoDataSchema = JsonPreservationSchema(
  knownKeys: {
    'dailyTemplates',
    'oneTimeTasks',
    'dailyLog',
    'dailyScores',
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
  keyedObjectFields: {'dailyScores': _dailyScoreEntrySchema},
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
    'feeWaiverMinimumBalance',
    'feeWaiverMonthlyDeposit',
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

const _accountPickerSettingsSchema = JsonPreservationSchema(
  knownKeys: {'sortMode', 'groupByType', 'customOrder', 'moreAccountIds'},
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
    'accountPickerSettings',
  },
  objectFields: {'accountPickerSettings': _accountPickerSettingsSchema},
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

const _bodyProfileSchema = JsonPreservationSchema(
  knownKeys: {
    'bustCm',
    'waistCm',
    'hipCm',
    'underbustCm',
    'braStandard',
    'cycleEnabled',
    'showCycleOnCalendar',
    'erectLengthCm',
    'baseCircumferenceCm',
    'frontCircumferenceCm',
  },
);

const _cycleRecordSchema = JsonPreservationSchema(
  knownKeys: {'id', 'personId', 'date', 'modifiedAt'},
);

const _partnerSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'name',
    'emoji',
    'imagePath',
    'startDate',
    'endDate',
    'body',
    'modifiedAt',
  },
  objectFields: {'body': _bodyProfileSchema},
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
    'thrustCount',
    'thrustCountUnit',
    'datetime',
    'notes',
    'hadOrgasm',
    'watchedPorn',
    'usedCondom',
    'modifiedAt',
  },
);

const _timerHistorySchema = JsonPreservationSchema(
  knownKeys: {'start', 'durationMs', 'end', 'thrustCount', 'thrustCountUnit'},
);

const _timerSessionSchema = JsonPreservationSchema(
  knownKeys: {
    'firstStartedAt',
    'startedAt',
    'accumulatedMs',
    'running',
    'thrustCount',
    'thrustCountUnit',
  },
);

const _intimacyDataSchema = JsonPreservationSchema(
  knownKeys: {
    'partners',
    'toys',
    'positions',
    'records',
    'timerHistory',
    'timerSession',
    'timerSessionModifiedAt',
    'userBody',
    'userBodyModifiedAt',
    'cycleRecords',
    'timerHistoryRetentionDays',
    'partnerSortModes',
    'partnerCustomOrders',
    'toySortModes',
    'toyCustomOrders',
    'settingsModifiedAt',
  },
  objectFields: {
    'timerSession': _timerSessionSchema,
    'userBody': _bodyProfileSchema,
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
    'cycleRecords': JsonListPreservation(
      keyField: 'id',
      itemSchema: _cycleRecordSchema,
    ),
  },
);

const _weightRecordSchema = JsonPreservationSchema(
  knownKeys: {
    'id',
    'weight',
    'bodyFat',
    'bustCm',
    'waistCm',
    'hipCm',
    'datetime',
    'notes',
    'modifiedAt',
  },
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
