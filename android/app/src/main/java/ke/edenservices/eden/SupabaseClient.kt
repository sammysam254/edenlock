package ke.edenservices.eden

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/**
 * Supabase REST API Client
 */
class SupabaseClient private constructor(private val context: Context) {

    private val TAG = "SupabaseClient"
    private val prefs = context.getSharedPreferences("eden_secure", Context.MODE_PRIVATE)
    
    private val supabaseUrl: String? = prefs.getString(EdenDeviceAdminReceiver.EXTRA_SUPABASE_URL, null)
    private val supabaseKey: String? = prefs.getString(EdenDeviceAdminReceiver.EXTRA_SUPABASE_KEY, null)
    private val deviceImei: String = getDeviceIdentifier()

    companion object {
        @Volatile
        private var instance: SupabaseClient? = null

        fun getInstance(context: Context): SupabaseClient {
            return instance ?: synchronized(this) {
                instance ?: SupabaseClient(context.applicationContext).also { instance = it }
            }
        }
    }

    /**
     * Get device identifier (IMEI or Android ID)
     */
    private fun getDeviceIdentifier(): String {
        return try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get device ID", e)
            "UNKNOWN_DEVICE"
        }
    }

    /**
     * Fetch device status from Supabase
     */
    suspend fun getDeviceStatus(): JSONObject? = withContext(Dispatchers.IO) {
        if (supabaseUrl == null || supabaseKey == null) {
            Log.e(TAG, "Supabase credentials not configured")
            return@withContext null
        }

        try {
            val url = URL("$supabaseUrl/rest/v1/devices?imei=eq.$deviceImei&select=*")
            val connection = url.openConnection() as HttpURLConnection

            connection.apply {
                requestMethod = "GET"
                setRequestProperty("apikey", supabaseKey)
                setRequestProperty("Authorization", "Bearer $supabaseKey")
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 10000
                readTimeout = 10000
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = BufferedReader(InputStreamReader(connection.inputStream)).use {
                    it.readText()
                }

                val jsonArray = org.json.JSONArray(response)
                if (jsonArray.length() > 0) {
                    val deviceData = jsonArray.getJSONObject(0)
                    Log.i(TAG, "Device status fetched successfully")
                    return@withContext deviceData
                } else {
                    Log.w(TAG, "No device found with IMEI: $deviceImei")
                }
            } else {
                Log.e(TAG, "HTTP Error: $responseCode")
            }

            connection.disconnect()
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching device status", e)
        }

        return@withContext null
    }

    /**
     * Register device in Supabase (first-time setup)
     */
    suspend fun registerDevice(walletAddress: String, loanTotal: Double): Boolean = withContext(Dispatchers.IO) {
        if (supabaseUrl == null || supabaseKey == null) {
            Log.e(TAG, "Supabase credentials not configured")
            return@withContext false
        }

        try {
            val url = URL("$supabaseUrl/rest/v1/devices")
            val connection = url.openConnection() as HttpURLConnection

            val deviceData = JSONObject().apply {
                put("imei", deviceImei)
                put("wallet_address", walletAddress)
                put("loan_total", loanTotal)
                put("loan_balance", loanTotal)
                put("is_locked", true)
                put("device_model", Build.MODEL)
                put("android_version", Build.VERSION.RELEASE)
            }

            connection.apply {
                requestMethod = "POST"
                setRequestProperty("apikey", supabaseKey)
                setRequestProperty("Authorization", "Bearer $supabaseKey)
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Prefer", "return=representation")
                doOutput = true
            }

            OutputStreamWriter(connection.outputStream).use {
                it.write(deviceData.toString())
                it.flush()
            }

            val responseCode = connection.responseCode
            connection.disconnect()

            if (responseCode == HttpURLConnection.HTTP_CREATED) {
                Log.i(TAG, "Device registered successfully")
                return@withContext true
            } else {
                Log.e(TAG, "Failed to register device: $responseCode")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error registering device", e)
        }

        return@withContext false
    }
}
