package ke.edenservices.eden

import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.work.*
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

/**
 * Main Activity - Device Status Dashboard
 */
class MainActivity : AppCompatActivity() {

    private val TAG = "MainActivity"
    private lateinit var tvDeviceStatus: TextView
    private lateinit var tvLoanInfo: TextView
    private lateinit var btnCheckStatus: Button
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initializeViews()
        verifyDeviceOwner()
        setupPeriodicSync()
        checkLockStatus()
    }

    private fun initializeViews() {
        tvDeviceStatus = findViewById(R.id.tv_device_status)
        tvLoanInfo = findViewById(R.id.tv_loan_info)
        btnCheckStatus = findViewById(R.id.btn_check_status)

        btnCheckStatus.setOnClickListener {
            checkLockStatus()
        }
    }

    /**
     * Verify Device Owner status
     */
    private fun verifyDeviceOwner() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        
        if (dpm.isDeviceOwnerApp(packageName)) {
            tvDeviceStatus.text = "✓ Device Protection Active"
            DeviceEnforcementManager.verifyEnforcement(this)
        } else {
            tvDeviceStatus.text = "⚠ Device Owner not configured"
            Log.e(TAG, "App is not Device Owner - provisioning required")
        }
    }

    /**
     * Setup periodic sync with Supabase using WorkManager
     */
    private fun setupPeriodicSync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val syncRequest = PeriodicWorkRequestBuilder<SupabaseSyncWorker>(
            15, TimeUnit.MINUTES,
            5, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "eden_sync",
            ExistingPeriodicWorkPolicy.KEEP,
            syncRequest
        )

        Log.i(TAG, "Periodic sync scheduled (every 15 minutes)")
    }

    /**
     * Check current lock status
     */
    private fun checkLockStatus() {
        scope.launch {
            try {
                btnCheckStatus.isEnabled = false
                btnCheckStatus.text = "Checking..."

                val supabaseClient = SupabaseClient.getInstance(this@MainActivity)
                val deviceData = supabaseClient.getDeviceStatus()

                if (deviceData != null) {
                    val isLocked = deviceData.optBoolean("is_locked", false)
                    val loanBalance = deviceData.optDouble("loan_balance", 0.0)
                    val loanTotal = deviceData.optDouble("loan_total", 0.0)

                    tvLoanInfo.text = "Loan: KES ${String.format("%.2f", loanBalance)} / ${String.format("%.2f", loanTotal)}"

                    if (isLocked && loanBalance > 0) {
                        // Device should be locked - launch lockout activity
                        launchLockoutScreen()
                    } else if (loanBalance <= 0) {
                        // Loan paid off - retire device
                        tvLoanInfo.text = "Loan Complete! Device will be unlocked..."
                        DeviceRetirementManager.retireDevice(this@MainActivity)
                    }
                } else {
                    tvLoanInfo.text = "Unable to fetch device status"
                }

                btnCheckStatus.isEnabled = true
                btnCheckStatus.text = "Check Status"

            } catch (e: Exception) {
                Log.e(TAG, "Error checking lock status", e)
                tvLoanInfo.text = "Error: ${e.message}"
                btnCheckStatus.isEnabled = true
                btnCheckStatus.text = "Check Status"
            }
        }
    }

    /**
     * Launch lockout screen (kiosk mode)
     */
    private fun launchLockoutScreen() {
        val intent = Intent(this, LockoutActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
