package ke.edenservices.eden

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Background worker to periodically sync device lock status with Supabase
 */
class SupabaseSyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val TAG = "SupabaseSyncWorker"

    override suspend fun doWork(): Result {
        return try {
            Log.i(TAG, "Starting Supabase sync...")

            val supabaseClient = SupabaseClient.getInstance(applicationContext)
            val deviceData = supabaseClient.getDeviceStatus()

            if (deviceData != null) {
                val isLocked = deviceData.optBoolean("is_locked", false)
                val loanBalance = deviceData.optDouble("loan_balance", 0.0)

                Log.i(TAG, "Sync complete - Locked: $isLocked, Balance: $loanBalance")

                // Store current status
                val prefs = applicationContext.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putBoolean("is_locked", isLocked)
                    putFloat("loan_balance", loanBalance.toFloat())
                    apply()
                }

                // If device should be locked, trigger lockout
                if (isLocked && loanBalance > 0) {
                    triggerLockout()
                } else if (loanBalance <= 0) {
                    // Loan paid off - trigger retirement
                    DeviceRetirementManager.retireDevice(applicationContext)
                }

                Result.success()
            } else {
                Log.w(TAG, "Failed to fetch device status")
                Result.retry()
            }

        } catch (e: Exception) {
            Log.e(TAG, "Sync failed", e)
            Result.retry()
        }
    }

    /**
     * Trigger lockout screen
     */
    private fun triggerLockout() {
        val intent = Intent(applicationContext, LockoutActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        applicationContext.startActivity(intent)
    }
}
