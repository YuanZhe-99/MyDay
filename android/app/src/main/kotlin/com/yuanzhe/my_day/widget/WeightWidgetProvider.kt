package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import com.yuanzhe.myapps_widget.setScaledTextSize

/**
 * Weight widget (2x2): the latest weight, the 30-day change, BMI, a sparkline of the last 30
 * days and the time of the latest record (or *Not logged today*).
 */
class WeightWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` — the instance's size options.
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store; allocates the sparkline bitmap.
     * Notes: The footer is re-evaluated at each draw, so *Not logged today* appears on the
     * update period after the reminder time.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, WeightState.KIND, appWidgetId) { content ->
            draw(context, appWidgetId, WeightState.load(content), options)
        }

    companion object {
        /** Width, in dp, assumed when the launcher reports no size. */
        private const val DEFAULT_WIDTH_DP = 150

        /** Height, in dp at 100% text, of everything except the sparkline, padding included. */
        private const val CHROME_DP = 110

        /** Fixed text views and their layout sizes in sp at 100%. */
        private val SCALED_TEXT = listOf(
            R.id.widget_header_title to 12f,
            R.id.widget_header_add to 11f,
            R.id.widget_weight_unit to 13f,
            R.id.widget_weight_change to 12f,
            R.id.widget_weight_bmi to 12f,
            R.id.widget_weight_footer to 11f,
        )

        /**
         * Purpose: Build the 2x2 weight RemoteViews for a state.
         * Inputs: `context`, `appWidgetId`, `state`, `options`.
         * Returns: `RemoteViews`.
         * Side effects: Allocates the sparkline bitmap.
         * Notes: Without records the value line shows the no-records label. *Hide values* masks
         * the weight, change and BMI and drops the sparkline.
         */
        fun draw(context: Context, appWidgetId: Int, state: WeightState, options: Bundle?): RemoteViews {
            val content = state.content
            val scale = content.textScale
            val views = RemoteViews(context.packageName, R.layout.widget_weight)
            MyDayWidget.scaleTexts(views, SCALED_TEXT, scale)
            MyDayWidget.bindTaps(context, views, WeightState.KIND, appWidgetId, R.id.widget_header_add)
            views.setTextViewText(R.id.widget_header_title, content.label("title").ifEmpty {
                context.getString(R.string.widget_weight_name)
            })
            views.setTextViewText(R.id.widget_header_add, "+ ${content.label("log")}")

            val kg = state.latestKg
            if (kg == null) {
                views.setScaledTextSize(R.id.widget_weight_value, 16f, scale)
                views.setTextViewText(R.id.widget_weight_value, content.label("noData"))
                views.setViewVisibility(R.id.widget_weight_unit, View.GONE)
                views.setViewVisibility(R.id.widget_weight_change, View.GONE)
                views.setViewVisibility(R.id.widget_weight_bmi, View.GONE)
            } else {
                views.setScaledTextSize(R.id.widget_weight_value, 28f, scale)
                views.setTextViewText(R.id.widget_weight_value, content.number(MyDayWidget.oneDecimal(kg)))
                views.setViewVisibility(R.id.widget_weight_unit, View.VISIBLE)
                views.setTextViewText(R.id.widget_weight_unit, content.label("unit"))
                val change = state.change30
                if (change == null) {
                    views.setViewVisibility(R.id.widget_weight_change, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_weight_change, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_weight_change,
                        "${content.number(MyDayWidget.signed(change))} · ${content.label("change30")}",
                    )
                    MyDayWidget.setTextColor(
                        context,
                        views,
                        R.id.widget_weight_change,
                        if (content.mask) R.color.widget_on_surface_variant else WeightState.changeColor(change),
                    )
                }
                val bmi = state.bmi
                if (bmi == null) {
                    views.setViewVisibility(R.id.widget_weight_bmi, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_weight_bmi, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_weight_bmi,
                        "${content.label("bmi")} ${content.number(MyDayWidget.oneDecimal(bmi))}",
                    )
                }
            }

            val (width, height) = MyDayWidget.size(options)
            val spark = if (content.mask) {
                null
            } else {
                val sparkWidth = (if (width > 0) width else DEFAULT_WIDTH_DP) - 28
                val sparkHeight = if (height > 0) (height - CHROME_DP * scale).toInt() else 40
                WeightState.sparkline(context, state.points, sparkWidth, sparkHeight.coerceIn(16, 120))
            }
            if (spark == null) {
                views.setViewVisibility(R.id.widget_weight_spark, View.INVISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_weight_spark, View.VISIBLE)
                views.setImageViewBitmap(R.id.widget_weight_spark, spark)
            }

            val footer = state.footer()
            views.setTextViewText(R.id.widget_weight_footer, footer.text)
            MyDayWidget.setTextColor(
                context,
                views,
                R.id.widget_weight_footer,
                if (footer.warning) R.color.widget_warning else R.color.widget_on_surface_variant,
            )
            return views
        }
    }
}
