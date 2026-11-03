package com.yuanzhe.my_day.widget

import android.content.Context
import android.graphics.Paint
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.yuanzhe.my_day.R
import com.yuanzhe.myapps_widget.EnvelopeWidgetProvider
import com.yuanzhe.myapps_widget.WidgetActions
import com.yuanzhe.myapps_widget.WidgetLaunch
import com.yuanzhe.myapps_widget.setScaledTextSize
import org.json.JSONObject

/**
 * Todo widget (2x2, resizable to 4x4): the open count with a progress bar and today's rows with
 * checkboxes; from 250 dp width a side column with tomorrow's scheduled tasks and the day score;
 * from 250 dp height up to ten rows.
 */
class TodoWidgetProvider : EnvelopeWidgetProvider() {

    /**
     * Purpose: Draw one instance from the stored envelope.
     * Inputs: `context`, `appWidgetId`, `options` — the instance's size options.
     * Returns: `RemoteViews`.
     * Side effects: Reads the envelope store and the pending-action queue.
     * Notes: Called by the shared base on add, update period, resize, publish and after a
     * checkbox tap; today is re-evaluated each time, so the list flips at midnight.
     */
    override fun render(context: Context, appWidgetId: Int, options: Bundle?): RemoteViews =
        MyDayWidget.render(context, TodoState.KIND, appWidgetId) { content ->
            val state = TodoState.load(context, content)
            if (state.today == null) {
                MyDayWidget.placeholder(context, TodoState.KIND, appWidgetId, content.label("stale"), content.textScale)
            } else {
                draw(context, appWidgetId, state, options)
            }
        }

