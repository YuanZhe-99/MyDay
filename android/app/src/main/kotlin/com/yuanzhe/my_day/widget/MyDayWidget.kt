package com.yuanzhe.my_day.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeStore
import com.yuanzhe.myapps_widget.WidgetEnvelope
import com.yuanzhe.myapps_widget.WidgetEnvelopeStatus
import com.yuanzhe.myapps_widget.WidgetLaunch
import com.yuanzhe.myapps_widget.WidgetPrivacy
import com.yuanzhe.myapps_widget.setScaledTextSize
import org.json.JSONArray
import org.json.JSONObject

/**
 * One readable MyDay envelope: the app-owned payload plus the fields every renderer needs.
 * The payload formats are documented in `doc/en-us/features/home-screen-widgets.md` and built by
 * `lib/shared/services/home_widget_payloads.dart`.
 */
class WidgetContent(
    val kind: String,
    val payload: JSONObject,
    val textScale: Float,
    /** True for the *Hide values* privacy choice: numbers and amounts are drawn as dots. */
    val mask: Boolean,
    private val labels: Map<String, String>,
) {
    /**
     * Purpose: Return a payload label, falling back to English.
     * Inputs: `key` — a key of the payload's `labels` object.
     * Returns: The label text; empty when neither the payload nor the fallback has it.
     * Side effects: None.
     * Notes: Fallbacks cover a payload written by an older app build.
     */
    fun label(key: String): String =
        labels[key]?.takeIf { it.isNotEmpty() } ?: MyDayWidget.FALLBACK_LABELS[key] ?: ""

    /**
     * Purpose: Return a label with its `{n}` and `{m}` placeholders replaced.
     * Inputs: `key`; `n` — the `{n}` value; `m` — the `{m}` value, or null to leave it.
     * Returns: The filled label.
     * Side effects: None.
     * Notes: Placeholders are written by the Dart builders as literal `{n}` / `{m}`.
     */
    fun label(key: String, n: String, m: String? = null): String {
        val filled = label(key).replace("{n}", n)
        return if (m == null) filled else filled.replace("{m}", m)
    }

    /**
     * Purpose: Mask a number when the privacy choice hides values.
     * Inputs: `text` — the formatted number.
     * Returns: `text`, or `••` when masked.
     * Side effects: None.
     * Notes: Use for counts, weights, minutes and days.
     */
    fun number(text: String): String = if (mask) MyDayWidget.MASK_NUMBER else text

    /**
     * Purpose: Mask an amount when the privacy choice hides values.
     * Inputs: `text` — the formatted amount.
     * Returns: `text`, or `••••` when masked.
     * Side effects: None.
     * Notes: Use for money.
     */
    fun amount(text: String): String = if (mask) MyDayWidget.MASK_AMOUNT else text

    /**
     * Purpose: Return the payload's applied action ids.
     * Inputs: None.
     * Returns: The ids the app already folded into this payload.
     * Side effects: None.
     * Notes: Renderers skip these when replaying the pending-action queue.
     */
    fun appliedActions(): Set<String> {
        val array = payload.optJSONArray("appliedActions") ?: return emptySet()
        return (0 until array.length()).mapNotNull { array.opt(it) as? String }.toSet()
    }

    companion object {
        /**
         * Purpose: Build the content of a readable envelope.
         * Inputs: `kind`; `envelope` — an `OK` read.
         * Returns: `WidgetContent`.
         * Side effects: None.
         * Notes: Non-string label values are ignored.
         */
        fun from(kind: String, envelope: WidgetEnvelope): WidgetContent {
            val labels = mutableMapOf<String, String>()
            envelope.payload.optJSONObject("labels")?.let { o ->
                o.keys().forEach { key -> (o.opt(key) as? String)?.let { labels[key] = it } }
            }
            return WidgetContent(
                kind = kind,
                payload = envelope.payload,
                textScale = envelope.textScale,
                mask = envelope.payload.optBoolean("mask", false),
                labels = labels,
            )
        }
    }
}

