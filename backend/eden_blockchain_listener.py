#!/usr/bin/env python3
"""
Eden Blockchain Listener - Monitors custom Eden blockchain for payments
Replaces Web3 listener with custom blockchain integration
"""

import os
import sys
import time
import logging
import requests
from decimal import Decimal
from typing import Optional, Dict, Any
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('eden_blockchain_listener.log')
    ]
)
logger = logging.getLogger('EdenBlockchainListener')


class EdenBlockchainListener:
    """
    Listens to Eden custom blockchain for payment transactions
    """
    
    def __init__(self):
        # Blockchain configuration
        self.blockchain_url = os.getenv('BLOCKCHAIN_URL', 'http://localhost:5000')
        
        # Supabase configuration
        self.supabase_url = os.getenv('SUPABASE_URL')
        self.supabase_key = os.getenv('SUPABASE_SERVICE_KEY')
        
        # Validate configuration
        self._validate_config()
        
        # Initialize Supabase client
        self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
        
        # Track last processed block
        self.last_processed_block = 0
        
        logger.info(f"✓ Eden Blockchain Listener initialized")
        logger.info(f"✓ Blockchain URL: {self.blockchain_url}")
    
    def _validate_config(self):
        """Validate required environment variables"""
        required = ['BLOCKCHAIN_URL', 'SUPABASE_URL', 'SUPABASE_SERVICE_KEY']
        missing = [var for var in required if not os.getenv(var)]
        
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")
    
    def get_blockchain_info(self) -> Optional[Dict]:
        """Get blockchain information"""
        try:
            response = requests.get(f"{self.blockchain_url}/api/info", timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error getting blockchain info: {e}")
            return None
    
    def get_new_blocks(self) -> list:
        """Get new blocks since last check"""
        try:
            response = requests.get(f"{self.blockchain_url}/api/chain", timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if not data.get('success'):
                return []
            
            chain = data.get('chain', [])
            new_blocks = [block for block in chain if block['index'] > self.last_processed_block]
            
            return new_blocks
        except Exception as e:
            logger.error(f"Error getting new blocks: {e}")
            return []
    
    def process_block(self, block: Dict) -> bool:
        """Process a single block and its transactions"""
        try:
            block_index = block['index']
            transactions = block.get('transactions', [])
            
            if not transactions:
                logger.info(f"Block #{block_index} has no transactions")
                return True
            
            logger.info(f"Processing block #{block_index} with {len(transactions)} transaction(s)")
            
            for transaction in transactions:
                self.process_transaction(transaction, block_index)
            
            return True
        except Exception as e:
            logger.error(f"Error processing block: {e}", exc_info=True)
            return False
    
    def process_transaction(self, transaction: Dict, block_index: int):
        """Process a single payment transaction"""
        try:
            device_wallet = transaction['device_wallet']
            amount = Decimal(str(transaction['amount']))
            timestamp = transaction['timestamp']
            
            logger.info(f"Payment detected: {device_wallet} paid {amount}")
            
            # Fetch device from Supabase
            response = self.supabase.table('devices').select('*').eq(
                'wallet_address', device_wallet
            ).execute()
            
            if not response.data:
                logger.warning(f"No device found for wallet: {device_wallet}")
                return
            
            device = response.data[0]
            device_id = device['id']
            current_balance = Decimal(str(device['loan_balance']))
            
            # Calculate new balance
            new_balance = max(current_balance - amount, Decimal('0'))
            is_locked = new_balance > 0
            
            logger.info(f"Device {device_id}: Balance {current_balance} -> {new_balance}")
            
            # Update device in Supabase
            update_response = self.supabase.table('devices').update({
                'loan_balance': float(new_balance),
                'is_locked': is_locked,
                'last_payment_amount': float(amount),
                'last_payment_timestamp': timestamp,
                'updated_at': 'now()'
            }).eq('id', device_id).execute()
            
            if update_response.data:
                logger.info(f"✓ Device {device_id} updated - Locked: {is_locked}")
                
                # Log payment transaction
                self._log_payment(device_id, device_wallet, float(amount), timestamp, block_index)
            else:
                logger.error(f"Failed to update device {device_id}")
                
        except Exception as e:
            logger.error(f"Error processing transaction: {e}", exc_info=True)
    
    def _log_payment(self, device_id: str, wallet: str, amount: float, timestamp: int, block_index: int):
        """Log payment to transactions table"""
        try:
            self.supabase.table('payment_transactions').insert({
                'device_id': device_id,
                'wallet_address': wallet,
                'amount': amount,
                'blockchain_timestamp': timestamp,
                'processed_at': 'now()'
            }).execute()
            logger.info(f"✓ Payment logged for device {device_id} (Block #{block_index})")
        except Exception as e:
            logger.error(f"Failed to log payment: {e}")
    
    def listen(self):
        """Main listening loop"""
        logger.info("🎧 Starting blockchain listener...")
        
        poll_interval = int(os.getenv('POLL_INTERVAL', '15'))
        
        while True:
            try:
                # Get new blocks
                new_blocks = self.get_new_blocks()
                
                if new_blocks:
                    logger.info(f"Found {len(new_blocks)} new block(s)")
                    
                    for block in new_blocks:
                        if self.process_block(block):
                            self.last_processed_block = block['index']
                
                # Wait before next poll
                time.sleep(poll_interval)
                
            except KeyboardInterrupt:
                logger.info("Listener stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in listener loop: {e}", exc_info=True)
                time.sleep(poll_interval)
    
    def test_connection(self) -> bool:
        """Test blockchain and Supabase connections"""
        try:
            # Test blockchain connection
            info = self.get_blockchain_info()
            if info and info.get('success'):
                logger.info(f"✓ Blockchain connected - Blocks: {info['data']['total_blocks']}")
            else:
                logger.error("✗ Blockchain connection failed")
                return False
            
            # Test Supabase connection
            response = self.supabase.table('devices').select('count').execute()
            logger.info(f"✓ Supabase connected - Devices: {len(response.data)}")
            
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False


def main():
    """Main entry point"""
    logger.info("=" * 60)
    logger.info("Eden Blockchain Listener")
    logger.info("=" * 60)
    
    try:
        listener = EdenBlockchainListener()
        
        # Test connections
        if not listener.test_connection():
            logger.error("Connection test failed - exiting")
            sys.exit(1)
        
        # Start listening
        listener.listen()
        
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
