package com.example.calorie_ai_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.text.NumberFormat
import java.util.Locale

class CalorieWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.calorie_widget_layout).apply {
                val consumed = widgetData.getInt("consumed_calories", 0)
                val goal = widgetData.getInt("calorie_goal", 2000)
                val water = widgetData.getInt("water_intake", 0)
                val isDarkMode = widgetData.getBoolean("is_dark_mode", true)

                // Theme Colors
                if (isDarkMode) {
                    setInt(R.id.calorie_widget_container, "setBackgroundResource", R.drawable.calorie_widget_background)
                    setTextColor(R.id.calorie_count_text, Color.parseColor("#FFFFFF"))
                    setTextColor(R.id.goal_text, Color.parseColor("#FFFFFF"))
                    setTextColor(R.id.water_text, Color.parseColor("#FFFFFF"))
                    setTextColor(R.id.kcal_label, Color.parseColor("#9E9E9E"))
                    setTextColor(R.id.water_label, Color.parseColor("#757575"))
                    setTextColor(R.id.budget_label, Color.parseColor("#757575"))

                    // Show dark rings, hide light rings
                    setViewVisibility(R.id.calorie_ring_bg_dark, android.view.View.VISIBLE)
                    setViewVisibility(R.id.calorie_progress_bar, android.view.View.VISIBLE)
                    setViewVisibility(R.id.calorie_ring_bg_light, android.view.View.GONE)
                    setViewVisibility(R.id.calorie_progress_bar_light, android.view.View.GONE)
                    setInt(R.id.stats_divider, "setBackgroundColor", Color.parseColor("#333333"))
                } else {
                    setInt(R.id.calorie_widget_container, "setBackgroundResource", R.drawable.calorie_widget_background_light)
                    setTextColor(R.id.calorie_count_text, Color.parseColor("#1C1C1E"))
                    setTextColor(R.id.goal_text, Color.parseColor("#1C1C1E"))
                    setTextColor(R.id.water_text, Color.parseColor("#1C1C1E"))
                    setTextColor(R.id.kcal_label, Color.parseColor("#757575"))
                    setTextColor(R.id.water_label, Color.parseColor("#9E9E9E"))
                    setTextColor(R.id.budget_label, Color.parseColor("#9E9E9E"))

                    // Show light rings, hide dark rings
                    setViewVisibility(R.id.calorie_ring_bg_dark, android.view.View.GONE)
                    setViewVisibility(R.id.calorie_progress_bar, android.view.View.GONE)
                    setViewVisibility(R.id.calorie_ring_bg_light, android.view.View.VISIBLE)
                    setViewVisibility(R.id.calorie_progress_bar_light, android.view.View.VISIBLE)
                    setInt(R.id.stats_divider, "setBackgroundColor", Color.parseColor("#D0D0D0"))
                }

                val fmt = NumberFormat.getNumberInstance(Locale.US)

                setTextViewText(R.id.calorie_count_text, fmt.format(consumed))
                setTextViewText(R.id.goal_text, "${fmt.format(goal)} kcal")

                // Update progress ring (both dark and light variants)
                setProgressBar(R.id.calorie_progress_bar, goal, consumed, false)
                setProgressBar(R.id.calorie_progress_bar_light, goal, consumed, false)

                val waterStr = if (water >= 1000) {
                    String.format("%.1f L", water / 1000f)
                } else {
                    "$water ml"
                }
                setTextViewText(R.id.water_text, waterStr)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.calorie_widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
