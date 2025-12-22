package com.wakemeup.wake_me_up_pro

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * AlarmReceiver - Triggered by AlarmManager when alarm time is reached
 * This is the entry point for alarm execution
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "AlarmReceiver"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_TIME = "alarm_time"
        const val EXTRA_MISSION_TYPE = "mission_type"
        const val EXTRA_DIFFICULTY = "difficulty"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm triggered!")
        
        val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
        val alarmTime = intent.getLongExtra(EXTRA_ALARM_TIME, 0)
        val missionType = intent.getStringExtra(EXTRA_MISSION_TYPE) ?: "math"
        val difficulty = intent.getIntExtra(EXTRA_DIFFICULTY, 3)
        
        if (alarmId == -1) {
            Log.e(TAG, "Invalid alarm ID received")
            return
        }
        
        Log.d(TAG, "Processing alarm #$alarmId at $alarmTime")
        
        // Start the foreground service to handle alarm
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_TIME, alarmTime)
            putExtra(EXTRA_MISSION_TYPE, missionType)
            putExtra(EXTRA_DIFFICULTY, difficulty)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
        
        // Launch full-screen activity
        val activityIntent = Intent(context, AlarmRingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_MISSION_TYPE, missionType)
            putExtra(EXTRA_DIFFICULTY, difficulty)
        }
        context.startActivity(activityIntent)
    }
}

/**
 * AlarmScheduler - Utility class to schedule alarms using AlarmManager
 */
object AlarmScheduler {
    private const val TAG = "AlarmScheduler"
    
    /**
     * Schedule an exact alarm that will wake the device from Doze mode
     * Uses setAlarmClock() for maximum reliability
     */
    fun scheduleAlarm(
        context: Context,
        alarmId: Int,
        triggerTime: Long,
        missionType: String,
        difficulty: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Check if we have permission to schedule exact alarms (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.w(TAG, "Cannot schedule exact alarms - permission denied")
                return
            }
        }
        
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_TIME, triggerTime)
            putExtra(AlarmReceiver.EXTRA_MISSION_TYPE, missionType)
            putExtra(AlarmReceiver.EXTRA_DIFFICULTY, difficulty)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create AlarmClockInfo for display in system UI
        val alarmClockInfo = AlarmManager.AlarmClockInfo(
            triggerTime,
            pendingIntent
        )
        
        // Use setAlarmClock() - this is THE ONLY method that guarantees
        // device wake from deep Doze mode
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        
        Log.d(TAG, "Alarm #$alarmId scheduled for ${java.util.Date(triggerTime)}")
    }
    
    /**
     * Cancel a scheduled alarm
     */
    fun cancelAlarm(context: Context, alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        
        Log.d(TAG, "Alarm #$alarmId cancelled")
    }
    
    /**
     * Reschedule all active alarms (used after device boot)
     */
    fun rescheduleAllAlarms(context: Context) {
        // This will be called from Flutter via MethodChannel
        // Flutter will query Isar database and reschedule each active alarm
        Log.d(TAG, "Reschedule request received")
    }
}
