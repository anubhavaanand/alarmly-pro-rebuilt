package com.wakemeup.wake_me_up_pro

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wakemeup.alarm"
    private val INTENT_CHANNEL = "com.wakemeup.intent"
    
    // Store initial alarm data if app is launched from alarm
    private var pendingAlarmData: Map<String, Any?>? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up MethodChannel for Flutter ↔ Native communication (alarm scheduling)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId")
                    val triggerTime = call.argument<Long>("triggerTime")
                    val missionType = call.argument<String>("missionType")
                    val difficulty = call.argument<Int>("difficulty")
                    
                    if (alarmId != null && triggerTime != null && missionType != null && difficulty != null) {
                        AlarmScheduler.scheduleAlarm(
                            context = applicationContext,
                            alarmId = alarmId,
                            triggerTime = triggerTime,
                            missionType = missionType,
                            difficulty = difficulty
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                
                "cancelAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId")
                    if (alarmId != null) {
                        AlarmScheduler.cancelAlarm(applicationContext, alarmId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing alarm ID", null)
                    }
                }
                
                "stopAlarm" -> {
                    // Stop the alarm service
                    val serviceIntent = Intent(applicationContext, AlarmService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up MethodChannel for receiving alarm launch intents
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> {
                    result.success(pendingAlarmData)
                    pendingAlarmData = null // Clear after sending
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Send pending alarm data to Flutter if available
        pendingAlarmData?.let { data ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
                .invokeMethod("launchAlarm", data)
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if launched from alarm ring activity or boot receiver
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        // Check if launched from boot receiver for rescheduling
        if (intent.getBooleanExtra("reschedule_alarms", false)) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("rescheduleAlarms", null)
            }
            return
        }
        
        // Check if launched from alarm ring activity
        val route = intent.getStringExtra("route")
        if (route == "/alarm-ring") {
            val alarmData = mapOf(
                "alarmId" to intent.getIntExtra("alarmId", 0),
                "missionType" to (intent.getStringExtra("missionType") ?: "math"),
                "difficulty" to intent.getIntExtra("difficulty", 3)
            )
            
            // If Flutter engine is ready, send immediately
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, INTENT_CHANNEL).invokeMethod("launchAlarm", alarmData)
            } ?: run {
                // Store for later delivery
                pendingAlarmData = alarmData
            }
        }
    }
}
