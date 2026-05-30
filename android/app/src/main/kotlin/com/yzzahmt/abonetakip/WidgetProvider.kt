package com.yzzahmt.abonetakip

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val views = android.widget.RemoteViews(context.packageName, R.layout.widget_layout)

        val totalAmount = widgetData.getString("monthly_total", "0")
        views.setTextViewText(R.id.widget_amount, "₺$totalAmount")

        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
