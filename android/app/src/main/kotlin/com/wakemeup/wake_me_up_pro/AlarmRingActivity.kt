package com.wakemeup.wake_me_up_pro

import android.os.Bundle
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity

class AlarmRingActivity : AppCompatActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make activity full-screen and show over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        // Get alarm details from intent
        val alarmId = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_ID, -1)
        val missionType = intent.getStringExtra(AlarmReceiver.EXTRA_MISSION_TYPE) ?: "math"
        val difficulty = intent.getIntExtra(AlarmReceiver.EXTRA_DIFFICULTY, 3)
        
        // Launch Flutter app with alarm details
        val flutterIntent = packageManager.getLaunchIntentForPackage(packageName)
        flutterIntent?.apply {
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("route", "/alarm-ring")
            putExtra("alarmId", alarmId)
            putExtra("missionType", missionType)
            putExtra("difficulty", difficulty)
        }
        
        startActivity(flutterIntent)
        finish()
    }
}
