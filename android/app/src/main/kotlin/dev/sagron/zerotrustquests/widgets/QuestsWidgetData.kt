package dev.sagron.zerotrustquests.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import dev.sagron.zerotrustquests.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * What every Quests widget shows, read from what the app wrote
 * (lib/widgets/quests_widgets.dart) under `quests_widget_data`, one JSON:
 *
 * ```
 * {"day": "2026-11-17", "details": true, "xp": 1234, "gold": 56,
 *  "streak": 4, "freezes": 1, "todayDone": false,
 *  "titles": [[1, "Novice"], [3, "Apprentice"], ...],
 *  "quests": [{"id": "...", "goal": "Get fitter", "xp": 30, "gold": 10,
 *              "steps": [{"t": "25 push-ups", "done": false}, ...]}]}
 * ```
 *
 * Step texts and goal names are there only with "Show details on the home
 * screen" on; otherwise "t" and "goal" are empty and the widgets show
 * counts. The widgets never read the vault.
 *
 * A step ticked on a widget is marked done here at once (and the quest's
 * XP and gold added when that finishes it), and queued under
 * `quests_widget_pending` as `<number>|<quest id>|<step index>` for the app,
 * which saves it the next time it is open and unlocked and then records the
 * number under `quests_widget_ack`.
 */
object QuestsWidgetData {
    const val DATA_KEY = "quests_widget_data"
    const val SIGNED_OUT_KEY = "quests_widget_signed_out"
    const val PENDING_KEY = "quests_widget_pending"

    /** The last tick number given out (as text). */
    const val SEQ_KEY = "quests_widget_seq"

    /** The last tick number the app saved (as text); written by the app only. */
    const val ACK_KEY = "quests_widget_ack"
    private const val ACTION_MIDNIGHT = "dev.sagron.zerotrustquests.widgets.MIDNIGHT"

    data class Step(val text: String, val done: Boolean)

    data class Quest(val id: String, val goal: String, val steps: List<Step>)

    /** The widgets' state for today, the day they are drawn. */
    data class State(
        val signedOut: Boolean,
        /** The app wrote for an earlier day and hasn't run since. */
        val stale: Boolean,
        val details: Boolean,
        val xp: Int,
        val gold: Int,
        val streak: Int,
        /** Today has a completed quest, so the streak is safe. */
        val todayDone: Boolean,
        val quests: List<Quest>,
        val titles: List<Pair<Int, String>>,
    ) {
        val level: Int get() = levelFor(xp)
        val title: String
            get() = titles.lastOrNull { level >= it.first }?.second ?: ""
        val stepsTotal: Int get() = quests.sumOf { it.steps.size }
        val stepsDone: Int get() = quests.sumOf { q -> q.steps.count { it.done } }

        /** The first unfinished step: (quest, step index). */
        val next: Pair<Quest, Int>?
            get() {
                for (q in quests) {
                    val i = q.steps.indexOfFirst { !it.done }
                    if (i >= 0) return q to i
                }
                return null
            }
    }

    /** Level L needs 50 x L x (L - 1) XP, as lib/engine/hero.dart. */
    fun xpAt(level: Int) = 50 * level * (level - 1)

    fun levelFor(xp: Int): Int = max(1, floor((50 + sqrt(2500.0 + 200.0 * max(0, xp))) / 100).toInt())

    fun today(): String = LocalDate.now().toString()

    private fun readJson(prefs: SharedPreferences): JSONObject? = try {
        prefs.getString(DATA_KEY, null)?.let { JSONObject(it) }
    } catch (e: Exception) {
        null
    }

