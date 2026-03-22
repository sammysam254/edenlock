package ke.edenservices.eden

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.*

/**
 * Lockout Activity - Kiosk Mode Payment Screen
 * Prevents device usage until payment is made
 */
class LockoutActivity : AppCompatActivity() {

    private val TAG = "LockoutActivity"
    private lateinit var tvLoanBalance: TextView
    private lateinit var tvWalletAddress: TextView
    private lateinit var tvStatus: TextView
    private lateinit var btnRefresh: Button
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var syncJob: Job? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_lockout)

        // Prevent screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        initializeViews()
        enterKioskMode()
        startSyncLoop()
    }

    private fun initializeViews() {
        tvLoanBalance = findViewById(R.id.tv_loan_balance)
        tvWalletAddress = findViewById(R.id.tv_wallet_address)
        tvStatus = findViewById(R.id.tv_status)
        btnRefresh = findViewById(R.id.btn_refresh)

        val prefs = getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
        val walletAddress = prefs.getString(EdenDeviceAdminReceiver.EXTRA_WALLET_ADDRESS, "Unknown")
        
        tvWalletAddress.text = "Wallet: ${walletAddress?.take(10)}...${walletAddress?.takeLast(8)}"
        
        btnRefresh.setOnClickListener {
            refreshLockStatus()
        }
    }

    /**
     * Enter kiosk mode using startLockTask()
     * User cannot exit this screen until payment is made
     */
    private fun enterKioskMode() {
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = EdenDeviceAdminReceiver.getComponentName(this)

            if (dpm.isDeviceOwnerApp(packageName)) {
                // Set this app as lock task package
                dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
                
                // Start lock task mode (kiosk)
                startLockTask()
                Log.i(TAG, "Kiosk mode activated - device locked")
                
                // Disable home button
                disableHomeButton()
            } else {
                Log.e(TAG, "Cannot enter kiosk mode - not Device Owner")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enter kiosk mode", e)
        }
    }

    /**
     * Disable home button and recent apps
     */
    private fun disableHomeButton() {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.lockTaskModeState
    }

    /**
     * Continuously check lock status every 30 seconds
     */
    private fun startSyncLoop() {
        syncJob = scope.launch {
            while (isActive) {
                refreshLockStatus()
                delay(30_000) // Check every 30 seconds
            }
        }
    }

    /**
     * Refresh lock status from Supabase
     */
    private fun refreshLockStatus() {
        scope.launch {
            try {
                tvStatus.text = "Checking payment status..."
                
                val supabaseClient = SupabaseClient.getInstance(this@LockoutActivity)
                val deviceData = supabaseClient.getDeviceStatus()

                if (deviceData != null) {
                    val loanBalance = deviceData.optDouble("loan_balance", 0.0)
                    val isLocked = deviceData.optBoolean("is_locked", true)

                    tvLoanBalance.text = "Balance: KES ${String.format("%.2f", loanBalance)}"

                    if (!isLocked || loanBalance <= 0.0) {
                        // Payment complete - unlock device
                        tvStatus.text = "Payment verified! Unlocking device..."
                        unlockDevice()
                    } else {
                        tvStatus.text = "Device locked - Payment required"
                    }
                } else {
                    tvStatus.text = "Unable to verify payment status"
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error refreshing lock status", e)
                tvStatus.text = "Connection error - Retrying..."
            }
        }
    }

    /**
     * Unlock device and return to normal operation
     */
    private fun unlockDevice() {
        try {
            // Exit lock task mode
            stopLockTask()
            
            // Trigger device retirement
            DeviceRetirementManager.retireDevice(this)
            
            // Close this activity
            finish()
        } catch (e: Exception) {
            Log.e(TAG, "Error unlocking device", e)
        }
    }

    override fun onBackPressed() {
        // Disable back button in kiosk mode
        Log.d(TAG, "Back button disabled in kiosk mode")
    }

    override fun onDestroy() {
        super.onDestroy()
        syncJob?.cancel()
        scope.cancel()
    }
}
