#!/usr/bin/env python3
"""
Eden Blockchain Server - REST API for Eden Blockchain
Provides HTTP endpoints for payment submission and verification
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sys
import logging
from typing import Optional
from supabase import create_client, Client
from dotenv import load_dotenv
from eden_blockchain import EdenBlockchain, Transaction

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('EdenBlockchainServer')

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Initialize blockchain
blockchain = EdenBlockchain(difficulty=2)

# Initialize Supabase
supabase_url = os.getenv('SUPABASE_URL')
supabase_key = os.getenv('SUPABASE_SERVICE_KEY')
supabase: Optional[Client] = None

if supabase_url and supabase_key:
    supabase = create_client(supabase_url, supabase_key)
    logger.info("Supabase client initialized")
else:
    logger.warning("Supabase credentials not found - running without database sync")

# Load existing blockchain if available
BLOCKCHAIN_FILE = 'eden_blockchain.json'
if os.path.exists(BLOCKCHAIN_FILE):
    blockchain.import_chain(BLOCKCHAIN_FILE)
    logger.info(f"Blockchain loaded from {BLOCKCHAIN_FILE}")


@app.route('/api/info', methods=['GET'])
def get_info():
    """Get blockchain information"""
    return jsonify({
        'success': True,
        'data': blockchain.get_chain_info()
    })


@app.route('/api/chain', methods=['GET'])
def get_chain():
    """Get entire blockchain"""
    chain_data = [block.to_dict() for block in blockchain.chain]
    return jsonify({
        'success': True,
        'length': len(chain_data),
        'chain': chain_data
    })


@app.route('/api/payment', methods=['POST'])
def submit_payment():
    """Submit a new payment transaction"""
    try:
        data = request.get_json()
        
        # Validate input
        if not data or 'device_wallet' not in data or 'amount' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing required fields: device_wallet, amount'
            }), 400
        
        device_wallet = data['device_wallet']
        amount = float(data['amount'])
        sender = data.get('sender', 'eden_system')
        
        if amount <= 0:
            return jsonify({
                'success': False,
                'error': 'Amount must be greater than 0'
            }), 400
        
        # Add transaction to blockchain
        tx_id = blockchain.add_transaction(device_wallet, amount, sender)
        
        # Mine the transaction immediately (for simplicity)
        blockchain.mine_pending_transactions()
        
        # Save blockchain
        blockchain.export_chain(BLOCKCHAIN_FILE)
        
        # Update Supabase if available
        if supabase:
            update_supabase_balance(device_wallet, amount)
        
        logger.info(f"Payment processed: {device_wallet} paid {amount}")
        
        return jsonify({
            'success': True,
            'transaction_id': tx_id,
            'device_wallet': device_wallet,
            'amount': amount,
            'message': 'Payment processed successfully'
        })
    
    except Exception as e:
        logger.error(f"Error processing payment: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/balance/<wallet_address>', methods=['GET'])
def get_balance(wallet_address: str):
    """Get total payments for a wallet address"""
    try:
        balance = blockchain.get_balance(wallet_address)
        transactions = blockchain.get_transactions_for_wallet(wallet_address)
        
        return jsonify({
            'success': True,
            'wallet_address': wallet_address,
            'total_paid': balance,
            'transaction_count': len(transactions),
            'transactions': [tx.to_dict() for tx in transactions]
        })
    
    except Exception as e:
        logger.error(f"Error getting balance: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/transactions/<wallet_address>', methods=['GET'])
def get_transactions(wallet_address: str):
    """Get all transactions for a wallet"""
    try:
        transactions = blockchain.get_transactions_for_wallet(wallet_address)
        
        return jsonify({
            'success': True,
            'wallet_address': wallet_address,
            'transaction_count': len(transactions),
            'transactions': [tx.to_dict() for tx in transactions]
        })
    
    except Exception as e:
        logger.error(f"Error getting transactions: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/validate', methods=['GET'])
def validate_chain():
    """Validate blockchain integrity"""
    is_valid = blockchain.is_chain_valid()
    return jsonify({
        'success': True,
        'is_valid': is_valid,
        'message': 'Blockchain is valid' if is_valid else 'Blockchain is invalid'
    })


@app.route('/api/mine', methods=['POST'])
def mine_pending():
    """Mine pending transactions (if any)"""
    try:
        if not blockchain.pending_transactions:
            return jsonify({
                'success': False,
                'message': 'No pending transactions to mine'
            })
        
        blockchain.mine_pending_transactions()
        blockchain.export_chain(BLOCKCHAIN_FILE)
        
        return jsonify({
            'success': True,
            'message': 'Pending transactions mined',
            'latest_block': blockchain.get_latest_block().to_dict()
        })
    
    except Exception as e:
        logger.error(f"Error mining: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


def update_supabase_balance(device_wallet: str, payment_amount: float):
    """Update device balance in Supabase"""
    try:
        if not supabase:
            return
        
        # Get device by wallet address
        response = supabase.table('devices').select('*').eq(
            'wallet_address', device_wallet
        ).execute()
        
        if not response.data:
            logger.warning(f"No device found for wallet: {device_wallet}")
            return
        
        device = response.data[0]
        device_id = device['id']
        current_balance = float(device['loan_balance'])
        
        # Calculate new balance
        new_balance = max(current_balance - payment_amount, 0.0)
        is_locked = new_balance > 0
        
        # Update device
        supabase.table('devices').update({
            'loan_balance': new_balance,
            'is_locked': is_locked,
            'last_payment_amount': payment_amount,
            'last_payment_timestamp': int(time.time())
        }).eq('id', device_id).execute()
        
        # Log transaction
        supabase.table('payment_transactions').insert({
            'device_id': device_id,
            'wallet_address': device_wallet,
            'amount': payment_amount,
            'blockchain_timestamp': int(time.time())
        }).execute()
        
        logger.info(f"Supabase updated: {device_id} - Balance: {new_balance}")
    
    except Exception as e:
        logger.error(f"Error updating Supabase: {e}", exc_info=True)


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'blockchain_blocks': len(blockchain.chain),
        'blockchain_valid': blockchain.is_chain_valid(),
        'supabase_connected': supabase is not None
    })


def main():
    """Start the blockchain server"""
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    logger.info("=" * 60)
    logger.info("Eden Blockchain Server Starting")
    logger.info("=" * 60)
    logger.info(f"Port: {port}")
    logger.info(f"Debug: {debug}")
    logger.info(f"Blockchain blocks: {len(blockchain.chain)}")
    logger.info(f"Blockchain valid: {blockchain.is_chain_valid()}")
    logger.info("=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=debug)


if __name__ == '__main__':
    import time
    main()
