#!/usr/bin/env python3
"""
Eden Web3 Payment Listener
Monitors blockchain smart contract for payment events and updates Supabase
"""

import os
import sys
import time
import logging
from decimal import Decimal
from typing import Optional, Dict, Any

from web3 import Web3
from web3.middleware import geth_poa_middleware
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
        logging.FileHandler('eden_listener.log')
    ]
)
logger = logging.getLogger('EdenListener')


class EdenWeb3Listener:
    """
    Listens to blockchain payment events and updates device lock status
    """
    
    def __init__(self):
        # Blockchain configuration
        self.rpc_url = os.getenv('RPC_URL', 'https://polygon-rpc.com')
        self.contract_address = os.getenv('CONTRACT_ADDRESS')
        self.contract_abi = self._load_contract_abi()
        self.chain_id = int(os.getenv('CHAIN_ID', '137'))  # Polygon mainnet
        
        # Supabase configuration
        self.supabase_url = os.getenv('SUPABASE_URL')
        self.supabase_key = os.getenv('SUPABASE_SERVICE_KEY')  # Use service role key
        
        # Validate configuration
        self._validate_config()
        
        # Initialize Web3
        self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
        
        # Add PoA middleware for Polygon/BSC
        if self.chain_id in [137, 80001, 56, 97]:  # Polygon or BSC
            self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        
        # Initialize Supabase client
        self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
        
        # Initialize contract
        self.contract = self.w3.eth.contract(
            address=Web3.to_checksum_address(self.contract_address),
            abi=self.contract_abi
        )
        
        # Track last processed block
        self.last_block = self.w3.eth.block_number
        
        logger.info(f"✓ Eden Listener initialized on chain {self.chain_id}")
        logger.info(f"✓ Contract: {self.contract_address}")
        logger.info(f"✓ Starting from block: {self.last_block}")
    
    def _validate_config(self):
        """Validate required environment variables"""
        required = [
            'RPC_URL', 'CONTRACT_ADDRESS', 'SUPABASE_URL', 'SUPABASE_SERVICE_KEY'
        ]
        missing = [var for var in required if not os.getenv(var)]
        
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")
    
    def _load_contract_abi(self) -> list:
        """
        Load contract ABI
        Minimal ABI for PaymentReceived event
        """
        return [
            {
                "anonymous": False,
                "inputs": [
                    {"indexed": True, "name": "wallet", "type": "address"},
                    {"indexed": False, "name": "amount", "type": "uint256"},
                    {"indexed": False, "name": "timestamp", "type": "uint256"}
                ],
                "name": "PaymentReceived",
                "type": "event"
            }
        ]
    
    def process_payment_event(self, event: Dict[str, Any]) -> bool:
        """
        Process a PaymentReceived event and update Supabase
        """
        try:
            wallet_address = event['args']['wallet']
            amount_wei = event['args']['amount']
            timestamp = event['args']['timestamp']
            
            # Convert from Wei to Ether (or token decimals)
            amount = Decimal(amount_wei) / Decimal(10**18)
            
            logger.info(f"Payment detected: {wallet_address} paid {amount} tokens")
            
            # Fetch device from Supabase
            response = self.supabase.table('devices').select('*').eq(
                'wallet_address', wallet_address
            ).execute()
            
            if not response.data:
                logger.warning(f"No device found for wallet: {wallet_address}")
                return False
            
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
                self._log_payment(device_id, wallet_address, float(amount), timestamp)
                
                return True
            else:
                logger.error(f"Failed to update device {device_id}")
                return False
                
        except Exception as e:
            logger.error(f"Error processing payment event: {e}", exc_info=True)
            return False
    
    def _log_payment(self, device_id: str, wallet: str, amount: float, timestamp: int):
        """Log payment to transactions table"""
        try:
            self.supabase.table('payment_transactions').insert({
                'device_id': device_id,
                'wallet_address': wallet,
                'amount': amount,
                'blockchain_timestamp': timestamp,
                'processed_at': 'now()'
            }).execute()
            logger.info(f"✓ Payment logged for device {device_id}")
        except Exception as e:
            logger.error(f"Failed to log payment: {e}")
    
    def listen(self):
        """
        Main listening loop - polls for new events
        """
        logger.info("🎧 Starting event listener...")
        
        poll_interval = int(os.getenv('POLL_INTERVAL', '15'))  # seconds
        
        while True:
            try:
                current_block = self.w3.eth.block_number
                
                if current_block > self.last_block:
                    logger.info(f"Scanning blocks {self.last_block + 1} to {current_block}")
                    
                    # Get PaymentReceived events
                    event_filter = self.contract.events.PaymentReceived.create_filter(
                        fromBlock=self.last_block + 1,
                        toBlock=current_block
                    )
                    
                    events = event_filter.get_all_entries()
                    
                    if events:
                        logger.info(f"Found {len(events)} payment event(s)")
                        
                        for event in events:
                            self.process_payment_event(event)
                    
                    self.last_block = current_block
                
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
            # Test Web3 connection
            block = self.w3.eth.block_number
            logger.info(f"✓ Web3 connected - Current block: {block}")
            
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
    logger.info("Eden Web3 Payment Listener")
    logger.info("=" * 60)
    
    try:
        listener = EdenWeb3Listener()
        
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
