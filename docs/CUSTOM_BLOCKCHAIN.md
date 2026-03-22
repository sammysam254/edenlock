# Eden Custom Blockchain Guide

Complete guide for the Eden custom blockchain system.

## Overview

Eden uses a lightweight, purpose-built blockchain specifically designed for payment tracking. This eliminates dependency on external networks like Polygon or BSC while maintaining security and transparency.

## Architecture

```
┌─────────────────────┐
│  Payment Submission │
│   (REST API)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Eden Blockchain    │
│  - Proof of Work    │
│  - Transaction Log  │
│  - Balance Tracking │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Blockchain Listener│
│  (Monitors Blocks)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Supabase Update   │
│  (Device Unlock)    │
└─────────────────────┘
```

## Components

### 1. Eden Blockchain Core (`eden_blockchain.py`)

**Features:**
- Simple block structure with transactions
- Proof-of-work mining (configurable difficulty)
- Transaction validation
- Balance tracking per wallet
- Chain validation
- Import/export to JSON

**Key Classes:**

```python
Transaction:
    - device_wallet: str
    - amount: float
    - timestamp: int
    - sender: str
    - transaction_id: str

Block:
    - index: int
    - timestamp: int
    - transactions: List[Transaction]
    - previous_hash: str
    - nonce: int
    - hash: str

EdenBlockchain:
    - chain: List[Block]
    - pending_transactions: List[Transaction]
    - difficulty: int
```

### 2. Blockchain Server (`eden_blockchain_server.py`)

**REST API Endpoints:**

#### POST /api/payment
Submit a new payment transaction

**Request:**
```json
{
  "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "amount": 1000.0,
  "sender": "user_123"
}
```

**Response:**
```json
{
  "success": true,
  "transaction_id": "abc123...",
  "device_wallet": "0x742d35...",
  "amount": 1000.0,
  "message": "Payment processed successfully"
}
```

#### GET /api/balance/<wallet_address>
Get total payments for a wallet

**Response:**
```json
{
  "success": true,
  "wallet_address": "0x742d35...",
  "total_paid": 1500.0,
  "transaction_count": 3,
  "transactions": [...]
}
```

#### GET /api/chain
Get entire blockchain

**Response:**
```json
{
  "success": true,
  "length": 5,
  "chain": [...]
}
```

#### GET /api/info
Get blockchain statistics

**Response:**
```json
{
  "success": true,
  "data": {
    "total_blocks": 5,
    "total_transactions": 12,
    "difficulty": 2,
    "is_valid": true,
    "latest_block_hash": "00abc..."
  }
}
```

#### GET /api/validate
Validate blockchain integrity

**Response:**
```json
{
  "success": true,
  "is_valid": true,
  "message": "Blockchain is valid"
}
```

### 3. Blockchain Listener (`eden_blockchain_listener.py`)

**Purpose:** Monitors blockchain for new blocks and updates Supabase

**Features:**
- Polls blockchain every 15 seconds
- Processes new blocks and transactions
- Updates device loan balances
- Logs all payments to Supabase
- Automatic retry on failures

## Deployment

### Local Development

```bash
# Terminal 1: Start blockchain server
cd blockchain
pip install -r requirements.txt
python eden_blockchain_server.py

# Terminal 2: Start listener
cd backend
pip install -r requirements.txt
python eden_blockchain_listener.py

# Terminal 3: Test
cd blockchain
python test_blockchain.py
```

### Production Deployment (Render)

#### Deploy Blockchain Server

1. Create new Web Service on Render
2. Connect GitHub repository
3. Configure:
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn eden_blockchain_server:app`
   - **Environment Variables:**
     - `PORT`: 5000
     - `SUPABASE_URL`: Your Supabase URL
     - `SUPABASE_SERVICE_KEY`: Service role key

4. Deploy

#### Deploy Listener

1. Create new Background Worker on Render
2. Connect GitHub repository
3. Configure:
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `python eden_blockchain_listener.py`
   - **Environment Variables:**
     - `BLOCKCHAIN_URL`: Your blockchain server URL
     - `SUPABASE_URL`: Your Supabase URL
     - `SUPABASE_SERVICE_KEY`: Service role key
     - `POLL_INTERVAL`: 15

4. Deploy

## Usage Examples

### Submit Payment (Python)

```python
import requests

blockchain_url = "https://your-blockchain.onrender.com"

payment = {
    "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "amount": 1000.0,
    "sender": "customer_123"
}

response = requests.post(f"{blockchain_url}/api/payment", json=payment)
print(response.json())
```

### Submit Payment (cURL)

```bash
curl -X POST https://your-blockchain.onrender.com/api/payment \
  -H "Content-Type: application/json" \
  -d '{
    "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "amount": 1000.0,
    "sender": "customer_123"
  }'
```

### Check Balance (Python)

```python
import requests

blockchain_url = "https://your-blockchain.onrender.com"
wallet = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"

response = requests.get(f"{blockchain_url}/api/balance/{wallet}")
data = response.json()

