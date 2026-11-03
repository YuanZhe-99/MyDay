package com.yuanzhe.my_day.widget

import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate

/** One upcoming subscription bill of the `myday.finance` payload. */
data class FinanceBill(val name: String, val emoji: String, val day: String, val date: String, val amount: String) {
    /**
     * Purpose: Return the bill's display name with its emoji.
     * Inputs: None.
     * Returns: For example "📺 Netflix".
     * Side effects: None.
     * Notes: None.
     */
    fun display(): String = if (emoji.isEmpty()) name else "$emoji $name"
}

/**
 * Finance widget (2x2): this month's expense, income and balance and the next bill; from
 * 250 dp width the three totals sit in columns with the top expense category below.
 */
class FinanceWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` — the instance's size options.
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store.
     * Notes: Bills whose day has passed are dropped at each draw.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, MyDayWidget.KIND_FINANCE, appWidgetId) { content ->
            draw(context, appWidgetId, content, options)
        }

    companion object {
        /** Minimum width, in dp, of the wide layout. */
        private const val WIDE_MIN_WIDTH_DP = 250

        /** Minimum height, in dp at 100% text, that fits all three bill rows. */
        private const val TALL_MIN_HEIGHT_DP = 220

        private val BILL_IDS = intArrayOf(R.id.widget_finance_bill0, R.id.widget_finance_bill1, R.id.widget_finance_bill2)
        private val BILL_NAME_IDS = intArrayOf(
            R.id.widget_finance_bill0_name, R.id.widget_finance_bill1_name, R.id.widget_finance_bill2_name,
        )
        private val BILL_DATE_IDS = intArrayOf(
            R.id.widget_finance_bill0_date, R.id.widget_finance_bill1_date, R.id.widget_finance_bill2_date,
        )
        private val BILL_AMOUNT_IDS = intArrayOf(
            R.id.widget_finance_bill0_amount, R.id.widget_finance_bill1_amount, R.id.widget_finance_bill2_amount,
        )

        /** Text views and their layout sizes in sp at 100%. */
        private val SCALED_TEXT = listOf(
            R.id.widget_header_title to 12f,
            R.id.widget_header_add to 11f,
            R.id.widget_finance_expense_label to 11f,
            R.id.widget_finance_expense to 22f,
            R.id.widget_finance_income_label to 12f,
            R.id.widget_finance_income to 12f,
            R.id.widget_finance_net_label to 12f,
            R.id.widget_finance_net to 12f,
            R.id.widget_finance_wide_expense_label to 11f,
            R.id.widget_finance_wide_expense to 16f,
            R.id.widget_finance_wide_income_label to 11f,
            R.id.widget_finance_wide_income to 16f,
            R.id.widget_finance_wide_net_label to 11f,
            R.id.widget_finance_wide_net to 16f,
            R.id.widget_finance_top to 12f,
            R.id.widget_finance_bills_title to 11f,
        ) + BILL_NAME_IDS.map { it to 12f } + BILL_DATE_IDS.map { it to 11f } + BILL_AMOUNT_IDS.map { it to 12f }

        /**
         * Purpose: Build the finance RemoteViews for readable content.
         * Inputs: `context`, `appWidgetId`, `content`, `options`.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: The balance turns the error color when negative. *Hide values* draws every
         * amount and the top category's share as dots and keeps names.
         */
        fun draw(context: Context, appWidgetId: Int, content: WidgetContent, options: Bundle?): RemoteViews {
            val p = content.payload
            val scale = content.textScale
            val views = RemoteViews(context.packageName, R.layout.widget_finance)
            MyDayWidget.scaleTexts(views, SCALED_TEXT, scale)
            MyDayWidget.bindTaps(context, views, MyDayWidget.KIND_FINANCE, appWidgetId, R.id.widget_header_add)
            views.setTextViewText(R.id.widget_header_title, p.text("monthLabel").ifEmpty {
                context.getString(R.string.widget_finance_name)
            })
            views.setTextViewText(R.id.widget_header_add, "+ ${content.label("add")}")

            val sameMonth = p.text("month") == LocalDate.now().toString().substring(0, 7)
            val expense = content.amount(p.text("expense"))
            val income = content.amount(p.text("income"))
            val net = content.amount(p.text("net"))
            val netColor = if (p.optBoolean("netNegative", false) && !content.mask) {
                R.color.widget_error
            } else {
                R.color.widget_on_surface
            }

            val (width, height) = MyDayWidget.size(options)
            val wide = width >= WIDE_MIN_WIDTH_DP
            if (wide) {
                views.setViewVisibility(R.id.widget_finance_compact, View.GONE)
                views.setViewVisibility(R.id.widget_finance_wide, View.VISIBLE)
                views.setTextViewText(R.id.widget_finance_wide_expense_label, content.label("expense"))
                views.setTextViewText(R.id.widget_finance_wide_expense, expense)
                views.setTextViewText(R.id.widget_finance_wide_income_label, content.label("income"))
                views.setTextViewText(R.id.widget_finance_wide_income, income)
                views.setTextViewText(R.id.widget_finance_wide_net_label, content.label("net"))
                views.setTextViewText(R.id.widget_finance_wide_net, net)
                MyDayWidget.setTextColor(context, views, R.id.widget_finance_wide_net, netColor)
                val top = p.optJSONObject("top")
                if (top == null || !sameMonth) {
                    views.setViewVisibility(R.id.widget_finance_top, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_finance_top, View.VISIBLE)
                    views.setTextViewText(R.id.widget_finance_top, topLine(content, top))
                }
            } else {
                views.setViewVisibility(R.id.widget_finance_wide, View.GONE)
                views.setViewVisibility(R.id.widget_finance_compact, View.VISIBLE)
                views.setTextViewText(R.id.widget_finance_expense_label, content.label("expense"))
                views.setTextViewText(R.id.widget_finance_expense, expense)
                views.setTextViewText(R.id.widget_finance_income_label, content.label("income"))
                views.setTextViewText(R.id.widget_finance_income, income)
                views.setTextViewText(R.id.widget_finance_net_label, content.label("net"))
                views.setTextViewText(R.id.widget_finance_net, net)
                MyDayWidget.setTextColor(context, views, R.id.widget_finance_net, netColor)
            }

            val todayKey = LocalDate.now().toString()
            val bills = p.optJSONArray("bills").objects()
                .map {
                    FinanceBill(it.text("name"), it.text("emoji"), it.text("day"), it.text("date"), it.text("amount"))
                }
                .filter { it.day.isEmpty() || it.day >= todayKey }
            val slots = if (height >= TALL_MIN_HEIGHT_DP * scale) BILL_IDS.size else 1
            if (bills.isEmpty()) {
                views.setTextViewText(R.id.widget_finance_bills_title, content.label("noBills"))
            } else {
                views.setTextViewText(
                    R.id.widget_finance_bills_title,
                    content.label("billsSoon", "${bills.size}"),
                )
            }
            for (i in BILL_IDS.indices) {
                val bill = bills.getOrNull(i)
                if (bill == null || i >= slots) {
                    views.setViewVisibility(BILL_IDS[i], View.GONE)
                    continue
                }
                views.setViewVisibility(BILL_IDS[i], View.VISIBLE)
                views.setTextViewText(BILL_NAME_IDS[i], bill.display())
                views.setTextViewText(BILL_DATE_IDS[i], bill.date)
                views.setTextViewText(BILL_AMOUNT_IDS[i], content.amount(bill.amount))
            }
            return views
        }

        /**
         * Purpose: Format the top expense category line.
         * Inputs: `content`; `top` — the payload's `top` object.
         * Returns: For example "Top spending · 🍜 Dining · ¥1,120 · 34%".
         * Side effects: None.
         * Notes: Amount and share are masked under *Hide values*.
         */
        private fun topLine(content: WidgetContent, top: JSONObject): String {
            val emoji = top.text("emoji")
            val name = if (emoji.isEmpty()) top.text("name") else "$emoji ${top.text("name")}"
            val share = top.long("share")?.let { content.number("$it") + "%" } ?: ""
            val amount = content.amount(top.text("amount"))
            return listOf(content.label("top"), name, amount, share)
                .filter { it.isNotEmpty() }
                .joinToString(" · ")
        }
    }
}