/** Outcome of loading a kind: drawable content or the neutral placeholder's text. */
sealed class WidgetLoad {
    /** A readable, visible envelope. */
    data class Ready(val content: WidgetContent) : WidgetLoad()

    /** Missing, invalid, too new or hidden: show the placeholder with [text]. */
    data class Placeholder(val text: String) : WidgetLoad()
}

/** Kinds, provider names, deep links and shared drawing helpers of the MyDay widgets. */
object MyDayWidget {
    const val KIND_TODO = "myday.todo"
    const val KIND_WEIGHT = "myday.weight"
    const val KIND_FINANCE = "myday.finance"
    const val KIND_INTIMACY = "myday.intimacy"
    const val KIND_TIMER = "myday.timer"

    /** Number mask of the *Hide values* privacy choice. */
    const val MASK_NUMBER = "••"

    /** Amount mask of the *Hide values* privacy choice. */
    const val MASK_AMOUNT = "••••"

    /** Real minus sign for signed changes. */
    const val MINUS = "−"

    /** Request-code slots, combined with the widget id by [requestCode]. */
    const val SLOT_ROOT = 0
    const val SLOT_ADD = 1
    const val SLOT_PRIMARY = 2
    const val SLOT_STEP = 3
    const val SLOT_FINISH = 4
    const val SLOT_ROWS = 16

    /** Providers redrawn after a Todo checkbox tap. */
    val TODO_PROVIDERS: List<String> = listOf(
        TodoWidgetProvider::class.java.name,
        TodoStripWidgetProvider::class.java.name,
    )

    /** Providers redrawn after a timer button tap. */
    val TIMER_PROVIDERS: List<String> = listOf(
        TimerWidgetProvider::class.java.name,
        TimerStripWidgetProvider::class.java.name,
    )

    /** English labels used when a payload lacks one. */
    val FALLBACK_LABELS: Map<String, String> = mapOf(
        "placeholder" to "MyDay",
        "stale" to "Open MyDay to update",
        "new" to "New",
        "left" to "{n} left",
        "progress" to "{n}/{m} done",
        "tomorrow" to "Tomorrow",
        "overdue" to "Overdue",
        "allDone" to "All done",
        "nothing" to "Nothing planned",
        "score" to "Day score",
        "log" to "Log",
        "unit" to "kg",
        "change30" to "30 days",
        "bmi" to "BMI",
        "notLogged" to "Not logged today",
        "noData" to "No records yet",
        "today" to "Today",
        "daysAgo" to "{n} days ago",
        "add" to "Add",
        "expense" to "Spent this month",
        "income" to "Income",
        "net" to "Balance",
        "top" to "Top spending",
        "billsSoon" to "{n} billing soon",
        "noBills" to "No bills this week",
        "month" to "{n} this month",
        "avg" to "avg {n} min",
        "cycleIn" to "Period in {n} days",
        "cycleToday" to "Period expected today",
        "running" to "Running",
        "paused" to "Paused",
        "count" to "Count {n}",
        "start" to "Start",
        "resume" to "Resume",
        "pause" to "Pause",
        "finish" to "Finish",
        "last" to "Last {n} · {m} min",
        "lastToday" to "Last today · {m} min",
        "idle" to "Not running",
    )

    /**
     * Purpose: Load a kind's envelope and decide whether it can be drawn.
     * Inputs: `context`, `kind`.
     * Returns: [WidgetLoad.Ready], or [WidgetLoad.Placeholder] with the line to show.
     * Side effects: Reads the envelope store.
     * Notes: Missing, invalid and `hidden` envelopes show "MyDay"; a too-new envelope cannot be
     * trusted for labels, so it shows the native "Open MyDay" string.
     */
    fun load(context: Context, kind: String): WidgetLoad {
        val appName = context.getString(R.string.widget_app_name)
        val read = try {
            EnvelopeStore.read(context, kind)
        } catch (e: Exception) {
            return WidgetLoad.Placeholder(appName)
        }
        return when (read.status) {
            WidgetEnvelopeStatus.OK -> {
                val envelope = read.envelope ?: return WidgetLoad.Placeholder(appName)
                if (envelope.privacy == WidgetPrivacy.HIDDEN) {
                    WidgetLoad.Placeholder(appName)
                } else {
                    WidgetLoad.Ready(WidgetContent.from(kind, envelope))
                }
            }
            WidgetEnvelopeStatus.TOO_NEW -> WidgetLoad.Placeholder(context.getString(R.string.widget_open_app))
            else -> WidgetLoad.Placeholder(appName)
        }
    }

