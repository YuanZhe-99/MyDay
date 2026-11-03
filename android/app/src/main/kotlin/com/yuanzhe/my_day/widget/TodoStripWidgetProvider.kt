package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import java.time.LocalTime
import java.time.format.DateTimeFormatter

/** 2x1 Todo strip: a tonal open-count tile and the next open task with a reminder time. */
class TodoStripWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` (unused; the strip has one layout).
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store and the pending-action queue.
     * Notes: Checkbox taps on the 2x2 widget redraw the strip too, so its count stays in step.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, TodoState.KIND, appWidgetId) { content ->
            val state = TodoState.load(context, content)
            if (state.today == null) {
                MyDayWidget.placeholder(context, TodoState.KIND, appWidgetId, content.label("stale"), content.textScale)
            } else {
                draw(context, appWidgetId, state)
            }
        }

    companion object {
        /**
         * Purpose: Build the strip RemoteViews for a state with a today entry.
         * Inputs: `context`, `appWidgetId`, `state`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: The tile shows the open count ("✓" when everything is done); line 1 is the next
         * task, line 2 its time (or the overdue label) and the remaining count.
         */
        fun draw(context: Context, appWidgetId: Int, state: TodoState): RemoteViews {
            val content = state.content
            val today = state.today!!
            val scale = content.textScale
            val views = RemoteViews(context.packageName, R.layout.widget_strip)
            MyDayWidget.bindTaps(context, views, TodoState.KIND, appWidgetId, null)
            MyDayWidget.scaleTexts(
                views,
                listOf(R.id.widget_strip_tile to 18f, R.id.widget_strip_line1 to 14f, R.id.widget_strip_line2 to 12f),
                scale,
            )
            val open = today.open.size
            val total = today.items.size
            views.setTextViewText(R.id.widget_strip_tile, if (open == 0 && total > 0) "✓" else content.number("$open"))
            val now = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"))
            val next = state.nextTask(now)
            if (next == null) {
                views.setTextViewText(
                    R.id.widget_strip_line1,
                    content.label(if (total == 0) "nothing" else "allDone"),
                )
                views.setTextViewText(
                    R.id.widget_strip_line2,
                    if (total == 0) today.label else content.label("progress", content.number("${total - open}"), content.number("$total")),
                )
                MyDayWidget.setTextColor(context, views, R.id.widget_strip_line2, R.color.widget_on_surface_variant)
                return views
            }
            views.setTextViewText(R.id.widget_strip_line1, next.display())
            val left = content.label("left", content.number("$open"))
            when {
                next.late -> {
                    views.setTextViewText(R.id.widget_strip_line2, "${content.label("overdue")} · $left")
                    MyDayWidget.setTextColor(context, views, R.id.widget_strip_line2, R.color.widget_error)
                }
                next.time.isNotEmpty() -> {
                    views.setTextViewText(R.id.widget_strip_line2, "${next.time} · $left")
                    MyDayWidget.setTextColor(context, views, R.id.widget_strip_line2, R.color.widget_on_surface_variant)
                }
                else -> {
                    views.setTextViewText(R.id.widget_strip_line2, left)
                    MyDayWidget.setTextColor(context, views, R.id.widget_strip_line2, R.color.widget_on_surface_variant)
                }
            }
            return views
        }
    }
}
