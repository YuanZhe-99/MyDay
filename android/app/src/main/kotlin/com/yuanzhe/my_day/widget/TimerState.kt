package com.yuanzhe.my_day.widget

import android.content.Context
import com.yuanzhe.myapps_widget.WidgetActionQueue

/** The Intimacy stopwatch session of the `myday.timer` payload. */
data class TimerSession(
    val running: Boolean,
    /** Epoch ms of the current running segment's start; null while paused. */
    val startedAt: Long?,
    /** Elapsed time of the finished segments, in ms. */
    val accumulatedMs: Long,
    /** The actual repetition count. */
    val count: Int,
) {
    /**
     * Purpose: Return the total elapsed time at an instant.
     * Inputs: `now` — epoch milliseconds.
     * Returns: Milliseconds, never negative.
     * Side effects: None.
     * Notes: A running segment counts from `startedAt` to `now`.
     */
    fun elapsedMs(now: Long): Long {
        val segment = if (running && startedAt != null) (now - startedAt).coerceAtLeast(0L) else 0L
        return (accumulatedMs + segment).coerceAtLeast(0L)
    }
}

/** The latest Intimacy record or timer-history entry. */
data class TimerLast(val at: Long, val durationMs: Long)

/**
 * The Timer widget state: the `myday.timer` envelope's session with the queued `start`, `pause`
 * and `add` taps replayed over it, using the semantics `HomeWidgetActions` applies in the app.
 */
data class TimerState(
    val content: WidgetContent,
    val session: TimerSession?,
    val last: TimerLast?,
    /** Amount the +N button adds; the payload's `step`. */
    val step: Int,
) {
    companion object {
        /** Envelope kind; matches `HomeWidgetService`. */
        const val KIND = MyDayWidget.KIND_TIMER

        /**
         * Purpose: Build the state from readable content.
         * Inputs: `context`, `content`.
         * Returns: `TimerState`.
         * Side effects: Reads the pending-action queue.
         * Notes: Pending actions whose ids are in `appliedActions` are skipped; the rest replay
         * in queue order through [apply].
         */
        fun load(context: Context, content: WidgetContent): TimerState {
            val payload = content.payload
            val sessionJson = payload.optJSONObject("session")
            var session = sessionJson?.let {
                val running = it.optBoolean("running", false)
                TimerSession(
                    running = running,
                    startedAt = if (running) it.long("startedAt") else null,
                    accumulatedMs = it.long("accumulatedMs") ?: 0L,
                    count = it.long("count")?.toInt() ?: 0,
                )
            }
            // A running session without a start cannot tick; treat it as paused.
            if (session != null && session.running && session.startedAt == null) {
                session = session.copy(running = false)
            }
            val last = payload.optJSONObject("last")?.let {
                val at = it.long("at") ?: return@let null
                TimerLast(at, it.long("durationMs") ?: 0L)
            }
            val step = payload.long("step")?.toInt()?.takeIf { it > 0 } ?: DEFAULT_STEP
            val applied = content.appliedActions()
            val pending = try {
                WidgetActionQueue.pending(context, KIND).filter { it.id !in applied }
            } catch (e: Exception) {
                emptyList()
            }
            for (action in pending) {
                val n = (action.args.opt("n") as? Number)?.toInt() ?: step
                session = apply(session, action.action, action.at, n)
            }
            return TimerState(content, session, last, step)
        }

        /** The +N amount when the payload has no `step`. */
        const val DEFAULT_STEP = 100

        /**
         * Purpose: Apply one queued timer action to a session.
         * Inputs: `session` — the current session or null; `action` — `start`, `pause` or `add`;
         * `at` — the tap time, epoch ms; `n` — the amount for `add`.
         * Returns: The new session (or the same one when the action does nothing).
         * Side effects: None.
         * Notes: start: no session → a running session from `at`; paused → running from `at`;
         * running → unchanged. pause: running → elapsed folded into `accumulatedMs`, paused.
         * add: a session exists → count += n. Unknown actions are ignored.
         */
        fun apply(session: TimerSession?, action: String, at: Long, n: Int): TimerSession? = when (action) {
            "start" -> when {
                session == null -> TimerSession(running = true, startedAt = at, accumulatedMs = 0, count = 0)
                session.running -> session
                else -> session.copy(running = true, startedAt = at)
            }
            "pause" -> if (session != null && session.running && session.startedAt != null) {
                session.copy(
                    running = false,
                    startedAt = null,
                    accumulatedMs = session.accumulatedMs + (at - session.startedAt).coerceAtLeast(0L),
                )
            } else {
                session
            }
            "add" -> session?.copy(count = session.count + n)
            else -> session
        }
    }
}