    fun read(prefs: SharedPreferences): State {
        val signedOut = prefs.getBoolean(SIGNED_OUT_KEY, false)
        val json = if (signedOut) null else readJson(prefs)
        val day = json?.optString("day").orEmpty()
        val today = today()
        val stale = json == null || day != today
        val writtenDone = json?.optBoolean("todayDone") ?: false
        var streak = json?.optInt("streak") ?: 0
        if (json != null && stale) {
            // Days missed since the app last wrote, bridged by freezes, as
            // the app would count them; it puts it right when it opens.
            val gap = try {
                ChronoUnit.DAYS.between(LocalDate.parse(day), LocalDate.parse(today)).toInt()
            } catch (e: Exception) {
                Int.MAX_VALUE
            }
            if (gap <= 0) {
                // The phone's clock went back: leave it as written.
            } else {
                val missed = (gap - 1) + (if (writtenDone) 0 else 1)
                if (missed > json.optInt("freezes")) streak = 0
            }
        }
        val titles = mutableListOf<Pair<Int, String>>()
        json?.optJSONArray("titles")?.let { arr ->
            for (i in 0 until arr.length()) {
                val pair = arr.optJSONArray(i) ?: continue
                titles.add(pair.optInt(0) to pair.optString(1))
            }
        }
        val quests = mutableListOf<Quest>()
        if (json != null && !stale) {
            val arr = json.optJSONArray("quests") ?: JSONArray()
            for (i in 0 until arr.length()) {
                val q = arr.optJSONObject(i) ?: continue
                val id = q.optString("id")
                if (id.isEmpty()) continue
                val steps = q.optJSONArray("steps") ?: JSONArray()
                quests.add(
                    Quest(
                        id,
                        q.optString("goal"),
                        (0 until steps.length()).mapNotNull { j ->
                            steps.optJSONObject(j)?.let { Step(it.optString("t"), it.optBoolean("done")) }
                        },
                    ),
                )
            }
        }
        return State(
            signedOut = signedOut,
            stale = stale,
            details = json?.optBoolean("details") ?: false,
            xp = json?.optInt("xp") ?: 0,
            gold = json?.optInt("gold") ?: 0,
            streak = streak,
            todayDone = !stale && writtenDone,
            quests = quests,
            titles = titles,
        )
    }

    /**
     * Marks step [index] of quest [questId] done and queues it for the app.
     * Only a step a widget shows today can be ticked, and only once.
     */
    fun tick(context: Context, questId: String, index: Int) {
        val prefs = HomeWidgetPlugin.getData(context)
        if (prefs.getBoolean(SIGNED_OUT_KEY, false)) return
        val json = readJson(prefs) ?: return
        if (json.optString("day") != today()) return
        val quests = json.optJSONArray("quests") ?: return
        var quest: JSONObject? = null
        for (i in 0 until quests.length()) {
            val q = quests.optJSONObject(i) ?: continue
            if (q.optString("id") == questId) quest = q
        }
        val found = quest ?: return
        val steps = found.optJSONArray("steps") ?: return
        val step = steps.optJSONObject(index) ?: return
        if (step.optBoolean("done")) return
        step.put("done", true)
        val finished = (0 until steps.length()).all { steps.optJSONObject(it)?.optBoolean("done") == true }
        if (finished) {
            // The first quest done today adds today to the streak.
            if (!json.optBoolean("todayDone")) {
                json.put("todayDone", true)
                json.put("streak", json.optInt("streak") + 1)
            }
            // Streak bonus, as lib/engine/hero.dart: 5% per day in a row
            // before today, up to 50%.
            val xp = found.optInt("xp")
            val bonus = floor(xp * min(json.optInt("streak") - 1, 10).coerceAtLeast(0) * 0.05).toInt()
            json.put("xp", json.optInt("xp") + xp + bonus)
            json.put("gold", json.optInt("gold") + found.optInt("gold"))
        }
        // The queue has one writer, this receiver; the app only records the
        // last tick it saved (ACK_KEY), and saved lines are dropped here.
        val acked = prefs.getString(ACK_KEY, null)?.toLongOrNull() ?: 0L
        val seq = (prefs.getString(SEQ_KEY, null)?.toLongOrNull() ?: 0L) + 1
        val kept = prefs.getString(PENDING_KEY, null).orEmpty().split('\n').filter { line ->
            val n = line.substringBefore('|').toLongOrNull()
            n != null && n > acked
        }
        prefs.edit()
            .putString(DATA_KEY, json.toString())
            .putString(SEQ_KEY, seq.toString())
            .putString(PENDING_KEY, (kept + "$seq|$questId|$index").joinToString("\n"))
            .apply()
        updateAll(context)
    }

