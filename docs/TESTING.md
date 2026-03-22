# Eden Testing Guide

Comprehensive testing procedures for the Eden system.

## Testing Environment Setup

### Prerequisites
- Android device (Android 9.0+) or emulator
- ADB installed and configured
- Test blockchain network (Polygon Mumbai or BSC Testnet)
- Test Supabase project
- Test smart contract deployed

### Test Environment Configuration

```bash
# Backend .env for testing
RPC_URL=https://rpc-mumbai.maticvigil.com
CONTRACT_ADDRESS=0xYourTestContractAddress
CHAIN_ID=80001
SUPABASE_URL=https://test-project.supabase.co
SUPABASE_SERVICE_KEY=test_service_key
POLL_INTERVAL=5  # Faster polling for testing
```

## Unit Testing

### Android Unit Tests

Create test files in `android/app/src/test/`:

```kotlin
// DeviceEnforcementManagerTest.kt
class DeviceEnforcementManagerTest {
    
    @Test
    fun testRestrictionsApplied() {
        val context = mockContext()
        val dpm = mockDevicePolicyManager()
        val component = mockComponentName()
        
        DeviceEnforcementManager.applyHardenedRestrictions(context, dpm, component)
        
        verify(dpm).addUserRestriction(component, UserManager.DISALLOW_FACTORY_RESET)
        verify(dpm).addUserRestriction(component, UserManager.DISALLOW_SAFE_BOOT)
        verify(dpm).addUserRestriction(component, UserManager.DISALLOW_DEBUGGING_FEATURES)
    }
}
```

Run tests:
```bash
cd android
./gradlew test
```

### Backend Unit Tests

Create `backend/test_listener.py`:

```python
import unittest
from web3_listener import EdenWeb3Listener

class TestEdenListener(unittest.TestCase):
    
    def test_connection(self):
        listener = EdenWeb3Listener()
        self.assertTrue(listener.test_connection())
    
    def test_payment_processing(self):
        listener = EdenWeb3Listener()
        event = {
            'args': {
                'wallet': '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
                'amount': 100000000000000000,  # 0.1 ETH
                'timestamp': 1234567890
            }
        }
        result = listener.process_payment_event(event)
        self.assertTrue(result)

if __name__ == '__main__':
    unittest.main()
```

Run tests:
```bash
cd backend
python -m pytest test_listener.py
```

## Integration Testing

### Test 1: Device Provisioning

**Objective:** Verify QR code provisioning works correctly

**Steps:**
1. Factory reset test device
2. Generate test QR code with test credentials
3. Tap welcome screen 6 times
4. Scan QR code
5. Wait for provisioning to complete

**Expected Results:**
- ✅ Device connects to WiFi
- ✅ APK downloads successfully
- ✅ Checksum verification passes
- ✅ Eden installs as Device Owner
- ✅ MainActivity launches
- ✅ Status shows "Device Protection Active"

**Verification:**
```bash
# Check Device Owner status
adb shell dpm list-owners
# Should show: ke.edenservices.eden/.EdenDeviceAdminReceiver

# Check restrictions
adb shell dumpsys device_policy
# Should show DISALLOW_FACTORY_RESET, etc.
```

### Test 2: Database Registration

**Objective:** Verify device registers in Supabase

**Steps:**
1. Provision device
2. Check Supabase devices table

**Expected Results:**
```sql
SELECT * FROM devices WHERE imei = 'test_device_id';
-- Should return device record with:
-- - imei: test_device_id
-- - wallet_address: 0x...
-- - loan_total: configured amount
-- - loan_balance: configured amount
-- - is_locked: true
```

### Test 3: Lock Enforcement

**Objective:** Verify device locks when is_locked = true

**Steps:**
1. Update device in Supabase:
```sql
UPDATE devices 
SET is_locked = true, loan_balance = 5000.00 
WHERE imei = 'test_device_id';
```

2. Wait for WorkManager sync (15 minutes) or restart app

