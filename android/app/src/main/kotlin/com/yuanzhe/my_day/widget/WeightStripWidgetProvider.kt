package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider

/** 2x1 Weight strip: the latest weight in a tonal tile and the change since the previous record. */
class WeightStripWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` (unused; the strip has one layout).
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store.
     * Notes: None.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, WeightState.KIND, appWidgetId) { content ->
            draw(context, appWidgetId, WeightState.load(content))
        }

    companion object {
        /**
         * Purpose: Build the strip RemoteViews for a state.
         * Inputs: `context`, `appWidgetId`, `state`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: Line 1 is the title with the unit, line 2 the signed change since the previous
         * record and the footer (time of the latest record, or *Not logged today* in the warning
         * color). Without records the tile shows "–" and line 2 the no-records label.
         */
        fun draw(context: Context, appWidgetId: Int, state: WeightState): RemoteViews {
            val content = state.content
            val views = RemoteViews(context.packageName, R.layout.widget_strip)
            MyDayWidget.bindTaps(context, views, WeightState.KIND, appWidgetId, null)
            MyDayWidget.scaleTexts(
                views,
                listOf(R.id.widget_strip_tile to 15f, R.id.widget_strip_line1 to 14f, R.id.widget_strip_line2 to 12f),
                content.textScale,
            )
            val title = content.label("title").ifEmpty { context.getString(R.string.widget_weight_name) }
            val footer = state.footer()
            val kg = state.latestKg
            if (kg == null) {
                views.setTextViewText(R.id.widget_strip_tile, "–")
                views.setTextViewText(R.id.widget_strip_line1, title)
                views.setTextViewText(R.id.widget_strip_line2, footer.text.ifEmpty { content.label("noData") })
                MyDayWidget.setTextColor(
                    context,
                    views,
                    R.id.widget_strip_line2,
                    if (footer.warning) R.color.widget_warning else R.color.widget_on_surface_variant,
                )
                return views
            }
            views.setTextViewText(R.id.widget_strip_tile, content.number(MyDayWidget.oneDecimal(kg)))
            views.setTextViewText(R.id.widget_strip_line1, "$title · ${content.label("unit")}")
            val change = state.changeSincePrevious
            val parts = listOfNotNull(
                change?.let { content.number(MyDayWidget.signed(it)) },
                footer.text.takeIf { it.isNotEmpty() },
            )
            views.setTextViewText(R.id.widget_strip_line2, parts.joinToString(" · "))
            val color = when {
                footer.warning -> R.color.widget_warning
                change != null && !content.mask -> WeightState.changeColor(change)
                else -> R.color.widget_on_surface_variant
            }
            MyDayWidget.setTextColor(context, views, R.id.widget_strip_line2, color)
            return views
        }
    }
}
