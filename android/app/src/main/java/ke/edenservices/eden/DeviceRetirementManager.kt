package ke.edenservices.eden

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.UserManager
import android.util.Log

/**
 * Handles device retirement when loan is fully paid
 */
object DeviceRetirementManager {

    private const val TAG = "DeviceRetirement"

    /**
     * Retire device - remove all restrictions and uninstall Eden
     * Called when loan_balance reaches 0
     */
    fun retireDevice(context: Context) {
        Log.i(TAG, "Starting device retirement process...")

        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = EdenDeviceAdminReceiver.getComponentName(context)

        if (!dpm.isDeviceOwnerApp(context.packageName)) {
            Log.e(TAG, "Cannot retire - not Device Owner")
            return
        }

        try {
            // Step 1: Exit lock task mode if active
            exitLockTaskMode(context)

            // Step 2: Remove all user restrictions
            removeAllRestrictions(dpm, adminComponent)

            // Step 3: Clear Device Owner status
            clearDeviceOwner(dpm, adminComponent)

            // Step 4: Mark as retired in preferences
            markAsRetired(context)

            // Step 5: Trigger self-uninstallation
            triggerUninstall(context)

            Log.i(TAG, "✓ Device retirement complete")

        } catch (e: Exception) {
            Log.e(TAG, "Error during device retirement", e)
        }
    }

    /**
     * Exit lock task mode
     */
    private fun exitLockTaskMode(context: Context) {
        try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = EdenDeviceAdminReceiver.getComponentName(context)
            
            // Clear lock task packages
            dpm.setLockTaskPackages(adminComponent, arrayOf())
            Log.i(TAG, "✓ Lock task mode cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Error exiting lock task mode", e)
        }
    }

    /**
     * Remove all user restrictions
     */
    private fun removeAllRestrictions(dpm: DevicePolicyManager, adminComponent: ComponentName) {
        val restrictions = listOf(
            UserManager.DISALLOW_FACTORY_RESET,
            UserManager.DISALLOW_SAFE_BOOT,
            UserManager.DISALLOW_DEBUGGING_FEATURES,
            UserManager.DISALLOW_ADD_USER,
            UserManager.DISALLOW_REMOVE_USER,
            UserManager.DISALLOW_INSTALL_APPS,
            UserManager.DISALLOW_UNINSTALL_APPS,
            UserManager.DISALLOW_CONFIG_CREDENTIALS,
            UserManager.DISALLOW_MODIFY_ACCOUNTS
        )

        restrictions.forEach { restriction ->
            try {
                dpm.clearUserRestriction(adminComponent, restriction)
                Log.i(TAG, "✓ Removed restriction: $restriction")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to remove restriction: $restriction", e)
            }
        }
    }

    /**
     * Clear Device Owner status
     */
    private fun clearDeviceOwner(dpm: DevicePolicyManager, adminComponent: ComponentName) {
        try {
            // Enable uninstallation first
            dpm.setUninstallBlocked(adminComponent, adminComponent.packageName, false)
            
            // Clear device owner
            dpm.clearDeviceOwnerApp(adminComponent.packageName)
            Log.i(TAG, "✓ Device Owner cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear Device Owner", e)
        }
    }

    /**
     * Mark device as retired in SharedPreferences
     */
    private fun markAsRetired(context: Context) {
        val prefs = context.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putBoolean("retired", true)
            putLong("retirement_timestamp", System.currentTimeMillis())
            apply()
        }
        Log.i(TAG, "✓ Device marked as retired")
    }

    /**
     * Trigger self-uninstallation
     */
    private fun triggerUninstall(context: Context) {
        try {
            val packageUri = Uri.parse("package:${context.packageName}")
            val uninstallIntent = Intent(Intent.ACTION_DELETE, packageUri).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(uninstallIntent)
            Log.i(TAG, "✓ Uninstall triggered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to trigger uninstall", e)
        }
    }

    /**
     * Check if device has been retired
     */
    fun isRetired(context: Context): Boolean {
        val prefs = context.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
        return prefs.getBoolean("retired", false)
    }
}