print(f"Total paid: {data['total_paid']}")
print(f"Transactions: {data['transaction_count']}")
```

### Android Integration

Update `SupabaseClient.kt` to also submit to blockchain:

```kotlin
suspend fun submitPayment(amount: Double): Boolean = withContext(Dispatchers.IO) {
    try {
        val blockchainUrl = "https://your-blockchain.onrender.com"
        val walletAddress = prefs.getString("wallet_address", null)
        
        val url = URL("$blockchainUrl/api/payment")
        val connection = url.openConnection() as HttpURLConnection
        
        val paymentData = JSONObject().apply {
            put("device_wallet", walletAddress)
            put("amount", amount)
            put("sender", "device_payment")
        }
        
        connection.apply {
            requestMethod = "POST"
            setRequestProperty("Content-Type", "application/json")
            doOutput = true
        }
        
        OutputStreamWriter(connection.outputStream).use {
            it.write(paymentData.toString())
            it.flush()
        }
        
        val responseCode = connection.responseCode
        connection.disconnect()
        
        return@withContext responseCode == HttpURLConnection.HTTP_OK
    } catch (e: Exception) {
        Log.e(TAG, "Error submitting payment", e)
        return@withContext false
    }
}
```

## Security

### Blockchain Security

1. **Proof of Work:** Prevents tampering with historical blocks
2. **Chain Validation:** Ensures integrity of entire chain
3. **Hash Verification:** Each block hash depends on previous block
4. **Immutability:** Once mined, blocks cannot be altered

### API Security

1. **HTTPS Only:** All communication encrypted
2. **Rate Limiting:** Prevent spam (implement in production)
3. **Input Validation:** Validate all payment data
4. **Authentication:** Optional API key authentication

### Recommended Enhancements

```python
# Add API key authentication
@app.before_request
def check_api_key():
    if request.endpoint != 'health_check':
        api_key = request.headers.get('X-API-Key')
        if api_key != os.getenv('API_KEY'):
            return jsonify({'error': 'Unauthorized'}), 401
```

## Monitoring

### Health Check

```bash
curl https://your-blockchain.onrender.com/health
```

**Response:**
```json
{
  "status": "healthy",
  "blockchain_blocks": 42,
  "blockchain_valid": true,
  "supabase_connected": true
}
```

### Logs

**Blockchain Server:**
- Check Render dashboard logs
- Look for "Payment processed" messages
- Monitor mining activity

**Listener:**
- Check Render dashboard logs
- Look for "Payment detected" messages
- Monitor Supabase updates

## Backup & Recovery

### Export Blockchain

```python
from eden_blockchain import EdenBlockchain

blockchain = EdenBlockchain()
blockchain.import_chain('eden_blockchain.json')
blockchain.export_chain('backup_blockchain.json')
```

### Restore Blockchain

```python
from eden_blockchain import EdenBlockchain

blockchain = EdenBlockchain()
blockchain.import_chain('backup_blockchain.json')

# Verify integrity
if blockchain.is_chain_valid():
    print("Blockchain restored successfully")
```

### Automated Backups

Add to `eden_blockchain_server.py`:

```python
import schedule

def backup_blockchain():
    blockchain.export_chain(f'backups/blockchain_{int(time.time())}.json')
    logger.info("Blockchain backed up")

# Backup every hour
schedule.every().hour.do(backup_blockchain)
```

## Performance

### Benchmarks

- **Transaction Processing:** < 1 second
- **Block Mining:** 2-5 seconds (difficulty=2)
- **Balance Query:** < 100ms
- **Chain Validation:** < 1 second (100 blocks)

### Optimization Tips

1. **Adjust Difficulty:** Lower for faster mining
2. **Batch Transactions:** Mine multiple transactions per block
3. **Database Indexing:** Index wallet_address in Supabase
4. **Caching:** Cache frequently accessed balances

## Troubleshooting

### Issue: Blockchain server not starting

**Solution:**
```bash
# Check port availability
lsof -i :5000

# Check logs
tail -f eden_blockchain_server.log
```

### Issue: Listener not detecting payments

**Solution:**
```bash
# Verify blockchain URL
curl https://your-blockchain.onrender.com/api/info

# Check listener logs
tail -f eden_blockchain_listener.log

# Verify Supabase credentials
```

### Issue: Chain validation fails

**Solution:**
```python
# Re-import from backup
blockchain.import_chain('backup_blockchain.json')

# Or start fresh
blockchain = EdenBlockchain()
```

## Comparison: Custom vs External Blockchain

| Feature | Eden Custom | Polygon/BSC |
|---------|-------------|-------------|
| Setup Complexity | Low | High |
| Transaction Cost | Free | Gas fees |
| Transaction Speed | Instant | 2-30 seconds |
| Scalability | Medium | High |
| Decentralization | Centralized | Decentralized |
| Maintenance | Self-hosted | Network-managed |
| Best For | Eden-specific | General purpose |

## Migration from Web3

If you want to switch from external blockchain to custom:

1. Deploy Eden blockchain server
2. Update backend `.env`:
   ```bash
   BLOCKCHAIN_URL=https://your-blockchain.onrender.com
   ```
3. Use `eden_blockchain_listener.py` instead of `web3_listener.py`
4. Update payment submission to use REST API

## Conclusion

The Eden custom blockchain provides a simple, cost-effective solution for payment tracking without external dependencies. It's perfect for Eden's specific use case while maintaining security and transparency.

For production use, consider:
- Adding API authentication
- Implementing rate limiting
- Setting up automated backups
- Monitoring blockchain health
- Scaling horizontally if needed
