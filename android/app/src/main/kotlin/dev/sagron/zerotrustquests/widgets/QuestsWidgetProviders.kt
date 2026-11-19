package dev.sagron.zerotrustquests.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import dev.sagron.zerotrustquests.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The four Quests widgets (today's quest, hero card, streak, next step), in
 * the shared Zero-Trust widget look (Zero-Trust-Core/android-widget-kit).
 * Each draws from [QuestsWidgetData] and picks what to show from its size.
 */
abstract class QuestsWidgetProvider : HomeWidgetProvider() {

    abstract fun build(context: Context, prefs: SharedPreferences, options: Bundle?): RemoteViews

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        QuestsWidgetData.scheduleMidnight(context)
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, build(context, widgetData, appWidgetManager.getAppWidgetOptions(id)))
        }
    }

    /** Resized: redraw with what now fits. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, build(context, HomeWidgetPlugin.getData(context), newOptions))
    }

    protected fun height(options: Bundle?) = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0) ?: 0

    protected fun width(options: Bundle?) = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0

    protected fun t(context: Context, prefs: SharedPreferences, key: String, fallback: Int) =
        QuestsWidgetData.text(context, prefs, key, fallback)
}

/**
 * Today's quest: the steps of today's daily quests, each with a tick
 * circle. A tick marks the step done at once and the app saves it when it
 * next opens. With "Show details on the home screen" off it shows only how
 * many steps are done.
 */
class TodayQuestWidgetProvider : QuestsWidgetProvider() {
    companion object {
        private const val MAX_ROWS = 6
        private val ROW = intArrayOf(R.id.row_0, R.id.row_1, R.id.row_2, R.id.row_3, R.id.row_4, R.id.row_5)
        private val CHECK = intArrayOf(R.id.row_0_check, R.id.row_1_check, R.id.row_2_check, R.id.row_3_check, R.id.row_4_check, R.id.row_5_check)
        private val TEXT = intArrayOf(R.id.row_0_text, R.id.row_1_text, R.id.row_2_text, R.id.row_3_text, R.id.row_4_text, R.id.row_5_text)
        private val TITLE = intArrayOf(R.id.row_0_title, R.id.row_1_title, R.id.row_2_title, R.id.row_3_title, R.id.row_4_title, R.id.row_5_title)
        private val GOAL = intArrayOf(R.id.row_0_goal, R.id.row_1_goal, R.id.row_2_goal, R.id.row_3_goal, R.id.row_4_goal, R.id.row_5_goal)
    }

    private data class Row(val questId: String, val index: Int, val text: String, val goal: String, val done: Boolean)

    override fun build(context: Context, prefs: SharedPreferences, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today)
        val s = QuestsWidgetData.read(prefs)
        val height = height(options)
        val showAppRow = height == 0 || height >= 160
        views.setViewVisibility(R.id.app_row, if (showAppRow) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.header, QuestsWidgetData.openApp(context))
        views.setOnClickPendingIntent(R.id.app_row, QuestsWidgetData.openApp(context))
        views.setOnClickPendingIntent(R.id.locked, QuestsWidgetData.openApp(context))
        views.setTextViewText(R.id.title, t(context, prefs, "today_title", R.string.widget_today_title))

        val total = s.stepsTotal
        val done = s.stepsDone
        val summary = when {
            s.signedOut -> t(context, prefs, "signed_out", R.string.widget_signed_out)
            s.stale -> t(context, prefs, "new_day", R.string.widget_new_day)
            total == 0 -> t(context, prefs, "no_quests", R.string.widget_no_quests)
            done == total -> t(context, prefs, "all_done", R.string.widget_all_done)
            else -> QuestsWidgetData.format(t(context, prefs, "steps_done", R.string.widget_steps_done), done, total)
        }
        views.setTextViewText(R.id.summary, summary)

