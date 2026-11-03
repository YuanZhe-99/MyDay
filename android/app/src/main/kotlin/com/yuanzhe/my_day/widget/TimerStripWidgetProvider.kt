package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider

/** 2x1 timer strip: a start / pause tile, the elapsed time with the count, and the +N button. */
class TimerStripWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` (unused; one layout).
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store and the pending-action queue.
     * Notes: Shares the clock, detail and tap helpers of [TimerWidgetProvider].
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, TimerState.KIND, appWidgetId) { content ->
            draw(context, appWidgetId, TimerState.load(context, content))
        }

    companion object {
        /**
         * Purpose: Build the strip RemoteViews for a state.
         * Inputs: `context`, `appWidgetId`, `state`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: The tile starts, pauses or resumes; +N is shown only during a session. Tapping
         * the rest opens the Intimacy tab; Finish lives on the 2x2 widget and the timer page.
         */
        fun draw(context: Context, appWidgetId: Int, state: TimerState): RemoteViews {
            val content = state.content
            val session = state.session
            val views = RemoteViews(context.packageName, R.layout.widget_timer_strip)
            MyDayWidget.scaleTexts(
                views,
                listOf(R.id.widget_timer_detail to 12f, R.id.widget_timer_add to 12f),
                content.textScale,
            )
            MyDayWidget.bindTaps(context, views, TimerState.KIND, appWidgetId, null)
            TimerWidgetProvider.bindClock(views, state, 18f)
            views.setTextViewText(R.id.widget_timer_detail, TimerWidgetProvider.detail(state, withStatus = true))

            val running = session?.running == true
            views.setImageViewResource(
                R.id.widget_timer_toggle,
                if (running) R.drawable.widget_ic_pause else R.drawable.widget_ic_play,
            )
            views.setContentDescription(
                R.id.widget_timer_toggle,
                content.label(
                    when {
                        session == null -> "start"
                        running -> "pause"
                        else -> "resume"
                    },
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_timer_toggle,
                TimerWidgetProvider.toggleIntent(context, appWidgetId, session),
            )
            if (session == null) {
                views.setViewVisibility(R.id.widget_timer_add, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_timer_add, View.VISIBLE)
                views.setTextViewText(R.id.widget_timer_add, "+${state.step}")
                views.setOnClickPendingIntent(
                    R.id.widget_timer_add,
                    TimerWidgetProvider.stepIntent(context, appWidgetId, state.step),
                )
            }
            return views
        }
    }
}
