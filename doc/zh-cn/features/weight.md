# 体重

模型来源：`lib/features/weight/models/weight_record.dart`。存储：`lib/features/weight/services/weight_storage.dart`。提醒宽限逻辑：`lib/shared/services/reminder_service.dart`。完整字段列表见 [数据格式](../data-formats.md#weight--weight_datajson)。

## 模型

- **`WeightRecord`**：id、体重（kg）、可选体脂百分比、可选胸/腰/臀周长（cm）、日期时间、备注、`modifiedAt`。
- **`WeightData`**：可选身高（cm）、记录、提醒模式（`'none'`、`'once'`、`'twice'`）、早晚提醒时间、`reminderGraceMinutes`（默认 **180**）和 `settingsModifiedAt`。

## BMI 和腰臀比

`WeightData.calculateBMI(heightCm, weightKg)` 在身高缺失或 `<= 0` 时返回 `null`；否则 `weightKg / (heightM * heightM)`，其中 `heightM = heightCm / 100`。`WeightData.calculateWaistHipRatio(waistCm, hipCm)` 除非腰和臀**都**为正，否则返回 `null`。

## 胸/腰/臀从最近正值继承

对摘要卡片和测量趋势图，胸、腰或臀字段缺失/空白的记录独立地**继承该特定字段的先前正值**——不把继承值写回记录。具体来说，`WeightData.effectiveMeasurementsUpTo(records, at)` 和 `effectiveMeasurementTimeline(records)` 按时间排序记录（平局按 `modifiedAt` 再按 `id` 打破），向前走时，为胸/腰/臀各自独立保留至今为止见过的大于零的最近值——因此，如一条只更新体重和腰的新记录仍显示早前记录中最后已知的胸和臀，而存储的记录本身保持用户输入的精确内容（可能那些字段缺席）。

## 提醒宽限窗口

体重记录已存在于配置的宽限窗口内时跳过提醒，窗口**对照提醒实际触发的时刻**测量，而不是配置的提醒分钟——因为否则在排定分钟后记录的数据永远不会抑制迟到的检查（文档注释给了具体情形：提醒排定 08:00，用户在 08:30 记录体重，但桌面应用直到 11:00 才再次打开——提醒必须仍识别当天提醒已有记录）。

纯决策位于 `ReminderService.shouldSkipWeightReminderAt`（`lib/shared/services/reminder_service.dart`），由 `test/weight_reminder_grace_test.dart` 覆盖：

```dart
static bool shouldSkipWeightReminderAt({
  required DateTime firesAt,
  required List<WeightRecord> records,
  required int graceMinutes,
}) {
  if (graceMinutes <= 0) return false;
  final windowStart = firesAt.subtract(Duration(minutes: graceMinutes));
  final windowEnd = firesAt.add(const Duration(minutes: 1));
  return records.any((record) {
    return !record.datetime.isBefore(windowStart) &&
        record.datetime.isBefore(windowEnd);
  });
}
```

窗口是 `[firesAt − graceMinutes, firesAt + 1 minute)`。两个调用方锚定 `firesAt` 的方式不同，这个差异是刻意的：

- **桌面**把窗口锚定在 `current`——30 秒提醒循环评估检查那一刻的实际挂钟时间（`lib/shared/services/reminder_service.dart` 早晚提醒块附近：`!_shouldSkipWeightReminder(current)`）。因此在排定分钟后记录的数据仍能抑制只在之后实际运行的检查（忙碌/被挂起进程追赶）。
- **移动端**把窗口锚定在它正在预计算通知的排定**候选触发时间**（构建 OS 日程时 `if (_shouldSkipWeightReminder(candidate))`），因为移动通知由 OS 提前排定而不是实时评估——应用在排定时间时没有"实际触发时刻"可用，只有正在排定的候选时间。

落入宽限窗口的移动体重提醒保持其**每日重复**——重复被移到下一天开始，绝不被一次性通知替换（见 [平台说明](../platform-notes.md#notifications-reminders-tray-and-startup)）。

## UI

体重页包括增/删记录、可选胸/腰/臀测量录入、图表范围选择、原始和 EWMA 体重趋势显示、单独的原始/EWMA 胸-腰-臀趋势图、带紧凑颜色条的 BMI/测量/腰臀比摘要卡片、跟随全局周起始日设置的周分组历史、"显示全部"历史视图和提醒设置。

## 相关页面

- [数据格式](../data-formats.md) — `WeightRecord`/`WeightData` 的精确 JSON 形态。
- [亲密](intimacy.md) — 身体层经 `effectiveMeasurementsUpTo` 从这些相同的体重记录镜像用户的胸/腰/臀。
- [平台说明](../platform-notes.md) — 移动 vs 桌面提醒投递机制。
