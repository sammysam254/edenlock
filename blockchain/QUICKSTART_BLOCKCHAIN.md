# Eden Blockchain Quick Start

Get the Eden custom blockchain running in 10 minutes.

## Step 1: Install Dependencies (1 minute)

```bash
cd blockchain
pip install -r requirements.txt
```

## Step 2: Test Blockchain Core (2 minutes)

```bash
# Run demo
python eden_blockchain.py
```

You should see:
- Genesis block created
- Transactions added
- Blocks mined
- Balances calculated
- Blockchain validated ✓

## Step 3: Start Blockchain Server (2 minutes)

```bash
# Create .env file
cp .env.example .env

# Edit .env (optional - Supabase integration)
nano .env

# Start server
python eden_blockchain_server.py
```

Server runs on http://localhost:5000

## Step 4: Test API (2 minutes)

```bash
# In new terminal
python test_blockchain.py
```

Or use cURL:

```bash
# Submit payment
curl -X POST http://localhost:5000/api/payment \
  -H "Content-Type: application/json" \
  -d '{
    "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "amount": 1000.0
  }'

# Check balance
curl http://localhost:5000/api/balance/0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb

# Get blockchain info
curl http://localhost:5000/api/info
```

## Step 5: Start Listener (3 minutes)

```bash
# In new terminal
cd ../backend

# Create .env
cp .env.example .env

# Edit .env
nano .env
# Set: BLOCKCHAIN_URL=http://localhost:5000

# Start listener
python eden_blockchain_listener.py
```

## Test Complete Flow

```bash
# Submit payment
curl -X POST http://localhost:5000/api/payment \
  -H "Content-Type: application/json" \
  -d '{
    "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "amount": 500.0
  }'

# Check listener logs
# Should see: "Payment detected: 0x742d35... paid 500.0"

# Check Supabase
# Device loan_balance should be reduced
```

## Production Deployment

### Deploy to Render

1. Push code to GitHub
2. Create Web Service for blockchain server
3. Create Background Worker for listener
4. Set environment variables
5. Deploy!

See `docs/CUSTOM_BLOCKCHAIN.md` for detailed deployment guide.

## API Endpoints

- `POST /api/payment` - Submit payment
- `GET /api/balance/<wallet>` - Get balance
- `GET /api/transactions/<wallet>` - Get transactions
- `GET /api/chain` - Get full blockchain
- `GET /api/info` - Get blockchain info
- `GET /api/validate` - Validate chain
- `GET /health` - Health check

## Next Steps

1. Read `docs/CUSTOM_BLOCKCHAIN.md` for full documentation
2. Deploy to production (Render)
3. Integrate with Android app
4. Set up monitoring

## Troubleshooting

**Port already in use:**
```bash
# Change port in .env
PORT=5001
```

**Supabase not updating:**
- Check SUPABASE_SERVICE_KEY (not anon key)
- Verify device exists with matching wallet_address
- Check listener logs

**Blockchain validation fails:**
```bash
# Delete and restart
rm eden_blockchain.json
python eden_blockchain_server.py
```

Done! Your Eden blockchain is running. 🎉
