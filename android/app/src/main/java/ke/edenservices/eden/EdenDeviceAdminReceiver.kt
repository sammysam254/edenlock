package ke.edenservices.eden

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.PersistableBundle
import android.util.Log
import android.widget.Toast

/**
 * Eden Device Admin Receiver
 * Handles Device Owner provisioning and enforcement
 */
class EdenDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "EdenDeviceAdmin"
        const val EXTRA_SUPABASE_URL = "supabase_url"
        const val EXTRA_SUPABASE_KEY = "supabase_key"
        const val EXTRA_WALLET_ADDRESS = "wallet_address"
        
        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, EdenDeviceAdminReceiver::class.java)
        }
    }

    /**
     * Called when device provisioning is complete
     * This is where we apply all hardened restrictions
     */
    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        super.onProfileProvisioningComplete(context, intent)
        Log.i(TAG, "Profile provisioning complete - applying restrictions")

        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = getComponentName(context)

        // Extract admin extras from provisioning bundle
        val adminExtras: PersistableBundle? = intent.getParcelableExtra(
            DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE
        )

        if (adminExtras != null) {
            val supabaseUrl = adminExtras.getString(EXTRA_SUPABASE_URL)
            val supabaseKey = adminExtras.getString(EXTRA_SUPABASE_KEY)
            val walletAddress = adminExtras.getString(EXTRA_WALLET_ADDRESS)

            // Store credentials securely
            val prefs = context.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString(EXTRA_SUPABASE_URL, supabaseUrl)
                putString(EXTRA_SUPABASE_KEY, supabaseKey)
                putString(EXTRA_WALLET_ADDRESS, walletAddress)
                putBoolean("provisioned", true)
                apply()
            }

            Log.i(TAG, "Supabase credentials stored securely")
        } else {
            Log.e(TAG, "No admin extras found in provisioning bundle!")
        }

        // Apply hardened enforcement
        DeviceEnforcementManager.applyHardenedRestrictions(context, dpm, adminComponent)

        // Set this app as the lock task package (for kiosk mode)
        dpm.setLockTaskPackages(adminComponent, arrayOf(context.packageName))

        // Enable the app and launch main activity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(launchIntent)

        Toast.makeText(context, "Eden Device Protection Active", Toast.LENGTH_LONG).show()
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device Admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Device Admin disabled")
    }

    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
        Log.i(TAG, "Entering lock task mode for package: $pkg")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
        Log.i(TAG, "Exiting lock task mode")
    }
}