**Expected Results:**
- ✅ LockoutActivity launches
- ✅ Kiosk mode activates (can't exit app)
- ✅ Payment information displayed
- ✅ Back button disabled
- ✅ Home button disabled
- ✅ Recent apps disabled

**Verification:**
```bash
# Check current activity
adb shell dumpsys activity activities | grep mResumedActivity
# Should show: LockoutActivity

# Try to exit (should fail)
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_BACK
```

### Test 4: Payment Detection

**Objective:** Verify backend detects blockchain payments

**Steps:**
1. Deploy test smart contract
2. Start backend listener
3. Send test payment:
```javascript
const tx = await contract.makePayment(
  "0xDeviceWalletAddress",
  { value: ethers.utils.parseEther("0.1") }
);
await tx.wait();
```

4. Check backend logs

**Expected Results:**
- ✅ Backend logs: "Payment detected: 0x... paid 0.1"
- ✅ Supabase updated:
```sql
SELECT * FROM devices WHERE wallet_address = '0x...';
-- loan_balance should be reduced by payment amount
```
- ✅ Transaction logged:
```sql
SELECT * FROM payment_transactions WHERE wallet_address = '0x...';
-- Should show new transaction record
```

### Test 5: Device Unlock

**Objective:** Verify device unlocks when loan paid

**Steps:**
1. Set loan_balance to small amount:
```sql
UPDATE devices 
SET loan_balance = 0.01 
WHERE imei = 'test_device_id';
```

2. Send payment to cover remaining balance
3. Wait for backend to process
4. Wait for device to sync

**Expected Results:**
- ✅ Supabase shows loan_balance = 0
- ✅ Supabase shows is_locked = false
- ✅ Device exits kiosk mode
- ✅ DeviceRetirementManager.retireDevice() called
- ✅ Restrictions removed
- ✅ Device Owner cleared
- ✅ Uninstall prompt appears

**Verification:**
```bash
# Check Device Owner status (should be empty)
adb shell dpm list-owners

# Check restrictions (should be cleared)
adb shell dumpsys device_policy
```

### Test 6: Boot Persistence

**Objective:** Verify lock persists across reboots

**Steps:**
1. Lock device (is_locked = true)
2. Reboot device:
```bash
adb reboot
```
3. Wait for boot to complete

**Expected Results:**
- ✅ BootReceiver triggers
- ✅ LockoutActivity launches automatically
- ✅ Kiosk mode re-enabled
- ✅ Device remains locked

### Test 7: Network Resilience

**Objective:** Verify system handles network failures

**Steps:**
1. Enable airplane mode
2. Try to sync status
3. Disable airplane mode
4. Verify sync resumes

**Expected Results:**
- ✅ WorkManager retries on failure
- ✅ No crashes or data loss
- ✅ Sync resumes when network available
- ✅ Exponential backoff applied

## Security Testing

### Test 8: Factory Reset Prevention

**Objective:** Verify factory reset is blocked

**Steps:**
1. Provision device as Device Owner
2. Attempt factory reset via Settings
3. Attempt factory reset via recovery mode

**Expected Results:**
- ✅ Settings > Reset option is disabled/hidden
- ✅ Recovery mode factory reset fails
- ✅ Device remains locked

### Test 9: Safe Boot Prevention

**Objective:** Verify safe mode is blocked

**Steps:**
1. Provision device
2. Attempt to boot into safe mode:
   - Power off device
   - Power on and hold Volume Down

**Expected Results:**
- ✅ Safe mode boot fails
- ✅ Device boots normally
- ✅ Eden app still active

### Test 10: ADB Access Prevention

**Objective:** Verify ADB is disabled

**Steps:**
1. Provision device
2. Attempt to enable Developer Options:
   - Settings > About Phone
   - Tap Build Number 7 times

**Expected Results:**
- ✅ Developer Options do not appear
- ✅ ADB debugging cannot be enabled
- ✅ USB debugging blocked

### Test 11: Uninstall Prevention

**Objective:** Verify app cannot be uninstalled

**Steps:**
1. Provision device
2. Attempt to uninstall via Settings
3. Attempt to uninstall via ADB:
```bash
adb uninstall ke.edenservices.eden
```

**Expected Results:**
- ✅ Uninstall option disabled in Settings
- ✅ ADB uninstall fails with error
- ✅ App remains installed

### Test 12: Kiosk Mode Bypass Attempts

**Objective:** Verify kiosk mode cannot be bypassed

**Steps:**
1. Lock device (LockoutActivity active)
2. Attempt various bypass methods:
   - Press Home button
   - Press Back button
   - Press Recent Apps button
   - Swipe from edges
   - Use accessibility services
   - Connect external keyboard

**Expected Results:**
- ✅ All bypass attempts fail
- ✅ User remains in LockoutActivity
- ✅ No way to exit payment screen

## Performance Testing

### Test 13: Battery Impact

**Objective:** Measure battery consumption

**Steps:**
1. Fully charge device
2. Run Eden for 24 hours
3. Monitor battery usage

**Expected Results:**
- ✅ Battery drain < 5% per day
- ✅ WorkManager uses minimal resources
- ✅ No wakelocks or excessive CPU usage

**Verification:**
```bash
adb shell dumpsys batterystats | grep eden
```

### Test 14: Network Usage

**Objective:** Measure data consumption

**Steps:**
1. Reset network stats
2. Run Eden for 24 hours
3. Check data usage

**Expected Results:**
- ✅ Data usage < 10 MB per day
- ✅ Efficient API calls
- ✅ No unnecessary polling

**Verification:**
```bash
adb shell dumpsys netstats | grep eden
```

### Test 15: Backend Performance

**Objective:** Measure backend processing speed

**Steps:**
1. Send 100 test payments
2. Measure processing time
3. Check database update latency

**Expected Results:**
- ✅ Event detection < 30 seconds
- ✅ Database update < 5 seconds
- ✅ No missed events
- ✅ No duplicate processing

## Stress Testing

### Test 16: Concurrent Payments

**Objective:** Test multiple simultaneous payments

**Steps:**
1. Send 10 payments to different devices simultaneously
2. Verify all are processed correctly

**Expected Results:**
- ✅ All payments detected
- ✅ All devices updated correctly
- ✅ No race conditions
- ✅ No data corruption

### Test 17: High-Frequency Sync

**Objective:** Test rapid sync requests

**Steps:**
1. Set POLL_INTERVAL to 1 second
2. Run for 1 hour
3. Monitor for errors

**Expected Results:**
- ✅ No crashes
- ✅ No memory leaks
- ✅ Consistent performance
- ✅ Proper rate limiting

### Test 18: Database Load

**Objective:** Test with many devices

**Steps:**
1. Insert 1000 device records
2. Send payments to random devices
3. Verify query performance

**Expected Results:**
- ✅ Queries remain fast (< 100ms)
- ✅ Indexes used effectively
- ✅ No database timeouts

## User Acceptance Testing

### Test 19: End-to-End User Flow

**Scenario:** New device provisioning to loan completion

**Steps:**
1. Factory reset device
2. Scan QR code
3. Device provisions automatically
4. Device locks (loan active)
5. User makes payment
6. Device unlocks
7. Device retires

**Expected Results:**
- ✅ Smooth provisioning experience
- ✅ Clear payment instructions
- ✅ Automatic unlock after payment
- ✅ Clean device retirement

### Test 20: Error Handling

**Objective:** Verify user-friendly error messages

**Steps:**
1. Test with invalid Supabase credentials
2. Test with no network connection
3. Test with invalid wallet address

**Expected Results:**
- ✅ Clear error messages
- ✅ No crashes
- ✅ Graceful degradation
- ✅ Retry mechanisms work

## Regression Testing

### Test 21: Android Version Compatibility

**Objective:** Test on multiple Android versions

**Devices to Test:**
- Android 9.0 (API 28)
- Android 10.0 (API 29)
- Android 11.0 (API 30)
- Android 12.0 (API 31)
- Android 13.0 (API 33)
- Android 14.0 (API 34)

**Expected Results:**
- ✅ Works on all supported versions
- ✅ No version-specific bugs
- ✅ Consistent behavior

### Test 22: Device Manufacturer Compatibility

**Objective:** Test on different manufacturers

**Devices to Test:**
- Samsung
- Xiaomi
- Oppo
- Tecno
- Infinix

**Expected Results:**
- ✅ Works on all manufacturers
- ✅ No OEM-specific issues
- ✅ Provisioning works consistently

## Test Automation

### Automated Test Suite

Create `android/app/src/androidTest/`:

```kotlin
@RunWith(AndroidJUnit4::class)
class EdenInstrumentedTest {
    
    @Test
    fun testDeviceOwnerStatus() {
        val dpm = InstrumentationRegistry.getInstrumentation()
            .targetContext
            .getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        
        assertTrue(dpm.isDeviceOwnerApp("ke.edenservices.eden"))
    }
    
    @Test
    fun testRestrictionsApplied() {
        val dpm = InstrumentationRegistry.getInstrumentation()
            .targetContext
            .getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        
        val component = ComponentName(
            "ke.edenservices.eden",
            "ke.edenservices.eden.EdenDeviceAdminReceiver"
        )
        
        val restrictions = dpm.getUserRestrictions(component)
        assertTrue(restrictions.getBoolean(UserManager.DISALLOW_FACTORY_RESET))
        assertTrue(restrictions.getBoolean(UserManager.DISALLOW_SAFE_BOOT))
    }
}
```

Run automated tests:
```bash
./gradlew connectedAndroidTest
```

## Test Reporting

### Test Report Template

```markdown
# Eden Test Report

**Date:** YYYY-MM-DD
**Tester:** Name
**Environment:** Test/Staging/Production

## Test Summary
- Total Tests: X
- Passed: X
- Failed: X
- Skipped: X

## Failed Tests
1. Test Name
   - Expected: ...
   - Actual: ...
   - Root Cause: ...
   - Fix: ...

## Performance Metrics
- Average payment detection time: X seconds
- Average sync time: X seconds
- Battery usage: X% per day
- Data usage: X MB per day

## Recommendations
- ...
```

## Continuous Testing

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Eden Tests

on: [push, pull_request]

jobs:
  android-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up JDK
        uses: actions/setup-java@v2
        with:
          java-version: '17'
      - name: Run tests
        run: |
          cd android
          ./gradlew test
  
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install pytest
      - name: Run tests
        run: |
          cd backend
          pytest
```

## Conclusion

This comprehensive testing guide covers all aspects of the Eden system. Follow these tests before each release to ensure quality and reliability.

**Testing Checklist:**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All security tests pass
- [ ] Performance metrics acceptable
- [ ] User acceptance criteria met
- [ ] Regression tests pass
- [ ] Documentation updated
