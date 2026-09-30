package com.chronomed.chronomed

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.chronomed.chronomed.R

/**
 * Widget 4×1 de pantalla de inicio para ChronoMed.
 * Muestra la próxima dosis programada del paciente con nombre del
 * fármaco, horario y estado de adherencia del día.
 */
class NextDoseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Primer widget agregado a la pantalla de inicio
    }

    override fun onDisabled(context: Context) {
        // Último widget removido de la pantalla de inicio
    }

    companion object {
        private const val PREFS_NAME = "chronomed_widget_prefs"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val medicineName = prefs.getString("next_medicine_name", "Sin dosis pendiente") ?: "Sin dosis pendiente"
            val nextTime = prefs.getString("next_dose_time", "--:--") ?: "--:--"
            val adherenceText = prefs.getString("adherence_today", "0/0 dosis") ?: "0/0 dosis"
            val patientName = prefs.getString("patient_name", "Paciente") ?: "Paciente"

            val views = RemoteViews(context.packageName, R.layout.widget_next_dose)

            views.setTextViewText(R.id.widget_patient_name, patientName)
            views.setTextViewText(R.id.widget_medicine_name, medicineName)
            views.setTextViewText(R.id.widget_next_time, nextTime)
            views.setTextViewText(R.id.widget_adherence, adherenceText)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
