package com.chronomed.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.chronomed.app/widget"
    private val PREFS_NAME = "chronomed_widget_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgetData") {
                val patientName = call.argument<String>("patientName") ?: "Paciente"
                val nextMedicineName = call.argument<String>("nextMedicineName") ?: "Sin dosis pendiente"
                val nextDoseTime = call.argument<String>("nextDoseTime") ?: "--:--"
                val adherenceToday = call.argument<String>("adherenceToday") ?: "0/0 dosis"

                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putString("patient_name", patientName)
                    putString("next_medicine_name", nextMedicineName)
                    putString("next_dose_time", nextDoseTime)
                    putString("adherence_today", adherenceToday)
                    apply()
                }

                // Disparar actualización en todos los widgets activos instalados
                val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(applicationContext, NextDoseWidgetProvider::class.java)
                )
                for (id in ids) {
                    NextDoseWidgetProvider.updateAppWidget(applicationContext, appWidgetManager, id)
                }

                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
