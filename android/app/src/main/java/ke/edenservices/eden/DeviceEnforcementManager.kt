package ke.edenservices.eden

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.UserManager
import android.util.Log

/**
 * Manages hardened device restrictions and enforcement policies
 */
object DeviceEnforcementManager {

    private const val TAG = "DeviceEnforcement"

    /**
     * Apply all hardened restrictions to prevent bypass attempts
     */
    fun applyHardenedRestrictions(
        context: Context,
        dpm: DevicePolicyManager,
        adminComponent: ComponentName
    ) {
        try {
            // Critical: Disable factory reset
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_FACTORY_RESET)
            Log.i(TAG, "✓ Factory reset disabled")

            // Critical: Disable safe boot
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_SAFE_BOOT)
            Log.i(TAG, "✓ Safe boot disabled")

            // Critical: Disable debugging features (ADB, Developer Options)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_DEBUGGING_FEATURES)
            Log.i(TAG, "✓ Debugging features disabled")

            // Prevent app uninstallation
            dpm.setUninstallBlocked(adminComponent, context.packageName, true)
            Log.i(TAG, "✓ Uninstall blocked for Eden app")

            // Additional security restrictions
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_ADD_USER)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_REMOVE_USER)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_INSTALL_APPS)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_UNINSTALL_APPS)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_CONFIG_CREDENTIALS)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_MODIFY_ACCOUNTS)
            
            Log.i(TAG, "✓ All hardened restrictions applied successfully")

        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to apply restrictions - not Device Owner?", e)
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error applying restrictions", e)
        }
    }

    /**
     * Check if device is properly locked down
     */
    fun verifyEnforcement(context: Context): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = EdenDeviceAdminReceiver.getComponentName(context)

        if (!dpm.isDeviceOwnerApp(context.packageName)) {
            Log.e(TAG, "App is not Device Owner!")
            return false
        }

        val restrictions = listOf(
            UserManager.DISALLOW_FACTORY_RESET,
            UserManager.DISALLOW_SAFE_BOOT,
            UserManager.DISALLOW_DEBUGGING_FEATURES
        )

        val allApplied = restrictions.all { restriction ->
            dpm.getUserRestrictions(adminComponent).getBoolean(restriction, false)
        }

        Log.i(TAG, "Enforcement verification: ${if (allApplied) "PASS" else "FAIL"}")
        return allApplied
    }

    /**
     * Enter kiosk lock mode
     */
    fun enterLockMode(context: Context) {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = EdenDeviceAdminReceiver.getComponentName(context)

        // Ensure lock task packages are set
        dpm.setLockTaskPackages(adminComponent, arrayOf(context.packageName))
        Log.i(TAG, "Lock task mode enabled")
    }
}
