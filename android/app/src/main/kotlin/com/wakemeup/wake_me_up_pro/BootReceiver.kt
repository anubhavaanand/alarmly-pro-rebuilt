package com.wakemeup.wake_me_up_pro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver - Reschedules all alarms after device boot
 * Critical for ensuring alarms persist across reboots
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        const val ACTION_RESCHEDULE = "com.wakemeup.wake_me_up_pro.RESCHEDULE_ALARMS"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "Device boot detected - rescheduling alarms")
                rescheduleAlarms(context)
            }
            
            ACTION_RESCHEDULE -> {
                Log.d(TAG, "Manual reschedule requested")
                rescheduleAlarms(context)
            }
        }
    }
    
    /**
     * Send broadcast to Flutter app to reschedule alarms
     * Flutter will query the database and reschedule each active alarm
     */
    private fun rescheduleAlarms(context: Context) {
        // Wake up the Flutter app to handle rescheduling
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            it.putExtra("reschedule_alarms", true)
            context.startActivity(it)
        }
        
        Log.d(TAG, "Reschedule request sent to Flutter app")
    }
}