    companion object {
        /** Minimum width, in dp, of the wide layout with the side column. */
        private const val WIDE_MIN_WIDTH_DP = 250

        /** Minimum height, in dp at 100% text, of the tall layout with up to ten rows. */
        private const val TALL_MIN_HEIGHT_DP = 250

        /** Height, in dp at 100% text, of the header, count line and progress bar. */
        private const val CHROME_DP = 64

        /** Vertical padding of the widget, in dp. */
        private const val PADDING_DP = 28

        /** Height of one row, in dp at 100% text. */
        private const val ROW_DP = 24

        /** Rows in the compact and tall layouts. */
        private const val COMPACT_ROWS = 3
        private const val TALL_ROWS = 10

        /** Tomorrow slots in the side column for the compact and tall heights. */
        private const val COMPACT_NEXT = 3
        private const val TALL_NEXT = 6

        private val ROW_IDS = intArrayOf(
            R.id.widget_todo_row0, R.id.widget_todo_row1, R.id.widget_todo_row2, R.id.widget_todo_row3,
            R.id.widget_todo_row4, R.id.widget_todo_row5, R.id.widget_todo_row6, R.id.widget_todo_row7,
            R.id.widget_todo_row8, R.id.widget_todo_row9,
        )
        private val CHECK_IDS = intArrayOf(
            R.id.widget_todo_check0, R.id.widget_todo_check1, R.id.widget_todo_check2, R.id.widget_todo_check3,
            R.id.widget_todo_check4, R.id.widget_todo_check5, R.id.widget_todo_check6, R.id.widget_todo_check7,
            R.id.widget_todo_check8, R.id.widget_todo_check9,
        )
        private val TITLE_IDS = intArrayOf(
            R.id.widget_todo_title0, R.id.widget_todo_title1, R.id.widget_todo_title2, R.id.widget_todo_title3,
            R.id.widget_todo_title4, R.id.widget_todo_title5, R.id.widget_todo_title6, R.id.widget_todo_title7,
            R.id.widget_todo_title8, R.id.widget_todo_title9,
        )
        private val META_IDS = intArrayOf(
            R.id.widget_todo_meta0, R.id.widget_todo_meta1, R.id.widget_todo_meta2, R.id.widget_todo_meta3,
            R.id.widget_todo_meta4, R.id.widget_todo_meta5, R.id.widget_todo_meta6, R.id.widget_todo_meta7,
            R.id.widget_todo_meta8, R.id.widget_todo_meta9,
        )
        private val NEXT_IDS = intArrayOf(
            R.id.widget_todo_next0, R.id.widget_todo_next1, R.id.widget_todo_next2,
            R.id.widget_todo_next3, R.id.widget_todo_next4, R.id.widget_todo_next5,
        )

        /** Fixed text views and their layout sizes in sp at 100%. */
        private val SCALED_TEXT = listOf(
            R.id.widget_header_title to 12f,
            R.id.widget_header_add to 11f,
            R.id.widget_todo_count to 22f,
            R.id.widget_todo_progress_text to 11f,
            R.id.widget_todo_empty to 12f,
            R.id.widget_todo_tomorrow to 11f,
            R.id.widget_todo_score to 12f,
        )

        /**
         * Purpose: Build the Todo RemoteViews for a state with a today entry.
         * Inputs: `context`; `appWidgetId`; `state`; `options` — the instance's size options.
         * Returns: `RemoteViews`.
         * Side effects: None.
         * Notes: The row count fits the instance height and grows the thresholds with the text
         * scale. Every slot's visibility, text, color and paint flags are set on every draw,
         * because the launcher may reapply onto the previous views.
         */
        fun draw(context: Context, appWidgetId: Int, state: TodoState, options: Bundle?): RemoteViews {
            val content = state.content
            val today = state.today!!
            val scale = content.textScale
            val views = RemoteViews(context.packageName, R.layout.widget_todo)
            MyDayWidget.scaleTexts(views, SCALED_TEXT, scale)
            MyDayWidget.bindTaps(context, views, TodoState.KIND, appWidgetId, R.id.widget_header_add)
            views.setTextViewText(R.id.widget_header_title, today.label)
            views.setTextViewText(R.id.widget_header_add, "+ ${content.label("new")}")

            val open = today.open.size
            val done = today.done.size
            val total = open + done
            when {
                total == 0 -> views.setTextViewText(R.id.widget_todo_count, content.label("nothing"))
                open == 0 -> views.setTextViewText(R.id.widget_todo_count, content.label("allDone"))
                else -> views.setTextViewText(R.id.widget_todo_count, content.label("left", content.number("$open")))
            }
            if (total == 0) {
                views.setViewVisibility(R.id.widget_todo_progress_text, View.GONE)
                views.setProgressBar(R.id.widget_todo_progress, 1, 0, false)
            } else {
                views.setViewVisibility(R.id.widget_todo_progress_text, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_todo_progress_text,
                    content.label("progress", content.number("$done"), content.number("$total")),
                )
                if (content.mask) {
                    views.setProgressBar(R.id.widget_todo_progress, 1, 0, false)
                } else {
                    views.setProgressBar(R.id.widget_todo_progress, total, done, false)
                }
            }

            val (width, height) = MyDayWidget.size(options)
            val wide = width >= WIDE_MIN_WIDTH_DP
            val tall = height >= TALL_MIN_HEIGHT_DP * scale
            val maxRows = if (tall) TALL_ROWS else COMPACT_ROWS
            val rowCount = if (height == 0) {
                maxRows
            } else {
                ((height - PADDING_DP - CHROME_DP * scale) / (ROW_DP * scale)).toInt().coerceIn(1, maxRows)
            }
            val rows = today.ordered.take(rowCount)
            for (i in ROW_IDS.indices) {
                bindRow(context, views, appWidgetId, i, today.date, rows.getOrNull(i), content)
            }
            if (rows.isEmpty()) {
                views.setViewVisibility(R.id.widget_todo_empty, View.VISIBLE)
                views.setTextViewText(R.id.widget_todo_empty, content.label("nothing"))
            } else {
                views.setViewVisibility(R.id.widget_todo_empty, View.GONE)
            }

            if (wide) {
                views.setViewVisibility(R.id.widget_todo_side, View.VISIBLE)
                bindSide(context, views, state, if (tall) TALL_NEXT else COMPACT_NEXT)
            } else {
                views.setViewVisibility(R.id.widget_todo_side, View.GONE)
            }
            return views
        }

        /**
         * Purpose: Fill or hide one task row.
         * Inputs: `context`; `views`; `appWidgetId`; `index` — the slot; `date` — the day shown;
         * `item` — the row or null to hide the slot; `content`.
         * Returns: None.
         * Side effects: Mutates `views`.
         * Notes: A recurring one-time task's checkbox opens the app (`do=toggle`) so the
         * "create next occurrence" prompt still appears; every other checkbox queues `setDone`
         * with the opposite state. Completed rows are struck through and dimmed; overdue rows
         * show the overdue label in the error color instead of the time.
         */
        private fun bindRow(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            index: Int,
            date: String,
            item: TodoItem?,
            content: WidgetContent,
        ) {
            if (item == null) {
                views.setViewVisibility(ROW_IDS[index], View.GONE)
                return
            }
            val scale = content.textScale
            views.setViewVisibility(ROW_IDS[index], View.VISIBLE)
            views.setScaledTextSize(TITLE_IDS[index], 13f, scale)
            views.setScaledTextSize(META_IDS[index], 11f, scale)
            views.setTextViewText(TITLE_IDS[index], item.display())
            views.setImageViewResource(
                CHECK_IDS[index],
                if (item.done) R.drawable.widget_ic_check_on else R.drawable.widget_ic_check_off,
            )
            views.setContentDescription(CHECK_IDS[index], item.title)
            views.setInt(
                TITLE_IDS[index],
                "setPaintFlags",
                if (item.done) Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG else Paint.ANTI_ALIAS_FLAG,
            )
            MyDayWidget.setTextColor(
                context,
                views,
                TITLE_IDS[index],
                if (item.done) R.color.widget_on_surface_variant else R.color.widget_on_surface,
            )
            when {
                item.late && !item.done -> {
                    views.setViewVisibility(META_IDS[index], View.VISIBLE)
                    views.setTextViewText(META_IDS[index], content.label("overdue"))
                    MyDayWidget.setTextColor(context, views, META_IDS[index], R.color.widget_error)
                }
                item.time.isNotEmpty() -> {
                    views.setViewVisibility(META_IDS[index], View.VISIBLE)
                    views.setTextViewText(META_IDS[index], item.time)
                    MyDayWidget.setTextColor(
                        context,
                        views,
                        META_IDS[index],
                        if (item.done) R.color.widget_on_surface_variant else R.color.widget_primary,
                    )
                }
                else -> views.setViewVisibility(META_IDS[index], View.GONE)
            }
            val code = MyDayWidget.requestCode(appWidgetId, MyDayWidget.SLOT_ROWS + index)
            val tap = if (item.recurring) {
                WidgetLaunch.pendingIntent(
                    context,
                    MyDayWidget.link(TodoState.KIND, "toggle", mapOf("id" to item.id)),
                    code,
                )
            } else {
                WidgetActions.pendingIntent(
                    context,
                    TodoState.KIND,
                    "setDone",
                    JSONObject().put("id", item.id).put("date", date).put("done", !item.done),
                    MyDayWidget.TODO_PROVIDERS,
                    code,
                )
            }
            views.setOnClickPendingIntent(CHECK_IDS[index], tap)
        }

        /**
         * Purpose: Fill the wide layout's side column.
         * Inputs: `context`; `views`; `state`; `slots` — tomorrow rows that fit.
         * Returns: None.
         * Side effects: Mutates `views`.
         * Notes: Tomorrow lists the open one-time tasks scheduled exactly on that day (`sched`),
         * with their reminder time; the score line shows today's day score when one exists.
         */
        private fun bindSide(context: Context, views: RemoteViews, state: TodoState, slots: Int) {
            val content = state.content
            val scale = content.textScale
            views.setTextViewText(R.id.widget_todo_tomorrow, content.label("tomorrow"))
            val next = state.tomorrow?.items?.filter { it.scheduled && !it.done } ?: emptyList()
            for (i in NEXT_IDS.indices) {
                val id = NEXT_IDS[i]
                views.setScaledTextSize(id, 12f, scale)
                val item = next.getOrNull(i)
                when {
                    i < slots && item != null -> {
                        views.setViewVisibility(id, View.VISIBLE)
                        val text = if (item.time.isEmpty()) item.display() else "${item.time}  ${item.display()}"
                        views.setTextViewText(id, text)
                        MyDayWidget.setTextColor(context, views, id, R.color.widget_on_surface)
                    }
                    i == 0 && next.isEmpty() -> {
                        views.setViewVisibility(id, View.VISIBLE)
                        views.setTextViewText(id, content.label("nothing"))
                        MyDayWidget.setTextColor(context, views, id, R.color.widget_on_surface_variant)
                    }
                    else -> views.setViewVisibility(id, View.GONE)
                }
            }
            val score = state.today?.score
            if (score == null) {
                views.setViewVisibility(R.id.widget_todo_score, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_todo_score, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_todo_score,
                    "${content.label("score")} ${content.number(MyDayWidget.decimal(score))}",
                )
            }
        }
    }
}
