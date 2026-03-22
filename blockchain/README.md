# Eden Custom Blockchain

A lightweight, purpose-built blockchain for Eden payment tracking.

## Features

- Simple REST API for payment submission
- Proof-of-work mining
- Transaction validation
- Balance tracking per wallet
- Supabase integration
- Persistent storage

## Quick Start

```bash
cd blockchain
pip install -r requirements.txt
python eden_blockchain.py  # Test blockchain
python eden_blockchain_server.py  # Start API server
```

## API Endpoints

- `POST /api/payment` - Submit payment
- `GET /api/balance/<wallet>` - Get balance
- `GET /api/chain` - Get full blockchain
- `GET /api/info` - Get blockchain info
