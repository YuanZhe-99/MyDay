package com.yuanzhe.my_day.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import com.yuanzhe.my_day.R
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/** The footer line of the Weight widgets and whether it is the "not logged" warning. */
data class WeightFooter(val text: String, val warning: Boolean)

/** The Weight widget state, read from the `myday.weight` envelope. */
data class WeightState(
    val content: WidgetContent,
    /** The latest weight in kg, or null without records. */
    val latestKg: Double?,
    /** Epoch ms of the latest record. */
    val latestAt: Long?,
    val previousKg: Double?,
    val change30: Double?,
    val bmi: Double?,
    /** Weights of the last 30 days, oldest first. */
    val points: List<Double>,
    /** Morning reminder `HH:mm`, or empty when the reminder mode is `none`. */
    val remindAt: String,
) {
    /**
     * Purpose: Return the change since the previous record.
     * Inputs: None.
     * Returns: Latest minus previous, in kg; null with fewer than two records.
     * Side effects: None.
     * Notes: Used by the strip.
     */
    val changeSincePrevious: Double?
        get() = if (latestKg != null && previousKg != null) latestKg - previousKg else null

    /**
     * Purpose: Build the footer at an instant.
     * Inputs: `zone` — the local zone; `now` — the current instant.
     * Returns: "Today HH:mm" for a record today; otherwise "N days ago"; replaced by the
     * warning-colored "Not logged today" once the morning reminder time has passed.
     * Side effects: None.
     * Notes: Days count local calendar days.
     */
    fun footer(zone: ZoneId = ZoneId.systemDefault(), now: Instant = Instant.now()): WeightFooter {
        val today = now.atZone(zone).toLocalDate()
        val latest = latestAt?.let { Instant.ofEpochMilli(it).atZone(zone) }
        val loggedToday = latest?.toLocalDate() == today
        if (!loggedToday && remindAt.isNotEmpty()) {
            val remind = try {
                LocalTime.parse(remindAt)
            } catch (e: Exception) {
                null
            }
            if (remind != null && !now.atZone(zone).toLocalTime().isBefore(remind)) {
                return WeightFooter(content.label("notLogged"), true)
            }
        }
        if (latest == null) return WeightFooter("", false)
        if (loggedToday) {
            return WeightFooter(content.label("today", latest.format(DateTimeFormatter.ofPattern("HH:mm"))), false)
        }
        val days = ChronoUnit.DAYS.between(latest.toLocalDate(), today).coerceAtLeast(0L)
        return WeightFooter(content.label("daysAgo", "$days"), false)
    }

    companion object {
        /** Envelope kind; matches `HomeWidgetService`. */
        const val KIND = MyDayWidget.KIND_WEIGHT

        /**
         * Purpose: Build the state from readable content.
         * Inputs: `content`.
         * Returns: `WeightState`.
         * Side effects: None.
         * Notes: A `latest` without a numeric `kg` reads as no records.
         */
        fun load(content: WidgetContent): WeightState {
            val p = content.payload
            val latest = p.optJSONObject("latest")
            val kg = latest?.double("kg")
            val array = p.optJSONArray("points")
            val points = (0 until (array?.length() ?: 0)).mapNotNull {
                (array!!.opt(it) as? Number)?.toDouble()?.takeIf { v -> v.isFinite() }
            }
            return WeightState(
                content = content,
                latestKg = kg,
                latestAt = if (kg == null) null else latest?.long("at"),
                previousKg = p.double("previousKg"),
                change30 = p.double("change30"),
                bmi = p.double("bmi"),
                points = points,
                remindAt = p.text("remindAt"),
            )
        }

        /**
         * Purpose: Draw the 30-day sparkline into a bitmap.
         * Inputs: `context`; `points` — oldest first; `widthDp`, `heightDp` — the target size.
         * Returns: The bitmap, or null with fewer than two points.
         * Side effects: Allocates a bitmap.
         * Notes: A primary-tone line over a faint fill, with a dot on the latest weight. The
         * ImageView scales it with `fitXY`, so the size only has to be close. Capped at 720 px
         * wide to keep the RemoteViews parcel small.
         */
        fun sparkline(context: Context, points: List<Double>, widthDp: Int, heightDp: Int): Bitmap? {
            if (points.size < 2) return null
            val density = context.resources.displayMetrics.density
            val width = (widthDp * density).toInt().coerceIn(48, 720)
            val height = (heightDp * density).toInt().coerceIn(16, 240)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val tone = context.getColor(R.color.widget_primary)
            val stroke = 2f * density
            val inset = stroke * 2
            val min = points.minOrNull() ?: 0.0
            val max = points.maxOrNull() ?: 0.0
            val range = if (max - min < 0.1) 0.1 else max - min
            val step = (width - inset * 2) / (points.size - 1)
            fun x(i: Int): Float = inset + i * step
            fun y(v: Double): Float = (height - inset - ((v - min) / range) * (height - inset * 2)).toFloat()

            val line = Path()
            points.forEachIndexed { i, v -> if (i == 0) line.moveTo(x(i), y(v)) else line.lineTo(x(i), y(v)) }
            val fill = Path(line)
            fill.lineTo(x(points.size - 1), height.toFloat())
            fill.lineTo(x(0), height.toFloat())
            fill.close()

            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = tone
                alpha = 40
            }
            canvas.drawPath(fill, fillPaint)
            val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                color = tone
            }
            canvas.drawPath(line, linePaint)
            val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = tone
            }
            canvas.drawCircle(x(points.size - 1), y(points.last()), stroke * 1.5f, dotPaint)
            return bitmap
        }

        /**
         * Purpose: Return the color for a signed weight change.
         * Inputs: `change`.
         * Returns: The positive (green) color for a loss, the variant color otherwise.
         * Side effects: None.
         * Notes: A change that rounds to zero is neutral.
         */
        fun changeColor(change: Double): Int =
            if (change < -0.05) R.color.widget_positive else R.color.widget_on_surface_variant
    }
}
