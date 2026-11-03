package com.yuanzhe.my_day.widget

import android.content.Context
import com.yuanzhe.myapps_widget.WidgetActionQueue
import org.json.JSONObject
import java.time.LocalDate

/** One Todo row of the `myday.todo` payload. */
data class TodoItem(
    val id: String,
    val title: String,
    val emoji: String,
    /** `daily`, `routineOnce` or `workOnce`. */
    val type: String,
    val done: Boolean,
    /** Reminder time `HH:mm`, or empty. */
    val time: String,
    val late: Boolean,
    /** A one-time task with a recurrence: its checkbox opens the app instead of queueing. */
    val recurring: Boolean,
    /** Scheduled exactly on this day; used for the "tomorrow" preview. */
    val scheduled: Boolean,
) {
    /**
     * Purpose: Return the row text: the emoji, if any, and the title.
     * Inputs: None.
     * Returns: For example "🧾 Pay the bills".
     * Side effects: None.
     * Notes: None.
     */
    fun display(): String = if (emoji.isEmpty()) title else "$emoji $title"
}

/** One day of the `myday.todo` payload, after the pending-action overlay. */
data class TodoDay(
    /** Local `yyyy-MM-dd`. */
    val date: String,
    /** Localized header label, e.g. "Mon, Nov 2". */
    val label: String,
    val score: Double?,
    /** Rows in payload order, with pending taps applied. */
    val items: List<TodoItem>,
) {
    /**
     * Purpose: Return the open rows.
     * Inputs: None.
     * Returns: Open items in payload order (overdue first, then by reminder time).
     * Side effects: None.
     * Notes: None.
     */
    val open: List<TodoItem> get() = items.filter { !it.done }

    /**
     * Purpose: Return the completed rows.
     * Inputs: None.
     * Returns: Done items in payload order.
     * Side effects: None.
     * Notes: None.
     */
    val done: List<TodoItem> get() = items.filter { it.done }

    /**
     * Purpose: Return the rows in display order.
     * Inputs: None.
     * Returns: Open rows, then completed rows.
     * Side effects: None.
     * Notes: Re-partitioned after the overlay, so a tapped row moves at once.
     */
    val ordered: List<TodoItem> get() = open + done
}

/**
 * The Todo widget state: today's and tomorrow's days of the `myday.todo` envelope, with the
 * queued `setDone` taps replayed over them.
 */
data class TodoState(val content: WidgetContent, val today: TodoDay?, val tomorrow: TodoDay?) {

    /**
     * Purpose: Pick the open task the strip shows: the next one with a reminder time.
     * Inputs: `nowHhmm` — the local time as `HH:mm`.
     * Returns: The first open, not overdue task timed at or after now; otherwise the first
     * open timed task; otherwise the first open task; null when nothing is open.
     * Side effects: None.
     * Notes: Payload order already sorts open tasks by time.
     */
    fun nextTask(nowHhmm: String): TodoItem? {
        val open = today?.open ?: return null
        return open.firstOrNull { !it.late && it.time.isNotEmpty() && it.time >= nowHhmm }
            ?: open.firstOrNull { it.time.isNotEmpty() }
            ?: open.firstOrNull()
    }

    companion object {
        /** Envelope kind; matches `HomeWidgetService`. */
        const val KIND = MyDayWidget.KIND_TODO

        /**
         * Purpose: Build the state from readable content at a local date.
         * Inputs: `context`; `content`; `date` — today's local date.
         * Returns: `TodoState`; `today` is null when the snapshot has no entry for the date.
         * Side effects: Reads the pending-action queue.
         * Notes: Pending `setDone` taps whose ids are not in `appliedActions` are replayed in
         * queue order, so a checkbox shows its new state before the app runs.
         */
        fun load(context: Context, content: WidgetContent, date: LocalDate = LocalDate.now()): TodoState {
            val days = content.payload.optJSONArray("days").objects().map { parseDay(it) }
            val applied = content.appliedActions()
            val pending = try {
                WidgetActionQueue.pending(context, KIND).filter { it.id !in applied && it.action == "setDone" }
            } catch (e: Exception) {
                emptyList()
            }
            val overlaid = days.map { day ->
                var items = day.items
                for (action in pending) {
                    val id = action.args.opt("id") as? String ?: continue
                    val actionDate = action.args.opt("date") as? String ?: continue
                    val done = action.args.opt("done") as? Boolean ?: continue
                    if (actionDate != day.date) continue
                    items = items.map { if (it.id == id) it.copy(done = done) else it }
                }
                day.copy(items = items)
            }
            val todayKey = date.toString()
            val tomorrowKey = date.plusDays(1).toString()
            return TodoState(
                content = content,
                today = overlaid.firstOrNull { it.date == todayKey },
                tomorrow = overlaid.firstOrNull { it.date == tomorrowKey },
            )
        }

        /**
         * Purpose: Parse one `days` entry.
         * Inputs: `json`.
         * Returns: `TodoDay`.
         * Side effects: None.
         * Notes: Items without an id are skipped; a missing label falls back to the date.
         */
        private fun parseDay(json: JSONObject): TodoDay {
            val date = json.text("date")
            val items = json.optJSONArray("items").objects().mapNotNull { o ->
                val id = o.text("id")
                if (id.isEmpty()) {
                    null
                } else {
                    TodoItem(
                        id = id,
                        title = o.text("t"),
                        emoji = o.text("e"),
                        type = o.text("k"),
                        done = o.optBoolean("done", false),
                        time = o.text("time"),
                        late = o.optBoolean("late", false),
                        recurring = o.optBoolean("rec", false),
                        scheduled = o.optBoolean("sched", false),
                    )
                }
            }
            return TodoDay(
                date = date,
                label = json.text("label").ifEmpty { date },
                score = json.double("score"),
                items = items,
            )
        }
    }
}