    /**
     * A widget string in the language picked in the app (written as
     * `quests_widget_text_<key>`), or the phone's language from strings.xml
     * until the app has run once.
     */
    fun text(context: Context, prefs: SharedPreferences, key: String, fallback: Int): String =
        prefs.getString("quests_widget_text_$key", null) ?: context.getString(fallback)

    /** Fills a `%d`/`%1$d` text written by the app or from strings.xml. */
    fun format(template: String, vararg args: Int): String = try {
        String.format(java.util.Locale.getDefault(), template, *args.toTypedArray())
    } catch (e: Exception) {
        template
    }

    fun openApp(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("zerotrustquests://open"))

    /** A tick for step [index] of [questId], to the app's own receiver. */
    fun tickIntent(context: Context, questId: String, index: Int): PendingIntent {
        val intent = Intent(context, QuestsWidgetTapReceiver::class.java).apply {
            action = QuestsWidgetTapReceiver.ACTION_TICK
            putExtra(QuestsWidgetTapReceiver.EXTRA_QUEST, questId)
            putExtra(QuestsWidgetTapReceiver.EXTRA_STEP, index)
            // Distinct data per step, or Android reuses one PendingIntent.
            data = Uri.parse("zerotrustquests://tick/" + Uri.encode(questId) + "/" + index)
        }
        return PendingIntent.getBroadcast(
            context,
            (questId + index).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private val providers = listOf(
        TodayQuestWidgetProvider::class.java,
        HeroWidgetProvider::class.java,
        StreakWidgetProvider::class.java,
        NextStepWidgetProvider::class.java,
    )

    /** Redraws every Quests widget, e.g. after a tick or at midnight. */
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (provider in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isEmpty()) continue
            context.sendBroadcast(
                Intent(context, provider)
                    .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
            )
        }
    }

    /**
     * Redraws at the next midnight, when yesterday's quests give way to
     * "New quests are ready" and the streak shows its warning.
     */
    fun scheduleMidnight(context: Context) {
        val next = java.util.Calendar.getInstance().apply {
            add(java.util.Calendar.DAY_OF_MONTH, 1)
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 5)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val intent = Intent(context, QuestsWidgetTapReceiver::class.java).setAction(ACTION_MIDNIGHT)
        val pending = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Inexact is fine: a few minutes late costs nothing.
        alarms.set(AlarmManager.RTC, next.timeInMillis, pending)
    }

    fun onMidnight(context: Context, intent: Intent): Boolean {
        if (intent.action != ACTION_MIDNIGHT) return false
        scheduleMidnight(context)
        updateAll(context)
        return true
    }
}

/**
 * Receives the widgets' own ticks and the midnight redraw. Not exported, so
 * only this app's PendingIntents reach it; no other app can tick a step.
 */
class QuestsWidgetTapReceiver : android.content.BroadcastReceiver() {
    companion object {
        const val ACTION_TICK = "dev.sagron.zerotrustquests.widgets.TICK"
        const val EXTRA_QUEST = "quest_id"
        const val EXTRA_STEP = "step"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (QuestsWidgetData.onMidnight(context, intent)) return
        if (intent.action != ACTION_TICK) return
        val questId = intent.getStringExtra(EXTRA_QUEST) ?: return
        val step = intent.getIntExtra(EXTRA_STEP, -1)
        if (step < 0) return
        QuestsWidgetData.tick(context, questId, step)
    }
}