        // Nothing to list: signed out, or steps hidden by the privacy switch.
        val hidden = !s.signedOut && !s.stale && total > 0 && !s.details
        val roomForLock = height == 0 || height >= 100
        views.setViewVisibility(R.id.locked, if ((s.signedOut || hidden) && roomForLock) View.VISIBLE else View.GONE)
        views.setTextViewText(
            R.id.locked_text,
            if (s.signedOut) t(context, prefs, "open_app", R.string.widget_open_app)
            else t(context, prefs, "open_to_see", R.string.widget_open_to_see),
        )

        val rows = if (s.signedOut || s.stale || !s.details) emptyList() else s.quests.flatMap { q ->
            q.steps.mapIndexed { i, step -> Row(q.id, i, step.text, q.goal, step.done) }
        }
        // Unfinished steps first, so the rows that fit are the useful ones.
        val ordered = rows.filter { !it.done } + rows.filter { it.done }
        val shown = ordered.take(rowsFor(height, showAppRow))
        views.setViewVisibility(R.id.rows, if (shown.isEmpty()) View.GONE else View.VISIBLE)
        val showGoal = s.quests.size > 1
        val completeStep = t(context, prefs, "complete_step", R.string.widget_complete_step)
        for (i in 0 until MAX_ROWS) {
            val row = shown.getOrNull(i)
            if (row == null) {
                views.setViewVisibility(ROW[i], View.GONE)
                continue
            }
            views.setViewVisibility(ROW[i], View.VISIBLE)
            views.setTextViewText(TITLE[i], row.text)
            views.setViewVisibility(GOAL[i], if (showGoal && row.goal.isNotEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(GOAL[i], row.goal)
            views.setOnClickPendingIntent(TEXT[i], QuestsWidgetData.openApp(context))
            if (row.done) {
                views.setImageViewResource(CHECK[i], R.drawable.widget_step_done)
                views.setContentDescription(CHECK[i], null)
                // A done step stays done: the widget only ticks.
                views.setOnClickPendingIntent(CHECK[i], QuestsWidgetData.openApp(context))
            } else {
                views.setImageViewResource(CHECK[i], R.drawable.zt_widget_check_ring)
                views.setContentDescription(CHECK[i], completeStep)
                views.setOnClickPendingIntent(CHECK[i], QuestsWidgetData.tickIntent(context, row.questId, row.index))
            }
        }
        return views
    }

    /** Rows that fit under the header at [height] dp (0: unknown, all). */
    private fun rowsFor(height: Int, showAppRow: Boolean): Int {
        if (height == 0) return MAX_ROWS
        // Padding 28, title and summary 44, gap 6, app name row 26; rows 40 each.
        val free = height - 78 - (if (showAppRow) 26 else 0)
        return (free / 40).coerceIn(0, MAX_ROWS)
    }
}

/** Hero card: level and title, XP to the next level, and gold. */
class HeroWidgetProvider : QuestsWidgetProvider() {
    override fun build(context: Context, prefs: SharedPreferences, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_hero)
        val s = QuestsWidgetData.read(prefs)
        val height = height(options)
        views.setViewVisibility(R.id.app_row, if (height == 0 || height >= 120) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.widget_root, QuestsWidgetData.openApp(context))
        if (s.signedOut) {
            views.setViewVisibility(R.id.main, View.GONE)
            views.setViewVisibility(R.id.locked, View.VISIBLE)
            views.setTextViewText(R.id.locked_text, t(context, prefs, "signed_out", R.string.widget_signed_out))
            return views
        }
        views.setViewVisibility(R.id.main, View.VISIBLE)
        views.setViewVisibility(R.id.locked, View.GONE)
        val level = s.level
        val into = s.xp - QuestsWidgetData.xpAt(level)
        val need = QuestsWidgetData.xpAt(level + 1) - QuestsWidgetData.xpAt(level)
        views.setTextViewText(R.id.level, QuestsWidgetData.format(t(context, prefs, "level", R.string.widget_level), level))
        views.setTextViewText(R.id.hero_title, s.title.ifEmpty { context.getString(R.string.widget_title_novice) })
        views.setProgressBar(R.id.xp_bar, need, into.coerceIn(0, need), false)
        views.setTextViewText(R.id.xp, QuestsWidgetData.format(t(context, prefs, "xp", R.string.widget_xp), into, need))
        views.setTextViewText(R.id.gold, s.gold.toString())
        views.setContentDescription(R.id.gold, QuestsWidgetData.format(t(context, prefs, "gold", R.string.widget_gold), s.gold))
        return views
    }
}

