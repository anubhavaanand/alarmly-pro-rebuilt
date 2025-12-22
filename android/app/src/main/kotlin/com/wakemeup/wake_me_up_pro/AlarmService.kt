package com.wakemeup.wake_me_up_pro

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * AlarmService - Foreground service that plays alarm sound
 * This service is nearly impossible to kill and ensures alarm continues ringing
 */
class AlarmService : Service() {
    
    companion object {
        private const val TAG = "AlarmService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "alarm_service_channel"
        private const val WAKE_LOCK_TAG = "WakeMeUp::AlarmWakeLock"
        
        var isRinging = false
            private set
        
        var currentAlarmId = -1
            private set
    }
    
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var originalVolume: Int = 0
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AlarmService created")
        
        // Create notification channel for Android O+
        createNotificationChannel()
        
        // Initialize audio manager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Initialize vibrator
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AlarmService started")
        
        val alarmId = intent?.getIntExtra(AlarmReceiver.EXTRA_ALARM_ID, -1) ?: -1
        currentAlarmId = alarmId
        
        // Start as foreground service (prevents killing)
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Acquire wake lock (keeps CPU running)
        acquireWakeLock()
        
        // Set volume to maximum
        setMaxVolume()
        
        // Start alarm sound
        startAlarmSound()
        
        // Start vibration
        startVibration()
        
        isRinging = true
        
        // START_STICKY ensures service is recreated if killed
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AlarmService destroyed")
        stopAlarm()
    }
    
    /**
     * Stop alarm sound, vibration, and release resources
     */
    fun stopAlarm() {
        isRinging = false
        
        // Stop media player
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
        
        // Stop vibration
        vibrator?.cancel()
        
        // Restore original volume
        restoreVolume()
        
        // Release wake lock
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        
        currentAlarmId = -1
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
    
    /**
     * Acquire partial wake lock to keep CPU running
     */
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            WAKE_LOCK_TAG
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes max
    }
    
    /**
     * Set alarm volume to maximum
     */
    private fun setMaxVolume() {
        audioManager?.let { am ->
            originalVolume = am.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            am.setStreamVolume(
                AudioManager.STREAM_ALARM,
                maxVolume,
                0
            )
            Log.d(TAG, "Volume set to maximum: $maxVolume (was: $originalVolume)")
        }
    }
    
    /**
     * Restore original volume
     */
    private fun restoreVolume() {
        audioManager?.setStreamVolume(
            AudioManager.STREAM_ALARM,
            originalVolume,
            0
        )
    }
    
    /**
     * Start playing alarm sound
     */
    private fun startAlarmSound() {
        try {
            // Get default alarm sound
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                
                // Configure audio attributes for alarm
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                
                // Loop indefinitely
                isLooping = true
                
                // Prepare and start
                prepare()
                start()
            }
            
            Log.d(TAG, "Alarm sound started")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting alarm sound", e)
        }
    }
    
    /**
     * Start vibration pattern
     */
    private fun startVibration() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Pattern: vibrate 1s, pause 0.5s, repeat
            val pattern = longArrayOf(0, 1000, 500)
            val effect = VibrationEffect.createWaveform(pattern, 0) // 0 = repeat from start
            vibrator?.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            val pattern = longArrayOf(0, 1000, 500)
            vibrator?.vibrate(pattern, 0)
        }
        
        Log.d(TAG, "Vibration started")
    }
    
    /**
     * Create notification for foreground service
     */
    private fun createNotification(): Notification {
        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm Ringing")
            .setContentText("Complete the mission to dismiss")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(pendingIntent)
            .build()
    }
    
    /**
     * Create notification channel for Android O+
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Keeps alarm ringing in background"
                setSound(null, null) // No sound for service notification
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