    /**
     * Purpose: Draw a kind from its envelope, or the placeholder.
     * Inputs: `context`; `kind`; `appWidgetId`; `draw` — builds the views for readable content.
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store.
     * Notes: An exception while drawing (a malformed payload) falls back to the placeholder, so a
     * bad snapshot never leaves a broken widget.
     */
    fun render(
        context: Context,
        kind: String,
        appWidgetId: Int,
        draw: (WidgetContent) -> RemoteViews,
    ): RemoteViews = when (val result = load(context, kind)) {
        is WidgetLoad.Ready -> try {
            draw(result.content)
        } catch (e: Exception) {
            placeholder(context, kind, appWidgetId, context.getString(R.string.widget_app_name))
        }
        is WidgetLoad.Placeholder -> placeholder(context, kind, appWidgetId, result.text)
    }

    /**
     * Purpose: Build the neutral placeholder: the app icon and one line.
     * Inputs: `context`; `kind`; `appWidgetId`; `text`; `textScale` — 1 when no envelope is readable.
     * Returns: `RemoteViews` that open the kind's tab when tapped.
     * Side effects: None.
     * Notes: Also used for the Todo "Open MyDay to update" state.
     */
    fun placeholder(
        context: Context,
        kind: String,
        appWidgetId: Int,
        text: String,
        textScale: Float = 1f,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_placeholder)
        views.setScaledTextSize(R.id.widget_placeholder_text, 14f, textScale)
        views.setTextViewText(R.id.widget_placeholder_text, text)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetLaunch.pendingIntent(context, link(kind), requestCode(appWidgetId, SLOT_ROOT)),
        )
        return views
    }

    /**
     * Purpose: Build a widget deep link.
     * Inputs: `kind`; `what` — the `do` parameter or null; `extra` — further query parameters.
     * Returns: `myday://widget/<kind>[?do=<what>&…]`.
     * Side effects: None.
     * Notes: Routed by `HomeWidgetLaunch` in the app.
     */
    fun link(kind: String, what: String? = null, extra: Map<String, String> = emptyMap()): Uri {
        val builder = Uri.Builder().scheme("myday").authority("widget").appendPath(kind)
        if (what != null) builder.appendQueryParameter("do", what)
        for ((key, value) in extra) builder.appendQueryParameter(key, value)
        return builder.build()
    }

    /**
     * Purpose: Derive a PendingIntent request code unique per widget instance and control.
     * Inputs: `appWidgetId`; `slot` — one of the `SLOT_*` constants, plus a row index for rows.
     * Returns: The request code.
     * Side effects: None.
     * Notes: 64 slots per instance; rows use `SLOT_ROWS + index` and stay below 64.
     */
    fun requestCode(appWidgetId: Int, slot: Int): Int = appWidgetId * 64 + slot

    /**
     * Purpose: Wire the common taps: the widget body opens the kind's tab, the header button the
     * add dialog.
     * Inputs: `context`; `views`; `kind`; `appWidgetId`; `addId` — the add button, or null.
     * Returns: None.
     * Side effects: Mutates `views`.
     * Notes: Controls with their own PendingIntent take precedence over the root.
     */
    fun bindTaps(context: Context, views: RemoteViews, kind: String, appWidgetId: Int, addId: Int?) {
        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetLaunch.pendingIntent(context, link(kind), requestCode(appWidgetId, SLOT_ROOT)),
        )
        if (addId != null) {
            views.setOnClickPendingIntent(
                addId,
                WidgetLaunch.pendingIntent(context, link(kind, "add"), requestCode(appWidgetId, SLOT_ADD)),
            )
        }
    }

    /**
     * Purpose: Scale a list of text views by the envelope's text scale.
     * Inputs: `views`; `sizes` — view id to its size in sp at 100%; `scale`.
     * Returns: None.
     * Side effects: Mutates `views`.
     * Notes: None.
     */
    fun scaleTexts(views: RemoteViews, sizes: List<Pair<Int, Float>>, scale: Float) {
        for ((id, base) in sizes) views.setScaledTextSize(id, base, scale)
    }

    /**
     * Purpose: Set a text color from a color resource.
     * Inputs: `context`; `views`; `viewId`; `color` — a `widget_*` color resource.
     * Returns: None.
     * Side effects: Mutates `views`.
     * Notes: Android 12+ resolves the resource in the launcher, so Material You and night mode
     * follow the host; earlier versions resolve it in the app's own configuration.
     */
    fun setTextColor(context: Context, views: RemoteViews, viewId: Int, color: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColor(viewId, "setTextColor", color)
        } else {
            views.setTextColor(viewId, context.getColor(color))
        }
    }

    /**
     * Purpose: Read the instance's minimum width and height in dp.
     * Inputs: `options` — the instance's size options, possibly null.
     * Returns: Width to height; 0 when unknown.
     * Side effects: None.
     * Notes: The minimum width is the portrait width and the minimum height the landscape
     * height, the conservative pair for fitting rows.
     */
    fun size(options: Bundle?): Pair<Int, Int> = Pair(
        options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0,
        options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0,
    )

    /**
     * Purpose: Format a number with at most one decimal, dropping a trailing `.0`.
     * Inputs: `value`.
     * Returns: For example "62.4", "3".
     * Side effects: None.
     * Notes: Uses `.` as the decimal separator, like the app's weight display.
     */
    fun decimal(value: Double): String {
        val rounded = Math.round(value * 10) / 10.0
        return if (rounded == Math.floor(rounded)) rounded.toLong().toString() else rounded.toString()
    }

    /**
     * Purpose: Format a value with exactly one decimal.
     * Inputs: `value`.
     * Returns: For example "62.0".
     * Side effects: None.
     * Notes: Locale-independent.
     */
    fun oneDecimal(value: Double): String = String.format(java.util.Locale.ROOT, "%.1f", value)

    /**
     * Purpose: Format a signed change with one decimal and a real minus sign.
     * Inputs: `value`.
     * Returns: For example "−0.6", "+1.2", "0.0".
     * Side effects: None.
     * Notes: A value that rounds to zero has no sign.
     */
    fun signed(value: Double): String {
        val text = oneDecimal(Math.abs(value))
        return when {
            text == oneDecimal(0.0) -> text
            value < 0 -> "$MINUS$text"
            else -> "+$text"
        }
    }
}

