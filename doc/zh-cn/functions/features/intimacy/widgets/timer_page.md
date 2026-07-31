# lib/features/intimacy/widgets/timer_page.dart

`TimerPage` 是 [亲密 — 计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence) 描述的亲密秒表屏。它是基于挂钟的计时器（不受熄屏/应用挂起影响，不同于朴素滴答计数器），带一个非负抽插计数器（估计值存为 `x100`、精确非整百数存为 `x1`）、保留/修剪历史列表，以及由 `wakelock_plus` 支撑的仅本地保持屏幕唤醒开关。关键的是，此组件自己不拥有持久化——每个改变状态的操作都调用 `widget.onStateChanged`（类型为 `TimerStateChanged`），调用方（`views/intimacy_page.dart`，经 `_saveTimerState`）用它立即写 `intimacy_data.json`，因此会话中途意外应用/页面退出仍保留最新运行/暂停状态和抽插次数。保存时它打开预填已流逝时长和抽插次数的 [`AddRecordDialog`](add_record_dialog.md)。页面返回描述什么变化（记录、历史、计时器会话、保留）的 `TimerPageResult`，使调用方只重新保存实际脏的东西。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `TimerStateChanged` | typedef | B | 调用方提供以持久化计时器状态变更的回调签名。 |
| `TimerPageResult`（构造函数） | 构造函数（`TimerPageResult`） | B | 创建计时器页结果实例。 |
| `TimerPage`（构造函数） | 构造函数（`TimerPage`） | B | 从姿势、当前计时器状态和持久化回调创建计时器页实例。 |
| `TimerPage.createState` | 方法（`TimerPage`） | B | 创建可变 `_TimerPageState`。 |
| [`_elapsed`](#elapsed) | getter（`_TimerPageState`） | A | 计算挂钟已流逝时间：累积时间加距上次恢复以来的时间（运行中时）。 |
| [`initState`](#initstate) | 方法（`_TimerPageState`） | A | 从 `widget.timerSession` 恢复被中断的计时器会话（运行/暂停）并加载唤醒锁偏好。 |
| `dispose` | 方法（`_TimerPageState`） | B | 取消滴答器、移除生命周期观察者并释放任何持有的唤醒锁。 |
| [`didChangeAppLifecycleState`](#didchangeapplifecyclestate) | 方法（`_TimerPageState`） | A | 应用在计时器运行中恢复时重新武装滴答器和唤醒锁。 |
| [`_loadKeepScreenAwakeSetting`](#loadkeepscreenawakesetting) | 方法（`_TimerPageState`） | A | 加载仅本地保持屏幕唤醒偏好并应用它。 |
| [`_setKeepScreenAwake`](#setkeepscreenawake) | 方法（`_TimerPageState`） | A | 持久化并应用新保持屏幕唤醒偏好。 |
| [`_applyWakelock`](#applywakelock) | 方法（`_TimerPageState`） | A | 启用或禁用平台屏幕唤醒锁以匹配当前偏好。 |
| [`_releaseWakelock`](#releasewakelock) | 方法（`_TimerPageState`） | A | 禁用唤醒锁，但只在本页是启用它的那个时。 |
| [`_applyRetention`](#applyretention) | 方法（`_TimerPageState`） | A | 丢弃比配置保留窗口更旧的历史条目。 |
| [`_start`](#start) | 方法（`_TimerPageState`） | A | 从零开始或从暂停恢复秒表，并持久化运行会话。 |
| [`_pause`](#pause) | 方法（`_TimerPageState`） | A | 暂停秒表，把已流逝时间折进累积总计，并持久化暂停会话。 |
| [`_changeThrustCount`](#changethrustcount) | 方法（`_TimerPageState`） | A | 把抽插次数按带符号增量调整，零处钳制，并持久化会话。 |
| [`_actualThrustCount`](#actualthrustcount) | 方法（`_TimerPageState`） | A | 把存储的计数/单位对转换回实际次数计数。 |
| [`_storedThrustCountUnit`](#storedthrustcountunit) | getter（`_TimerPageState`） | A | 决定当前计数必须存为精确 `x1` 还是估计 `x100`。 |
| [`_storedThrustCount`](#storedthrustcount) | getter（`_TimerPageState`） | A | 计算在当前存储单位下要持久化的计数值。 |
| `_thrustCountLabel` | getter（`_TimerPageState`） | B | 把当前抽插次数格式化为 `"<count> x<unit>"` 供显示。 |
| [`_reset`](#reset) | 方法（`_TimerPageState`） | A | 把秒表清零回零（时间和抽插次数）并持久化已清除的会话。 |
| [`_ensureTicker`](#ensureticker) | 方法（`_TimerPageState`） | A | （重新）启动驱动可见已流逝时间显示的一秒周期计时器。 |
| `_sessionStartTime` | getter（`_TimerPageState`） | B | 返回 `_firstStartedAt`（会话的原始开始时间，如有）。 |
| [`_timerSession`](#timersession) | getter（`_TimerPageState`） | A | 构建当前秒表状态的可持久化 `IntimacyTimerSession` 快照。 |
| [`_persistState`](#persiststate) | 方法（`_TimerPageState`） | A | 只在有实际变化时把变更字段标志和状态快照转发给 `widget.onStateChanged`。 |
| [`_popWithHistoryIfChanged`](#popwithhistoryifchanged) | 方法（`_TimerPageState`） | A | 弹出页面，只在历史/会话/保留实际变化时返回 `TimerPageResult`。 |
| [`_saveRecord`](#saverecord) | 方法（`_TimerPageState`） | A | 停止计时器（从历史恢复时除外）、添加历史条目、打开 `AddRecordDialog` 并带结果弹出。 |
| [`_formatDuration`](#formatduration) | 方法（`_TimerPageState`） | A | 把 `Duration` 格式化为 `HH:MM:SS`。 |
| `_formatDateTime` | 方法（`_TimerPageState`） | B | 经 `intl` 把 `DateTime` 格式化为 `MM/dd HH:mm:ss`。 |
| [`_confirmRestoreHistory`](#confirmrestorehistory) | 方法（`_TimerPageState`） | A | 确认，然后把计时器历史条目恢复为新运行秒表会话，从历史移除它。 |
| `build` | 方法（`_TimerPageState`） | B | 渲染已流逝时间显示、抽插控件、开始/暂停/保存/重置按钮和历史列表。 |
| `_buildRetentionChip` | 方法（组件辅助） | B | 渲染历史保留弹出菜单 chip（3 天/7 天/14 天/永久）。 |

`grep -c 'Purpose:' lib/features/intimacy/widgets/timer_page.dart` 报告 32，与上面 32 行精确匹配（未发现未文档化的真实声明，也没有 `/// Purpose:` 块错附在调用点而非真实声明上方）。几个块在源码中使用泛泛的自动生成式措辞（"Provide the internal ... helper for this file"、"Internal helper used within this file only"）——本页的 Purpose 列和文档条目按逐文件模板细化（不只复制）源码 `///` 注释的要求，用对照实际实现验证的描述替换那种措辞。Tier 划分：22 个 Tier A、10 个 Tier B。

## 文档

### `Duration get _elapsed` <a id="elapsed"></a>
- **种类：** `_TimerPageState` 的 getter
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 117 行）
- **用途：** 从挂钟时间戳而不是滴答内存计数器计算秒表当前已流逝时间。
- **输入：** 无（读取 `_accumulated`、`_running`、`_startedAt`）。
- **返回：** `Duration`。
- **副作用：** 无。
- **算法：** `_accumulated + (_running && _startedAt != null ? DateTime.now().difference(_startedAt!) : Duration.zero)`——先前运行段的累积时间，加当前运行中距上次恢复以来的时间。
- **用法：**
  ```dart
  // build, line 626:
  Text(_formatDuration(_elapsed), ...),

  // build, line 590:
  final hasElapsed = _elapsed > Duration.zero;
  ```
- **备注：** 这是模型自己的 `IntimacyTimerSession.elapsedAt(now)` 的组件级等价物，在 [亲密 — 计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence) 中描述：因为每次读取都从 `DateTime.now()` 派生，即使应用重启后、第一个滴答回调触发前，显示时间也正确。

### `void initState()` <a id="initstate"></a>
- **种类：** `_TimerPageState` 的方法（`State.initState` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 131 行）
- **用途：** 恢复调用方传入的任何计时器会话——运行、暂停或无——并开始加载保持屏幕唤醒偏好。
- **输入：** 无（读取 `widget.timerHistory`、`widget.timerHistoryRetentionDays`、`widget.timerSession`）。
- **返回：** 无。
- **副作用：** 把此状态注册为 `WidgetsBindingObserver`；可能标记历史已变；恢复运行会话时启动滴答器；启动 `_loadKeepScreenAwakeSetting()`。
- **算法：**
  1. `super.initState()`，然后注册为生命周期观察者。
  2. `_retentionDays = widget.timerHistoryRetentionDays`；经 `_applyRetention` 对 `widget.timerHistory` 副本应用保留；修剪了任何条目时设 `_historyChanged = true`（使调用方即使从未碰计时器也重新保存修剪后的列表）。
  3. `widget.timerSession` 非 null 时：恢复 `_firstStartedAt`，`session.running` 时才恢复 `_startedAt`（暂停会话没有活 `_startedAt`）；恢复 `_accumulated`、`_running`；经 `_actualThrustCount(session.thrustCount, session.thrustCountUnit)` 恢复 `_thrustCount`（把存储 x100/x1 形式转换回实际次数计数）；`_running` 时调用 `_ensureTicker()`，使显示立即开始推进。
  4. `unawaited(_loadKeepScreenAwakeSetting())`。
- **用法：**
  ```dart
  // views/intimacy_page.dart, lines 548-560 (opening the page restores whatever session was saved):
  builder: (_) => TimerPage(
    partners: _partners.where((p) => p.endDate == null).toList(),
    toys: _toys.where((t) => t.retiredDate == null).toList(),
    positions: _positions,
    timerHistory: _timerHistory,
    timerSession: _timerSession,
    timerHistoryRetentionDays: _timerHistoryRetentionDays,
    onStateChanged: _saveTimerState,
  ),
  ```
- **备注：** 这正是 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 文档化的会话恢复行为："停止但未保存和暂停的会话恢复为暂停"（这里：`session.running == false`，因此 `_startedAt` 保持 `null` 而 `_accumulated`/`_thrustCount` 仍恢复）和"运行中会话从挂钟时间恢复"（这里：`_ensureTicker()` 加 `_elapsed` getter 的实时计算）。

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="didchangeapplifecyclestate"></a>
- **种类：** `_TimerPageState` 的方法（`WidgetsBindingObserver.didChangeAppLifecycleState` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 174 行）
- **用途：** 应用回到前台后重新武装滴答器和唤醒锁。
- **输入：** `state` — 新 `AppLifecycleState`。
- **返回：** 无。
- **副作用：** 可能重启滴答器（`setState`）并重新启用唤醒锁。
- **算法：** 只对 `AppLifecycleState.resumed` 行动：`_running` 时调用 `_ensureTicker()` 和 `setState(() {})`，用当前挂钟已流逝时间强制立即重绘；`_keepScreenAwake` 时调用 `_applyWakelock()`（unawaited）。
- **用法：** 应用生命周期状态变化时（如操作系统可能挂起计时器后从后台返回）由 Flutter 框架经 `initState` 注册的 `WidgetsBindingObserver` mixin 自动调用。
- **备注：** 因为 `_elapsed` 基于挂钟，即使没有此方法，显示时间在下一个周期滴答时也已正确——它的真正工作是让*滴答器本身*（被挂起应用可能暂停）和唤醒锁及时恢复，而不是等待。

### `Future<void> _loadKeepScreenAwakeSetting()` <a id="loadkeepscreenawakesetting"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 191 行）
- **用途：** 加载记住的仅本地保持屏幕唤醒偏好并立即应用。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `storage_config.json`；更新 `_keepScreenAwake`；可能启用平台唤醒锁。
- **算法：** 读取 `TodoStorage.readConfig()`；`enabled = config[_keepScreenAwakeConfigKey] == true`；仍 mounted 时 `setState` 存储它，然后 `await _applyWakelock()`。
- **用法：**
  ```dart
  // initState, line 151:
  unawaited(_loadKeepScreenAwakeSetting());
  ```
- **备注：** 用键 `intimacyTimerKeepScreenAwake`（`_keepScreenAwakeConfigKey`），它刻意不属于同步的 `intimacy_data.json`——见 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence)。

### `Future<void> _setKeepScreenAwake(bool enabled)` <a id="setkeepscreenawake"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 204 行）
- **用途：** 处理用户切换保持屏幕唤醒开关。
- **输入：** `enabled` — 新开关值。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_keepScreenAwake`；切换平台唤醒锁；写 `storage_config.json`，保留配置映射中任何无关键。
- **算法：** `setState` 新值；`await _applyWakelock()`；读取配置、设 `config[_keepScreenAwakeConfigKey] = enabled`、写回。
- **用法：**
  ```dart
  // build, line 682-684:
  onChanged: (value) {
    unawaited(_setKeepScreenAwake(value));
  },
  ```
- **备注：** 唤醒锁在配置写入前应用，使平台状态即使在写入在途也立即匹配 UI。

### `Future<void> _applyWakelock()` <a id="applywakelock"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 217 行）
- **用途：** 让平台屏幕唤醒锁与当前 `_keepScreenAwake` 偏好一致，不踩其他功能可能持有的唤醒锁。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 调用 `WakelockPlus.enable()`/`disable()`；更新 `_wakelockEnabledByPage`。
- **算法：**
  1. `_keepScreenAwake && !_disposed` 时：启用唤醒锁；await 期间页面被释放或偏好翻转为关（`_disposed || !_keepScreenAwake`）时立即再次禁用并清除 `_wakelockEnabledByPage`；否则标记 `_wakelockEnabledByPage = true`。
  2. 否则 `_wakelockEnabledByPage`（偏好关但本页仍持有锁）时：禁用并清除标志。
- **用法：**
  ```dart
  // _loadKeepScreenAwakeSetting, line 196:
  await _applyWakelock();

  // didChangeAppLifecycleState, line 181:
  unawaited(_applyWakelock());
  ```
- **备注：** `_wakelockEnabledByPage` 跟踪*本页*是否是持有锁的那个，因此 `_releaseWakelock` 绝不禁用其他功能（如经 `shared/services/sync_wake_lock.dart` 的前台同步操作）独立持有的唤醒锁。

### `void _releaseWakelock()` <a id="releasewakelock"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 237 行）
- **用途：** 页面拆除时释放唤醒锁，但只在本页是启用它的那个时。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 可能调用 `WakelockPlus.disable()`（即发即忘）。
- **算法：** `!_wakelockEnabledByPage` 时立即返回；否则清除标志并做不 await 的 `WakelockPlus.disable()`。
- **用法：**
  ```dart
  // dispose, line 164:
  _releaseWakelock();
  ```
- **备注：** 文档注释明确说明不 await 的调用是刻意的：`dispose()` 不能是 `async`，因此平台通道调用刻意即发即忘。

### `List<TimerHistoryEntry> _applyRetention(List<TimerHistoryEntry> entries)` <a id="applyretention"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 250 行）
- **用途：** 修剪比配置保留窗口更旧的历史条目。
- **输入：** `entries` — 要过滤的历史列表。
- **返回：** `List<TimerHistoryEntry>` — 保留为永久时 `entries` 不变。
- **副作用：** 无（纯过滤；调用方负责持久化结果）。
- **算法：** `_retentionDays == null` 时原样返回 `entries`（永久保留）。否则计算 `cutoff = DateTime.now().subtract(Duration(days: _retentionDays!))` 并只保留 `e.start.isAfter(cutoff)` 的条目。
- **用法：**
  ```dart
  // initState, line 135:
  _history = _applyRetention(List.of(widget.timerHistory));

  // _buildRetentionChip, onSelected, line 859:
  _history = _applyRetention(_history);
  ```
- **备注：** 保留在加载时（设置可能在页面关闭时变化）和用户选新保留值时立即都应用。

### `Future<void> _start()` <a id="start"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 263 行）
- **用途：** 从零开始秒表，或从暂停状态恢复。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_firstStartedAt`/`_startedAt`/`_running`；启动滴答器；经 `_persistState` 持久化会话。
- **算法：**
  1. `_firstStartedAt ??= DateTime.now()` — 只在首次开始设置，恢复时绝不。
  2. `_startedAt = DateTime.now()`（本运行段开始的挂钟时刻）；`_running = true`。
  3. `_ensureTicker()`；`setState(() {})`；`await _persistState(timerSessionChanged: true)`。
- **用法：**
  ```dart
  // build, line 696 (fresh start) and line 734 (resume from paused):
  onPressed: () => _start(),
  ```
- **备注：** `_firstStartedAt` 是暂停/恢复循环中原样存活的值——它是作为 `IntimacyTimerSession.firstStartedAt` 存储、`_saveRecord` 回退为记录开始时间的值。

### `Future<void> _pause()` <a id="pause"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 277 行）
- **用途：** 暂停秒表，把刚流逝的运行段折进 `_accumulated`。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_accumulated`/`_startedAt`/`_running`；取消滴答器；持久化会话。
- **算法：**
  1. 运行中且 `_startedAt` 有效时，把 `DateTime.now().difference(_startedAt!)` 加进 `_accumulated`。
  2. 清除 `_startedAt`、设 `_running = false`、取消 `_ticker`。
  3. `setState(() {})`；`await _persistState(timerSessionChanged: true)`。
- **用法：**
  ```dart
  // build, line 708-710:
  OutlinedButton.icon(
    onPressed: () => _pause(),
    icon: const Icon(Icons.pause),
    label: Text(l10n.intimacyPause),
  ),
  ```
- **备注：** `_saveRecord`（不从历史预填恢复时）也内部调用它，使保存运行中计时器先经同一累积逻辑干净停止。

### `Future<void> _changeThrustCount(int delta)` <a id="changethrustcount"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 293 行）
- **用途：** 按带符号增量调整抽吸计数器（`+100`/`+50`/`+10`/`-100` 按钮）。
- **输入：** `delta` — 要应用的带符号变更。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_thrustCount`；持久化会话。
- **算法：** `next = (_thrustCount + delta).clamp(0, 999999).toInt()`；未变时提前返回；否则 `setState` 新计数并 `await _persistState(timerSessionChanged: true)`。
- **用法：**
  ```dart
  // build, lines 647-666 (the four buttons):
  OutlinedButton.icon(
    onPressed: _thrustCount > 0 ? () => _changeThrustCount(-100) : null,
    icon: const Icon(Icons.remove),
    label: const Text('-100'),
  ),
  FilledButton.icon(
    onPressed: () => _changeThrustCount(100),
    icon: const Icon(Icons.add),
    label: const Text('+100'),
  ),
  ```
- **备注：** `clamp(0, ...)` 正是保证 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 描述的"非负抽插计数器"不变量的东西；`-100` 按钮本身在 UI 中 `_thrustCount == 0` 时额外禁用。

### `int _actualThrustCount(int count, int unit)` <a id="actualthrustcount"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 305 行）
- **用途：** 把存储的 `(count, unit)` 对——如从持久化会话或历史条目读取的——转换回活动计数器的实际次数计数。
- **输入：** `count`、`unit` — 存储值（`unit` 总是规范化为 `1` 或 `100`）。
- **返回：** `int` — 实际次数计数。
- **副作用：** 无。
- **算法：** `count <= 0` 返回 `0`；否则 `unit == 1 ? count : count * unit`（如存储为 `x100` 的计数 `3` 展开回 `300`）。
- **用法：**
  ```dart
  // initState, line 145-148 (restoring a session):
  _thrustCount = _actualThrustCount(session.thrustCount, session.thrustCountUnit);

  // _confirmRestoreHistory, line 568-571 (restoring from history):
  _thrustCount = _actualThrustCount(entry.thrustCount, entry.thrustCountUnit);
  ```
- **备注：** 这是 `_storedThrustCount`/`_storedThrustCountUnit` 的精确逆——它们一起实现 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 的 x100/x1 存储规则。

### `int get _storedThrustCountUnit` <a id="storedthrustcountunit"></a>
- **种类：** `_TimerPageState` 的 getter
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 315 行）
- **用途：** 决定当前活抽插计数必须存为精确 `x1` 值还是紧凑 `x100` 估计。
- **输入：** 无（读取 `_thrustCount`）。
- **返回：** `int` — `1` 或 `100`（`_estimatedThrustUnit`）。
- **副作用：** 无。
- **算法：** `_thrustCount > 0 && _thrustCount % _estimatedThrustUnit != 0 ? 1 : _estimatedThrustUnit`——任何不是 100 干净倍数的正计数必须精确存储（单位 `1`）；零或 100 的精确倍数存为单位 `100`。
- **用法：**
  ```dart
  // _timerSession getter, line 386:
  thrustCountUnit: _storedThrustCountUnit,

  // _saveRecord, line 450:
  prefillEntry?.thrustCountUnit ?? _storedThrustCountUnit,
  ```
- **备注：** 因为按钮是 `+100`/`+50`/`+10`/`-100`，除重复 `+100`/`-100` 外的任何组合（如一次 `+50`）立即把计数推出 100 的倍数，该会话其余时间切换为精确 `x1` 存储。

### `int get _storedThrustCount` <a id="storedthrustcount"></a>
- **种类：** `_TimerPageState` 的 getter
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 325 行）
- **用途：** 计算实际要持久化的计数值，与 `_storedThrustCountUnit` 一致。
- **输入：** 无（读取 `_thrustCount`）。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `_storedThrustCountUnit == 1` 时逐字存储 `_thrustCount`（精确）；否则存储 `_thrustCount ~/ _estimatedThrustUnit`（百的计数）。
- **用法：**
  ```dart
  // _saveRecord, line 448 and _timerSession, line 385:
  thrustCount: _storedThrustCount,
  ```
- **备注：** 活计数 `250`（不是 100 的干净倍数）以单位 `1`、计数 `250` 精确存储——绝不向下舍入为 2 个百，那会静默丢失 50 次。

### `Future<void> _reset()` <a id="reset"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 342 行）
- **用途：** 完全清除秒表——已流逝时间和抽插次数——回到新鲜、未开始状态。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 清除 `_accumulated`/`_firstStartedAt`/`_startedAt`/`_running`/`_thrustCount`；取消滴答器；持久化（现在为空的）会话。
- **算法：** 清零每个计时器字段、取消 `_ticker`、`setState(() {})`，然后 `await _persistState(timerSessionChanged: true)`——它持久化 `null` 会话快照，因为 `_firstStartedAt` 为 `null` 后 `_timerSession` 返回 `null`。
- **用法：**
  ```dart
  // build, line 755-759 (only shown once paused with elapsed time):
  TextButton.icon(
    onPressed: () => _reset(),
    icon: const Icon(Icons.refresh),
    label: Text(l10n.intimacyReset),
  ),
  ```
- **备注：** 这是"停止并保存"会话之后按 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 稍后清除的方式——虽然实践中 `_saveRecord` 已在成功保存时直接清除相同字段；`_reset` 是显式的丢弃不保存路径。

### `void _ensureTicker()` <a id="ensureticker"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 358 行）
- **用途：** （重新）启动让显示已流逝时间在秒表运行中持续推进的一秒周期计时器。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 取消任何既有 `_ticker`；启动每秒调用 `setState(() {})` 的新 `Timer.periodic`。
- **算法：** `_ticker?.cancel(); _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));`——回调除强制重建外不做任何工作；实际已流逝值总是来自挂钟 `_elapsed` getter，不是此计时器递增的计数器。
- **用法：**
  ```dart
  // _start, line 267:
  _ensureTicker();

  // initState, line 149 (restoring a running session):
  if (_running) _ensureTicker();
  ```
- **备注：** 因为滴答器只触发重绘、自己从不跟踪时间，错过滴答（如应用挂起期间）不产生漂移——下一个滴答只是重绘正确的挂钟派生已流逝时间。

### `IntimacyTimerSession? get _timerSession` <a id="timersession"></a>
- **种类：** `_TimerPageState` 的 getter
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 377 行）
- **用途：** 为 `_persistState`/页面 `TimerPageResult` 构建当前秒表状态的可持久化快照。
- **输入：** 无（读取计时器字段加 `_storedThrustCount`/`_storedThrustCountUnit`）。
- **返回：** `IntimacyTimerSession?` — 无可恢复会话时为 `null`。
- **副作用：** 无。
- **算法：** `_firstStartedAt == null` 时返回 `null`（无可恢复——"停止并清除"状态）。否则构建带 `firstStartedAt`、`startedAt: _running ? _startedAt : null`、`accumulated`、`running: _running` 和当前 `_storedThrustCount`/`_storedThrustCountUnit` 的 `IntimacyTimerSession`。
- **用法：**
  ```dart
  // _persistState, line 406:
  session: _timerSession,

  // _popWithHistoryIfChanged, line 427:
  updatedTimerSession: _timerSession,
  ```
- **备注：** 暂停会话的 `startedAt` 在快照中显式为 `null`，即使 `_startedAt` 可能仍持有暂停前的过期内存值——getter 总是从当前 `_running` 标志派生 `startedAt`，而不是复用 `_startedAt` 碰巧含有的任何东西。

### `Future<void> _persistState({bool historyChanged = false, bool timerSessionChanged = false, bool retentionChanged = false})` <a id="persiststate"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 395 行）
- **用途：** 只在有实际变化时把每个影响计时器的操作桥接到调用方的持久化回调。
- **输入：** 历史、计时器会话和保留的三个独立变更标志。
- **返回：** `Future<void>`。
- **副作用：** 更新对应 `_historyChanged`/`_timerSessionChanged`/`_retentionChanged` 粘性标志（稍后 `_popWithHistoryIfChanged` 使用）；调用 `widget.onStateChanged(...)`。
- **算法：**
  1. 把每个传入标志 OR 进对应粘性字段（一旦设置，标志在页面剩余生命周期保持设置，即使跨多次调用）。
  2. *本次*调用三个标志都不为 true 时不做任何调用回调地返回（避免空操作写入）。
  3. 否则 `await widget.onStateChanged(history: _history, session: _timerSession, historyChanged: historyChanged, timerSessionChanged: timerSessionChanged, retentionDays: _retentionDays, retentionChanged: retentionChanged)`——注意回调收到的是本次调用的标志，不是粘性累积的。
- **用法：**
  ```dart
  // _start, line 269:
  await _persistState(timerSessionChanged: true);

  // views/intimacy_page.dart's _saveTimerState (the onStateChanged implementation), consumed via:
  onStateChanged: _saveTimerState,
  ```
- **备注：** 这正是让"状态在用户操作时写入、不在每个显示的计时器滴答时写入"成立的东西——每秒一次的 `_ensureTicker` 回调绝不调用 `_persistState`，只有离散操作（`_start`、`_pause`、`_changeThrustCount`、`_reset`、`_saveRecord`、`_confirmRestoreHistory`、保留选择器）才调用。

### `void _popWithHistoryIfChanged()` <a id="popwithhistoryifchanged"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 421 行）
- **用途：** 关闭页面，只在确有调用方要持久化的东西时返回 `TimerPageResult`。
- **输入：** 无。
- **返回：** 无。
- **副作用：** `Navigator.pop`，带或不带 `TimerPageResult` 参数。
- **算法：** `_historyChanged`/`_timerSessionChanged`/`_retentionChanged` 任一为 true 时，带携带 `_history`、`_timerSession`、`_retentionDays` 和三个变更标志的 `TimerPageResult` 弹出；否则不带任何结果弹出。
- **用法：**
  ```dart
  // build, line 593-598 (PopScope intercepts the back gesture/button):
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      _popWithHistoryIfChanged();
    },
    ...
  );
  ```
- **备注：** `canPop: false` 加此处理器让页面拦截每次弹出尝试（含系统返回手势），保证脏会话在出去的路上绝不被静默丢弃——这是 `_saveRecord` 显式保存流程之外的第二层、页面级安全网。

### `Future<void> _saveRecord({TimerHistoryEntry? prefillEntry})` <a id="saverecord"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 446 行）
- **用途：** 经 `AddRecordDialog` 把当前秒表（或重新打开的历史条目）变成 `IntimacyRecord`。
- **输入：** `prefillEntry` — 非 null 时从既有历史条目而不是活计时器保存（点击历史行而不是停止/保存按钮）。
- **返回：** `Future<void>`。
- **副作用：** 可能暂停活计时器；可能插入新历史条目并持久化它；打开 `AddRecordDialog`；成功保存时可能清除活计时器会话并持久化；带 `TimerPageResult` 弹出页面。
- **算法：**
  1. 从 `prefillEntry`（若给）解析 `elapsed`/`prefillThrustCount`/`prefillThrustCountUnit`/`sessionStart`，否则从活 `_elapsed`/`_storedThrustCount`/`_storedThrustCountUnit`/`_sessionStartTime`（无记录开始时回退 `DateTime.now().subtract(elapsed)`）。
  2. `prefillEntry == null` 时先 `await _pause()`（干净停止活计时器）。
  3. `prefillEntry == null` 时从活会话构建新 `TimerHistoryEntry`、插入 `_history` 前部、重新应用保留、标记历史已变并 `await _persistState(historyChanged: true)`——使即使随后取消记录对话框，历史行也存在。
  4. `await showDialog<IntimacyRecord>(... AddRecordDialog(prefillDuration: elapsed, initialThrustCount: prefillThrustCount > 0 ? prefillThrustCount : null, ...))`。
  5. 返回记录时：若为活计时器保存（`prefillEntry == null`），把每个计时器字段清除到重置状态并 `await _persistState(timerSessionChanged: true)`——历史预填保存不碰活计时器。
  6. 带携带记录、更新历史、更新（可能现在为 null 的）计时器会话和对应变更标志的 `TimerPageResult` 弹出。
- **用法：**
  ```dart
  // build, line 719-722 (Stop & Save while running):
  FilledButton.icon(
    onPressed: () => _saveRecord(),
    icon: const Icon(Icons.stop),
    label: Text(l10n.intimacyStopSave),
  ),

  // build, line 823 (tapping a history row to re-save it):
  onTap: () => _saveRecord(prefillEntry: entry),
  ```
- **备注：** 第 3 步对历史条目的提前持久化（对话框打开前）意味着即使未完成 `AddRecordDialog` 就退出，本次会话的历史行也存在——只有记录本身丢失，不是计时器的历史痕迹。

### `String _formatDuration(Duration d)` <a id="formatduration"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 519 行）
- **用途：** 把时长格式化为零填充 `HH:MM:SS` 字符串，供主计时器显示和历史行。
- **输入：** `d` — 要格式化的时长。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** `hours = d.inHours`（无界，不是 mod-24）、`minutes = d.inMinutes % 60`、`seconds = d.inSeconds % 60`，各 `padLeft(2, '0')`，用 `:` 连接。
- **用法：**
  ```dart
  // build, line 626 (the big display) and line 812 (each history row):
  Text(_formatDuration(_elapsed), ...),
  Text(_formatDuration(entry.duration), ...),
  ```
- **备注：** `hours` 不以 24 取模，因此超过一天的会话（无论多么不可能）显示为如 `26:14:03` 而不是回卷为 `02:14:03`。

### `Future<void> _confirmRestoreHistory(TimerHistoryEntry entry)` <a id="confirmrestorehistory"></a>
- **种类：** `_TimerPageState` 的方法
- **来源：** `lib/features/intimacy/widgets/timer_page.dart`（第 539 行）
- **用途：** 确认后让用户把保存的历史条目变回活运行秒表。
- **输入：** `entry` — 要恢复的历史条目。
- **返回：** `Future<void>`。
- **副作用：** 打开确认 `AlertDialog`；从 `_history` 移除 `entry`；覆盖每个活计时器字段；重启滴答器；持久化历史和计时器会话变更。
- **算法：**
  1. 显示是/否 `AlertDialog`；用户未确认或 await 期间组件已卸载时返回。
  2. 取消当前滴答器（无论活计时器先前状态如何）。
  3. 在 `setState` 内：从 `_history` 移除 `entry`、标记 `_historyChanged`；设 `_firstStartedAt = entry.start`、`_startedAt = DateTime.now()`（新恢复点）、`_accumulated = entry.duration`（条目的保存已流逝时间成为新累积基础）、`_running = true`；经 `_actualThrustCount(entry.thrustCount, entry.thrustCountUnit)` 恢复 `_thrustCount`；标记 `_timerSessionChanged`。
  4. `_ensureTicker()`；`await _persistState(historyChanged: true, timerSessionChanged: true)`。
- **用法：**
  ```dart
  // build, line 824-828 (the restore icon on each history row):
  IconButton(
    tooltip: l10n.intimacyTimerRestore,
    icon: const Icon(Icons.restore, size: 20),
    onPressed: () => _confirmRestoreHistory(entry),
  ),
  ```
- **备注：** 匹配 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence)："历史行可以确认为运行中会话并恢复，这会移除该历史行。"确认对话框上的源码注释说明"确认对话框打开时任何当前运行计时器继续滴答"——活计时器不会只因正在考虑恢复就被暂停。

## 相关页面

- [亲密 — 计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence) — 运行/暂停/停止恢复契约、x100/x1 抽插次数存储规则和本文件完整实现的保持屏幕唤醒偏好。
- [`add_record_dialog.dart`](add_record_dialog.md) — `AddRecordDialog`，由 `_saveRecord` 打开并从完成（或重新打开）的秒表会话预填。
- `shared/services/sync_wake_lock.dart` — 前台同步操作使用的独立、引用计数唤醒锁；这里的 `_applyWakelock`/`_releaseWakelock` 绝不干扰它，因为各自跟踪自己的"我启用它了吗"标志。