/**
 * Streak: the flame and days in a row. While today has no completed quest
 * the surface turns amber and the caption says to do one today.
 */
class StreakWidgetProvider : QuestsWidgetProvider() {
    override fun build(context: Context, prefs: SharedPreferences, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_streak)
        val s = QuestsWidgetData.read(prefs)
        views.setOnClickPendingIntent(R.id.widget_root, QuestsWidgetData.openApp(context))
        val warn = !s.signedOut && !s.todayDone
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (warn) R.drawable.widget_warn_background else R.drawable.zt_widget_background,
        )
        views.setInt(
            R.id.flame,
            "setColorFilter",
            context.getColor(
                when {
                    s.signedOut -> R.color.zt_widget_on_surface_variant
                    warn -> R.color.widget_warn
                    else -> R.color.widget_flame
                },
            ),
        )
        views.setTextViewText(R.id.count, if (s.signedOut) "–" else s.streak.toString())
        // At 1x1 there is room for one short line.
        val roomy = height(options).let { it == 0 || it >= 90 }
        val caption = when {
            s.signedOut -> t(context, prefs, "signed_out", R.string.widget_signed_out)
            warn && roomy -> t(context, prefs, "streak_warn", R.string.widget_streak_warn)
            !warn && roomy -> t(context, prefs, "streak_done", R.string.widget_streak_done)
            else -> t(context, prefs, "streak", R.string.widget_streak)
        }
        views.setTextViewText(R.id.caption, caption)
        views.setContentDescription(
            R.id.widget_root,
            t(context, prefs, "streak", R.string.widget_streak) + " " + s.streak + ". " + caption,
        )
        return views
    }
}

/**
 * Next step: the first unfinished step of today's quests, which moves on as
 * steps are done (here, on another widget or in the app). From two cells
 * wide it gets a tick button.
 */
class NextStepWidgetProvider : QuestsWidgetProvider() {
    override fun build(context: Context, prefs: SharedPreferences, options: Bundle?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_next_step)
        val s = QuestsWidgetData.read(prefs)
        views.setOnClickPendingIntent(R.id.widget_root, QuestsWidgetData.openApp(context))
        views.setOnClickPendingIntent(R.id.main, QuestsWidgetData.openApp(context))
        views.setTextViewText(R.id.label, t(context, prefs, "next_step", R.string.widget_next_step))
        val next = if (s.signedOut || s.stale) null else s.next
        val left = s.stepsTotal - s.stepsDone
        val step = when {
            s.signedOut -> t(context, prefs, "signed_out", R.string.widget_signed_out)
            s.stale -> t(context, prefs, "new_day", R.string.widget_new_day)
            s.stepsTotal == 0 -> t(context, prefs, "no_quests", R.string.widget_no_quests)
            next == null -> t(context, prefs, "all_done", R.string.widget_all_done)
            !s.details -> QuestsWidgetData.format(t(context, prefs, "steps_left", R.string.widget_steps_left), left)
            else -> next.first.steps[next.second].text
        }
        views.setTextViewText(R.id.step, step)
        val wide = width(options).let { it == 0 || it >= 150 }
        val tall = height(options).let { it == 0 || it >= 90 }
        // The count under the step, when there is room and it adds something.
        val showLeft = next != null && s.details && tall && left > 1
        views.setViewVisibility(R.id.left, if (showLeft) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.left, QuestsWidgetData.format(t(context, prefs, "steps_left", R.string.widget_steps_left), left))
        val canTick = next != null && s.details && wide
        views.setViewVisibility(R.id.tick, if (canTick) View.VISIBLE else View.GONE)
        if (canTick) {
            views.setContentDescription(R.id.tick, t(context, prefs, "complete_step", R.string.widget_complete_step))
            views.setOnClickPendingIntent(R.id.tick, QuestsWidgetData.tickIntent(context, next!!.first.id, next.second))
        }
        return views
    }
}
