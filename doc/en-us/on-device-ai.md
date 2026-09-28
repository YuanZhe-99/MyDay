# On-device AI

Since 1.5.0, MyDay!!!!! can use the device's own language model — Gemini Nano through Android
AICore, or Apple Intelligence's model through the Foundation Models framework — to write a short
**insight card** on each module page: today's plan, progress or review on Todo; the income and
spending trend and the subscriptions on Finance; the trend on Weight; the trend and the body
condition on Intimacy. This page holds the rules, how the code is laid out, what each card is
given, how results are cached, and what still has to be checked on a device.

The model layer is a port of MyAnime!!!!!'s (1.6.x), which is itself a port of MyNihongo!!!!!'s;
the insight cards are MyDay's own.

> **Last verified:** 2026-09-28, against MyAnime's verified port and the published libraries.
> **Not verified on a device.** Neither an Android device with AICore nor an Apple device with
> Apple Intelligence has run this code yet; the [device checklist](#device-checklist) is what to do
> when one is available. The Android bridge has run on a Pixel 10 and a Galaxy Z Fold 8 in
> MyNihongo.

## Policy

Rules 1–3, 7 and 8 are enforced in `OnDeviceAiService` and covered by
`test/on_device_ai_test.dart` and `test/ai_settings_tiles_ui_test.dart`. Rules 4–6 and 9 are
enforced by the insight layer and covered by `test/insight_service_test.dart`,
`test/insight_facts_test.dart`, `test/ai_insights_cache_test.dart` and
`test/ai_insight_card_ui_test.dart`.

1. **Off by default.** `onDeviceAiEnabled` is absent from `storage_config.json` until the user turns
   the switch on.
2. **The switch is a gate.** While it is off, the method channel is never called, not even for
   status, and every card renders nothing.
3. **Status is re-checked before every request.** The system can remove a model between two
   requests.
4. **Generated output is labelled** "Generated on this device — may be wrong".
5. **The page comes first.** A card only adds text under data the page already shows; when the
   model fails, the page is unchanged.
6. **Nothing generated is synced or backed up.** Results live in `ai_insights.json`, which is not
   registered in `lib/app/data_modules.dart`.
7. **Nothing is downloaded on the user's behalf.** On Android the model download starts only from
   the Download button in Settings and is performed by AICore; on Apple platforms the system
   manages the model.
8. **On-device only.** Never Apple's Private Cloud Compute and never any other remote model.
9. **Only computed facts reach the model.** Cards are built from aggregates the app computes; see
   [what each card is given](#insight-cards). Free-text notes never reach the model.

Both Android flavors ship the feature: it makes no network call of its own. On Windows (and any
other platform without an on-device model) the cards are never built, and the Settings section is a
single "not available on this platform" line.

## Layout

| Path | Role |
|---|---|
| `lib/features/ai/services/genai_backend.dart` | The Dart seam: `GenAiStatus`, `GenAiFailure`, `GenAiStatusReport`, `GenAiCoreInfo`, the `GenAiBackend` interface and `MethodChannelGenAiBackend` |
| `lib/features/ai/services/on_device_ai_service.dart` | `OnDeviceAiService`: the switch, status before every use, the single-flight priority queue, the 45-second timeout, lifecycle, busy backoff and the daily quota stop |
| `lib/features/ai/services/output_validation.dart` | Stripping Markdown, the script check, cleaning one sentence, parsing a choice reply |
| `lib/features/ai/services/insight_language.dart` | `InsightLanguage`: the request language for the UI locale, and Chinese variant conversion |
| `lib/features/ai/services/insight_prompts.dart` | `InsightModule`, `InsightTimeBucket`, `InsightFacts`, the versioned instructions and prompt, and the reply parser |
| `lib/features/ai/services/ai_insights_cache.dart` | `AiInsightsCache`: `ai_insights.json`, the per-device cache |
| `lib/features/ai/services/insight_service.dart` | `AiInsightStore`: the fingerprint, cache-or-generate, coalescing, failure handling |
| `lib/features/ai/widgets/ai_insight_card.dart` | `AiInsightCard`: the card and all its states |
| `lib/features/ai/widgets/ai_settings_tiles.dart` | `AiSettingsTiles`: the switch, the status row, the size preference, the notes, technical details and *Clear generated insights* |
| `lib/features/todo/services/todo_insight_facts.dart` | Todo facts, by time bucket |
| `lib/features/finance/services/finance_insight_facts.dart` | Finance facts |
| `lib/features/weight/services/weight_insight_facts.dart` | Weight facts |
| `lib/features/intimacy/services/intimacy_insight_facts.dart` | Intimacy facts and body condition |
| `lib/shared/utils/chinese_convert.dart` | Simplified ↔ Traditional conversion, copied from MyAnime |
| `android/app/src/main/kotlin/com/yuanzhe/my_day/GenAiChannel.kt` | The Android bridge to ML Kit GenAI |
| `packages/on_device_ai_apple/` | A local Flutter plugin with one shared Darwin source for iOS and macOS |

The Settings section *On-device AI* sits between *Privacy* and *Desktop*. The switches are stored
as `onDeviceAiEnabled` and `onDeviceAiPreferFast` in `storage_config.json` (see
[`data-formats.md`](data-formats.md)); `AppSettingsNotifier` pushes both into
`OnDeviceAiService` at startup, and `main()` starts the service's lifecycle listener.

The channel is `com.yuanzhe.my_day/genai` on all three platforms. Its methods are `status`
(`force`, `preferFast`), `info` (`locale`), `download` (Android only), `generate` (`instructions`,
`prompt`, `maxOutputTokens`, `temperature`, `topK`), `choose` (Apple only; unused by MyDay but kept
so the plugin matches MyAnime's), `prewarm` and `cancel`. `platformMayHaveOnDeviceModel` is true on
Android, iOS and macOS; on every other platform the backend answers `unsupported` without touching
the channel. A `MissingPluginException` on iOS or macOS is reported as `unreachable` with the detail
"channel not registered", never as `unsupported`, so a plugin that failed to register is noticed.

### Statuses and failures

| Status | Meaning |
|---|---|
| `unsupported` | This platform has no on-device model (Windows, Linux, iOS or macOS before 26) |
| `unavailable` | The system was asked and said no |
| `unreachable` | The system could not be asked at all |
| `notEnabled` | Apple Intelligence is off in system settings |
| `downloadable` | Android: the model can be fetched by AICore |
| `downloading` | The model is being fetched or prepared (Apple's `modelNotReady` too) |
| `available` | Ready |
| `unknown` | A status this build has no name for |

Failures are `unavailable`, `busy`, `failed`, `cancelled`, `tooLong`, `timeout`, `background`,
`quota`, `guardrail` and `unsupportedLanguage`.

### The queue

One request runs at a time. A card generated because its page opened is a **background** request;
the card's refresh button is **interactive** and goes first. Nothing runs unless the app is
`AppLifecycleState.resumed`. After `busy`, background work waits 5 seconds, doubling up to 5
minutes; after `quota`, background work stops for the rest of the day; after `background`, the
queue waits for the next resume.

## Insight cards

Each card is an `AiInsightCard` placed on its page. It renders nothing while the switch is off or
on a platform without a model, so every existing layout is unchanged then. While the model is not
ready (needs a download, Apple Intelligence off, …) it is a one-line notice with a *Settings*
button. Otherwise it shows a header with a refresh button, a thin progress bar while generating,
the lines (older lines dimmed while newer ones are generated), and the label and time.

| Page | Where | Slots |
|---|---|---|
| Todo | After the daily score card; in the last column when sections sit side by side. Only while today is selected. | Morning (before 12:00): `plan`, `first`, `tip`. Afternoon (12:00–18:00): `progress`, `remaining`, `tip`. Evening (from 18:00): `summary`, `tomorrow`, `encouragement`. |
| Finance | After the upcoming-renewals strip. Collapsed to one preview line in the stacked (phone) layout; full in the left pane of the split layout. | `flowSummary`, `flowAdvice` under *Income & spending*; `subSummary`, `subAdvice` under *Subscriptions*. |
| Weight | Between the summary card and the charts. | `trend`, `advice`. |
| Intimacy | After the trend chart, only while on-device AI is on. | `trend`, `advice` under *Trend* (when there are records); `body` under *Body condition* (when there are body facts). A cycle disclaimer is shown when the user tracks their cycle. |

### What each card is given

Facts are English `- key: value` lines computed by a pure builder, rounded so that a fingerprint
does not change with float noise. The model is asked to answer each numbered request with one
sentence under 30 words in the UI language, using only the facts, with no medical, legal or
investment advice and no invented numbers.

| Card | Sent | Never sent |
|---|---|---|
| Todo | The date; titles of today's daily habits and one-off tasks (trimmed to 40 characters, at most 12 per line); whether each is done, carried over, overdue, and its reminder time; counts; the self-rating; tomorrow's tasks in the evening | Task notes, subtask titles |
| Finance | Income and spending per month for this month and the three before, in the default currency; the top three spending categories this month and last; the total across accounts; subscription count, cost and the costliest names; renewals in the next 7 days | Card numbers, expiry dates, security codes, bank or account names, transaction and subscription notes |
| Weight | Latest weight and date, height, BMI, change over 7/30/90 days, recent range, weigh-in count, body fat, bust/waist/hip carried forward, waist-to-hip ratio | Record notes |
| Intimacy | For the last 30 days and the 30 before: counts (partnered vs solo), average rating, average timed length, climax rate, protection rate; 90-day count; days since the last entry; the user's bust/waist/hip (from Weight), underbust and estimated bra size; when the user tracks their own cycle: typical length, last start, today's estimated phase and fertile window, days to the next estimated start | Notes, locations, partner, toy and position names, thrust counts, the porn flag, genital measurements, partners' cycles |

The Intimacy exclusions are for privacy and to stay inside the on-device models' acceptable-use
rules; a `guardrail` refusal is cached as *skipped* so it is not retried until the facts change.

### Language

`InsightLanguage.forLocale` picks the request language from the UI locale: Simplified Chinese
(converted to Simplified), Traditional Chinese (converted to Traditional), Japanese, or English.
When Apple's `supportsLocale` rejects Traditional Chinese, Simplified is requested and converted;
when it rejects any other UI language, the card says the model cannot write in it. A reply line is
kept only when its script matches the UI language (at least 60 % CJK for Chinese and Japanese,
Latin otherwise); user-typed words listed as *quoted terms* (task titles, category and subscription
names) are removed before that check so a Chinese sentence quoting an English title is kept.

## Cache and fingerprint

Results are cached in `ai_insights.json` in the app data folder (see
[`data-formats.md`](data-formats.md#ai_insightsjson)). A card is regenerated **only** when its
fingerprint changes. The fingerprint is the SHA-256 of:

- the module,
- `insightPromptVersion` (bump it whenever prompt wording or a builder's output changes),
- the request language tag,
- the local date (so every card is refreshed at most once a day by time alone),
- the model identity (`variant · baseModelName`, or `apple`),
- the canonical facts, which include Todo's time bucket.

So a card updates when its data changes (a task ticked, a transaction added, a weigh-in), when the
day changes, when Todo crosses 12:00 or 18:00, after a model update, or when the UI language
changes — and at no other time. The card arms a timer to the next boundary so a page left open
also updates.

`AiInsightStore` keeps at most one generation per card running or waiting: a request that arrives
meanwhile replaces the pending one, so ticking several tasks in a row costs at most one extra run,
and a result whose facts are no longer current is discarded. A `failed`, `timeout` or unparseable
reply is not cached and is retried only by the refresh button or by new facts, so it cannot loop;
`busy`, `background`, `cancelled` and `unavailable` are retried on the next page build. *Clear
generated insights* in Settings deletes the file.

## Android: ML Kit GenAI over AICore

- `com.google.mlkit:genai-prompt:1.0.0-beta4`, the same version as MyAnime. The Structured Output API
  is **not** used.
- API 26 or later, so the app's `minSdk` is 26 since 1.5.0 (Android 7.0 and 7.1 are dropped). The
  APIs refuse to run on an unlocked bootloader. Input must stay under about 4,000 tokens; every card
  prompt is far below that.
- Inference is allowed only while the app is the top foreground app; background use fails with
  `BACKGROUND_USE_BLOCKED` (→ `background`). AICore enforces a per-app quota: `BUSY` (→ `busy`) and
  `PER_APP_BATTERY_USE_QUOTA_EXCEEDED` (→ `quota`).
- `GenAiChannel.probePrompt` tries all four combinations of `ModelReleaseStage` (STABLE, PREVIEW) and
  `ModelPreference` (FULL, FAST) and keeps the first that serves. Settings offers "Use the faster
  model" only when both sizes are served.
- Instructions are sent as a `SystemInstruction` where the model reports `isSystemPromptAvailable`,
  and prepended to the prompt otherwise.
- `android/app/proguard-rules.pro` carries the two keep rules that R8 needs for ML Kit, and the
  release build type lists it with `proguardFiles`.
- `AndroidManifest.xml` has a `<queries>` entry for `com.google.android.aicore` so `info` can read
  AICore's version.
- `MainActivity` attaches `GenAiChannel` in `configureFlutterEngine` and detaches it in
  `onDestroy`.
- Toolchain: AGP 9.1.1, Kotlin Gradle Plugin 2.2.20, `android.builtInKotlin=false`, the same as
  MyAnime.
- Log tag: `MyDayGenAi`. Exceptions are logged, prompts never are.

## Apple: the Foundation Models framework

- iOS, iPadOS and macOS 26.0 or later. `SystemLanguageModel.default.availability` is `.available`
  or `.unavailable(reason)` with `deviceNotEligible`, `appleIntelligenceNotEnabled` or
  `modelNotReady`; availability also depends on the region.
- A new `LanguageModelSession(instructions:)` per request, so earlier turns cannot leak into later
  answers.
- The listed languages include en-US, ja-JP and zh-CN; Traditional Chinese is not listed, see
  [Language](#language).
- The context window is 4,096 tokens. Background calls are rate limited.
- Errors: `rateLimited` → `quota`, `concurrentRequests` → `busy`, `guardrailViolation` and
  `refusal` → `guardrail`, `unsupportedLanguageOrLocale` → `unsupportedLanguage`,
  `exceededContextWindowSize` → `tooLong`, `assetsUnavailable` → `unavailable`, anything else →
  `failed`.
- CI builds with the `macos-latest` image's default Xcode (26.x).
- No entitlement, `Info.plist` key or usage description is needed, and the Private Cloud Compute
  entitlement is deliberately absent.

### Weak linking

The deployment targets stay iOS 13.0 and macOS 13.0. Every FoundationModels reference is behind
`#if canImport(FoundationModels)` and `@available(iOS 26.0, macOS 26.0, *)`, and the podspec declares
`s.weak_frameworks = 'FoundationModels'`. An app that strong-links the framework will not launch on
iOS 18 or macOS 15 and earlier, so this is **checked, not assumed**: `tool/check_weak_link.sh`
fails a CI build unless every binary that links FoundationModels uses `LC_LOAD_WEAK_DYLIB`, and
also fails when nothing links it (the plugin did not make it into the build). See
[`ci-cd.md`](ci-cd.md).

## Store policy

Google Play's AI-Generated Content policy treats productivity apps that use AI to improve an
existing feature as out of scope; the output is still labelled. Apple's acceptable-use requirements
for Foundation Models prohibit generating adult content; the Intimacy card sends only neutral
statistics and asks for neutral wording.

## Device checklist

Run this when a device becomes available, and update **Last verified** above.

1. With the switch off, confirm nothing touches the model (logcat tag `MyDayGenAi` stays silent)
   and no card appears.
2. Turn the switch on; check the status row, the technical details and, on Android, the AICore
   version and the served and refused variants.
3. Android: Download, with progress in MB; the status becomes available.
4. Open each module page; each card generates once, then reopening the page shows the cached text
   without the progress bar.
5. Tick a task; the Todo card regenerates. Cross 12:00 or 18:00 with the page open; the mode changes.
6. Check all four UI languages; lines arrive in the right script, and Traditional Chinese is
   converted where the model answers in Simplified.
7. Intimacy: confirm the model answers rather than refusing; if it refuses, the card says so once
   and does not retry.
8. Send the app to the background mid-request; it resumes cleanly.
9. Repeat 2–8 on a **release** build (R8).
10. Apple: turn Apple Intelligence off in system settings; the card and the row say so.
11. Apple: install on an iOS 18 or macOS 15 device, or boot one in a simulator, and confirm the app
    launches.

## How to refresh this page

1. Compare `genai-prompt` against the Google Maven group index
   (`https://dl.google.com/android/maven2/com/google/mlkit/group-index.xml`) and the ML Kit release
   notes, and against MyAnime's `doc/en-us/on-device-ai.md`.
2. Re-read the Foundation Models documentation for the current SDK and the runner image's default
   Xcode.
3. After changing any prompt wording or fact builder, bump `insightPromptVersion`.
4. Update **Last verified** and the facts above in both languages.
