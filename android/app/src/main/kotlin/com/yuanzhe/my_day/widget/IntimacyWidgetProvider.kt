package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import com.yuanzhe.myapps_widget.setScaledTextSize
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * Private widget (2x2) for the Intimacy module: days since the last record, this month's count
 * and average duration, and the days until the next predicted period. The title is the neutral
 * *Private* label.
 */
class IntimacyWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` (unused; one layout).
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store.
     * Notes: The envelope is cleared while the module is hidden, which shows the placeholder.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, MyDayWidget.KIND_INTIMACY, appWidgetId) { content ->
            draw(context, appWidgetId, content)
        }

    companion object {
        /** Fixed text views and their layout sizes in sp at 100%; the day count is sized per state. */
        private val SCALED_TEXT = listOf(
            R.id.widget_header_title to 12f,
            R.id.widget_header_add to 11f,
            R.id.widget_intimacy_days_label to 12f,
            R.id.widget_intimacy_month to 12f,
            R.id.widget_intimacy_cycle to 12f,
        )

        /**
         * Purpose: Build the Private RemoteViews for readable content.
         * Inputs: `context`, `appWidgetId`, `content`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: Days count local calendar days (0 shows the today label). The month count is 0
         * and the average hidden when the payload's `month` is not the current month. A cycle
         * prediction in the past is hidden. *Hide values* masks every number.
         */
        fun draw(context: Context, appWidgetId: Int, content: WidgetContent): RemoteViews {
            val p = content.payload
            val scale = content.textScale
            val zone = ZoneId.systemDefault()
            val today = LocalDate.now(zone)
            val views = RemoteViews(context.packageName, R.layout.widget_intimacy)
            MyDayWidget.scaleTexts(views, SCALED_TEXT, scale)
            MyDayWidget.bindTaps(context, views, MyDayWidget.KIND_INTIMACY, appWidgetId, R.id.widget_header_add)
            views.setTextViewText(R.id.widget_header_title, content.label("title").ifEmpty {
                context.getString(R.string.widget_intimacy_name)
            })
            views.setTextViewText(R.id.widget_header_add, "+ ${content.label("add")}")

            val lastAt = p.long("lastAt")
            if (lastAt == null) {
                views.setScaledTextSize(R.id.widget_intimacy_days, 16f, scale)
                views.setTextViewText(R.id.widget_intimacy_days, content.label("noData"))
                views.setViewVisibility(R.id.widget_intimacy_days_label, View.GONE)
            } else {
                val lastDay = Instant.ofEpochMilli(lastAt).atZone(zone).toLocalDate()
                val days = ChronoUnit.DAYS.between(lastDay, today).coerceAtLeast(0L)
                if (days == 0L && !content.mask) {
                    views.setScaledTextSize(R.id.widget_intimacy_days, 22f, scale)
                    views.setTextViewText(R.id.widget_intimacy_days, content.label("today"))
                    views.setViewVisibility(R.id.widget_intimacy_days_label, View.GONE)
                } else {
                    views.setScaledTextSize(R.id.widget_intimacy_days, 32f, scale)
                    views.setTextViewText(R.id.widget_intimacy_days, content.number("$days"))
                    views.setViewVisibility(R.id.widget_intimacy_days_label, View.VISIBLE)
                    views.setTextViewText(R.id.widget_intimacy_days_label, content.label("daysAgo"))
                }
            }

            val sameMonth = p.text("month") == YearMonth.now(zone).toString()
            val count = if (sameMonth) p.long("monthCount") ?: 0L else 0L
            val avg = if (sameMonth) p.long("avgMinutes") else null
            val month = content.label("month", content.number("$count"))
            views.setTextViewText(
                R.id.widget_intimacy_month,
                if (avg == null) month else "$month · ${content.label("avg", content.number("$avg"))}",
            )

            val next = p.text("cycleNext").takeIf { it.isNotEmpty() }?.let {
                try {
                    LocalDate.parse(it)
                } catch (e: Exception) {
                    null
                }
            }
            val until = next?.let { ChronoUnit.DAYS.between(today, it) }
            when {
                until == null || until < 0 -> views.setViewVisibility(R.id.widget_intimacy_cycle, View.GONE)
                until == 0L && !content.mask -> {
                    views.setViewVisibility(R.id.widget_intimacy_cycle, View.VISIBLE)
                    views.setTextViewText(R.id.widget_intimacy_cycle, content.label("cycleToday"))
                }
                else -> {
                    views.setViewVisibility(R.id.widget_intimacy_cycle, View.VISIBLE)
                    views.setTextViewText(R.id.widget_intimacy_cycle, content.label("cycleIn", content.number("$until")))
                }
            }
            return views
        }
    }
}
