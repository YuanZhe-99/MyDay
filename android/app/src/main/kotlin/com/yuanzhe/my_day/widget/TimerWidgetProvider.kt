package com.yuanzhe.my_day.widget

import android.app.PendingIntent
import android.content.Context
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import com.yuanzhe.myapps_widget.WidgetActions
import com.yuanzhe.myapps_widget.WidgetLaunch
import com.yuanzhe.myapps_widget.setScaledTextSize
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Timer widget (2x2): the Intimacy stopwatch. Running time counts up natively in a
 * `Chronometer`; Start / Pause / Resume and +100 queue actions without opening the app, Finish
 * opens the timer page to save a record.
 */
class TimerWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` (unused; one layout).
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store and the pending-action queue.
     * Notes: Redrawn right after each button tap, so the replayed action shows at once.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, TimerState.KIND, appWidgetId) { content ->
            draw(context, appWidgetId, TimerState.load(context, content))
        }

    companion object {
        /** Fixed text views and their layout sizes in sp at 100%; the clock is sized per state. */
        private val SCALED_TEXT = listOf(
            R.id.widget_header_title to 12f,
            R.id.widget_header_add to 11f,
            R.id.widget_timer_detail to 12f,
            R.id.widget_timer_primary to 12f,
            R.id.widget_timer_add to 12f,
            R.id.widget_timer_finish to 12f,
        )

        /**
         * Purpose: Build the 2x2 timer RemoteViews for a state.
         * Inputs: `context`, `appWidgetId`, `state`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: Idle shows only Start and the last-session line; a session adds +N and Finish
         * and a Running / Paused pill in the header.
         */
        fun draw(context: Context, appWidgetId: Int, state: TimerState): RemoteViews {
            val content = state.content
            val session = state.session
            val views = RemoteViews(context.packageName, R.layout.widget_timer)
            MyDayWidget.scaleTexts(views, SCALED_TEXT, content.textScale)
            MyDayWidget.bindTaps(context, views, TimerState.KIND, appWidgetId, null)
            views.setTextViewText(R.id.widget_header_title, content.label("title").ifEmpty {
                context.getString(R.string.widget_timer_name)
            })
            if (session == null) {
                views.setViewVisibility(R.id.widget_header_add, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_header_add, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_header_add,
                    content.label(if (session.running) "running" else "paused"),
                )
            }
            bindClock(views, state, 30f)
            views.setTextViewText(R.id.widget_timer_detail, detail(state, withStatus = false))

            views.setTextViewText(
                R.id.widget_timer_primary,
                content.label(
                    when {
                        session == null -> "start"
                        session.running -> "pause"
                        else -> "resume"
                    },
                ),
            )
            views.setOnClickPendingIntent(R.id.widget_timer_primary, toggleIntent(context, appWidgetId, session))
            if (session == null) {
                views.setViewVisibility(R.id.widget_timer_add, View.GONE)
                views.setViewVisibility(R.id.widget_timer_finish, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_timer_add, View.VISIBLE)
                views.setViewVisibility(R.id.widget_timer_finish, View.VISIBLE)
                views.setTextViewText(R.id.widget_timer_add, "+${state.step}")
                views.setOnClickPendingIntent(R.id.widget_timer_add, stepIntent(context, appWidgetId, state.step))
                views.setTextViewText(R.id.widget_timer_finish, content.label("finish"))
                views.setOnClickPendingIntent(
                    R.id.widget_timer_finish,
                    WidgetLaunch.pendingIntent(
                        context,
                        MyDayWidget.link(TimerState.KIND, "timer"),
                        MyDayWidget.requestCode(appWidgetId, MyDayWidget.SLOT_FINISH),
                    ),
                )
            }
            return views
        }

        /**
         * Purpose: Show the elapsed time: a ticking or frozen `Chronometer`, or a text instead.
         * Inputs: `views`; `state`; `baseSp` — the clock size at 100%.
         * Returns: None.
         * Side effects: Mutates `views`.
         * Notes: Idle shows the idle label at a smaller size; *Hide values* shows `••:••` and
         * stops the chronometer. A paused chronometer is set with `started = false`, which
         * freezes it at `base`.
         */
        fun bindClock(views: RemoteViews, state: TimerState, baseSp: Float) {
            val content = state.content
            val session = state.session
            val scale = content.textScale
            if (session == null || content.mask) {
                views.setChronometer(R.id.widget_timer_clock, SystemClock.elapsedRealtime(), null, false)
                views.setViewVisibility(R.id.widget_timer_clock, View.GONE)
                views.setViewVisibility(R.id.widget_timer_clock_text, View.VISIBLE)
                if (session == null) {
                    views.setScaledTextSize(R.id.widget_timer_clock_text, maxOf(baseSp * 0.6f, 14f), scale)
                    views.setTextViewText(R.id.widget_timer_clock_text, content.label("idle"))
                } else {
                    views.setScaledTextSize(R.id.widget_timer_clock_text, baseSp, scale)
                    views.setTextViewText(
                        R.id.widget_timer_clock_text,
                        "${MyDayWidget.MASK_NUMBER}:${MyDayWidget.MASK_NUMBER}",
                    )
                }
                return
            }
            val elapsed = session.elapsedMs(System.currentTimeMillis())
            views.setViewVisibility(R.id.widget_timer_clock_text, View.GONE)
            views.setViewVisibility(R.id.widget_timer_clock, View.VISIBLE)
            views.setScaledTextSize(R.id.widget_timer_clock, baseSp, scale)
            views.setChronometer(
                R.id.widget_timer_clock,
                SystemClock.elapsedRealtime() - elapsed,
                null,
                session.running,
            )
        }

        /**
         * Purpose: Return the line under the clock.
         * Inputs: `state`; `withStatus` — prefix Running / Paused (the strip has no header pill).
         * Returns: The count for a session, otherwise the last-session line or empty.
         * Side effects: None.
         * Notes: The last line uses `lastToday` for a session today, else `last` with a short
         * localized date for `{n}`; minutes fill `{m}`.
         */
        fun detail(state: TimerState, withStatus: Boolean): String {
            val content = state.content
            val session = state.session
            if (session != null) {
                val count = content.label("count", content.number("${session.count}"))
                if (!withStatus) return count
                return "${content.label(if (session.running) "running" else "paused")} · $count"
            }
            val last = state.last ?: return ""
            val zone = ZoneId.systemDefault()
            val minutes = content.number("${Math.round(last.durationMs / 60000.0)}")
            val day = Instant.ofEpochMilli(last.at).atZone(zone).toLocalDate()
            if (day == LocalDate.now(zone)) return content.label("lastToday", minutes, minutes)
            val locale = Locale.getDefault()
            val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, "MMMd")
            val date = day.format(DateTimeFormatter.ofPattern(pattern, locale))
            return content.label("last", date, minutes)
        }

        /**
         * Purpose: Build the Start / Pause / Resume tap.
         * Inputs: `context`, `appWidgetId`, `session` — the replayed session or null.
         * Returns: A broadcast PendingIntent queueing `pause` while running, else `start`.
         * Side effects: None.
         * Notes: The action name is part of the intent data, so the two never collapse.
         */
        fun toggleIntent(context: Context, appWidgetId: Int, session: TimerSession?): PendingIntent =
            WidgetActions.pendingIntent(
                context,
                TimerState.KIND,
                if (session?.running == true) "pause" else "start",
                JSONObject(),
                MyDayWidget.TIMER_PROVIDERS,
                MyDayWidget.requestCode(appWidgetId, MyDayWidget.SLOT_PRIMARY),
            )

        /**
         * Purpose: Build the +N tap.
         * Inputs: `context`, `appWidgetId`, `step`.
         * Returns: A broadcast PendingIntent queueing `add` with `{"n": step}`.
         * Side effects: None.
         * Notes: None.
         */
        fun stepIntent(context: Context, appWidgetId: Int, step: Int): PendingIntent =
            WidgetActions.pendingIntent(
                context,
                TimerState.KIND,
                "add",
                JSONObject().put("n", step),
                MyDayWidget.TIMER_PROVIDERS,
                MyDayWidget.requestCode(appWidgetId, MyDayWidget.SLOT_STEP),
            )
    }
}