/**
 * Purpose: Read a string field, treating JSON null and missing as empty.
 * Inputs: `key`.
 * Returns: The string, or "".
 * Side effects: None.
 * Notes: `JSONObject.optString` returns "null" for JSON null; this does not.
 */
fun JSONObject.text(key: String): String = (opt(key) as? String) ?: ""

/**
 * Purpose: Read a finite numeric field.
 * Inputs: `key`.
 * Returns: The value as `Double`, or null when missing, null or not a number.
 * Side effects: None.
 * Notes: Booleans and numeric strings are not numbers.
 */
fun JSONObject.double(key: String): Double? =
    (opt(key) as? Number)?.toDouble()?.takeIf { it.isFinite() }

/**
 * Purpose: Read a numeric field as epoch milliseconds or another whole number.
 * Inputs: `key`.
 * Returns: The value as `Long`, or null.
 * Side effects: None.
 * Notes: See [double].
 */
fun JSONObject.long(key: String): Long? = double(key)?.toLong()

/**
 * Purpose: Read the objects of a JSON array.
 * Inputs: None (receiver may be null).
 * Returns: The array's object items in order; non-objects are skipped.
 * Side effects: None.
 * Notes: None.
 */
fun JSONArray?.objects(): List<JSONObject> {
    if (this == null) return emptyList()
    return (0 until length()).mapNotNull { opt(it) as? JSONObject }
}
