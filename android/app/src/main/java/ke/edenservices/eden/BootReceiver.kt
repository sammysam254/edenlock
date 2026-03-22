package ke.edenservices.eden

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot receiver to check lock status on device restart
 */
class BootReceiver : BroadcastReceiver() {

    private val TAG = "BootReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "Device booted - checking lock status")

            val prefs = context.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
            val isLocked = prefs.getBoolean("is_locked", false)
            val isRetired = prefs.getBoolean("retired", false)

            if (isRetired) {
                Log.i(TAG, "Device is retired - no action needed")
                return
            }

            if (isLocked) {
                // Launch lockout screen
                val lockoutIntent = Intent(context, LockoutActivity::class.java)
                lockoutIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(lockoutIntent)
            } else {
                // Launch main activity
                val mainIntent = Intent(context, MainActivity::class.java)
                mainIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(mainIntent)
            }
        }
    }
}
