package com.example.calorie_ai_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val streakCount = widgetData.getInt("streak_count", 0)
                val streakInfo = widgetData.getString("streak_info", "0000000") ?: "0000000"
                val isDarkMode = widgetData.getBoolean("is_dark_mode", false)

                // Theme Colors
                if (isDarkMode) {
                    setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_background_dark)
                    setTextColor(R.id.widget_title, Color.parseColor("#EDE7F6"))
                    setTextColor(R.id.streak_count_text, Color.parseColor("#673AB7"))
                    val dayColor = Color.parseColor("#9E9E9E")
                    setTextColor(R.id.day_0, dayColor)
                    setTextColor(R.id.day_1, dayColor)
                    setTextColor(R.id.day_2, dayColor)
                    setTextColor(R.id.day_3, dayColor)
                    setTextColor(R.id.day_4, dayColor)
                    setTextColor(R.id.day_5, dayColor)
                    setTextColor(R.id.day_6, dayColor)
                } else {
                    setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_background)
                    setTextColor(R.id.widget_title, Color.parseColor("#673AB7"))
                    setTextColor(R.id.streak_count_text, Color.parseColor("#673AB7"))
                    val dayColor = Color.parseColor("#9E9E9E")
                    setTextColor(R.id.day_0, dayColor)
                    setTextColor(R.id.day_1, dayColor)
                    setTextColor(R.id.day_2, dayColor)
                    setTextColor(R.id.day_3, dayColor)
                    setTextColor(R.id.day_4, dayColor)
                    setTextColor(R.id.day_5, dayColor)
                    setTextColor(R.id.day_6, dayColor)
                }

                setTextViewText(R.id.streak_count_text, streakCount.toString())

                val dots = intArrayOf(
                    R.id.dot_0, R.id.dot_1, R.id.dot_2, R.id.dot_3,
                    R.id.dot_4, R.id.dot_5, R.id.dot_6
                )

                for (i in 0 until 7) {
                    val isActive = if (i < streakInfo.length) streakInfo[i] == '1' else false
                    val dotRes = if (isActive) {
                        R.drawable.dot_active
                    } else {
                        if (isDarkMode) R.drawable.dot_background_dark else R.drawable.dot_background
                    }
                    setImageViewResource(dots[i], dotRes)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
