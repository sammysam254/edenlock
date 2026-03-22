#!/usr/bin/env python3
"""
Eden Blockchain - Simple Custom Blockchain for Payment Tracking
A lightweight blockchain implementation for Eden device payment verification
"""

import hashlib
import json
import time
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from datetime import datetime


@dataclass
class Transaction:
    """Payment transaction"""
    device_wallet: str
    amount: float
    timestamp: int
    sender: str = "eden_system"
    transaction_id: str = ""
    
    def __post_init__(self):
        if not self.transaction_id:
            self.transaction_id = self.calculate_hash()
    
    def calculate_hash(self) -> str:
        """Calculate transaction hash"""
        tx_string = f"{self.device_wallet}{self.amount}{self.timestamp}{self.sender}"
        return hashlib.sha256(tx_string.encode()).hexdigest()
    
    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class Block:
    """Blockchain block"""
    index: int
    timestamp: int
    transactions: List[Transaction]
    previous_hash: str
    nonce: int = 0
    hash: str = ""
    
    def __post_init__(self):
        if not self.hash:
            self.hash = self.calculate_hash()
    
    def calculate_hash(self) -> str:
        """Calculate block hash"""
        block_string = json.dumps({
            'index': self.index,
            'timestamp': self.timestamp,
            'transactions': [tx.to_dict() for tx in self.transactions],
            'previous_hash': self.previous_hash,
            'nonce': self.nonce
        }, sort_keys=True)
        return hashlib.sha256(block_string.encode()).hexdigest()
    
    def mine_block(self, difficulty: int = 2):
        """Mine block with proof of work"""
        target = '0' * difficulty
        while self.hash[:difficulty] != target:
            self.nonce += 1
            self.hash = self.calculate_hash()
        print(f"Block mined: {self.hash}")
    
    def to_dict(self) -> dict:
        return {
            'index': self.index,
            'timestamp': self.timestamp,
            'transactions': [tx.to_dict() for tx in self.transactions],
            'previous_hash': self.previous_hash,
            'nonce': self.nonce,
            'hash': self.hash
        }


class EdenBlockchain:
    """Eden custom blockchain for payment tracking"""
    
    def __init__(self, difficulty: int = 2):
        self.chain: List[Block] = []
        self.pending_transactions: List[Transaction] = []
        self.difficulty = difficulty
        self.mining_reward = 0  # No mining reward for Eden
        
        # Create genesis block
        self.create_genesis_block()
    
    def create_genesis_block(self):
        """Create the first block in the chain"""
        genesis_block = Block(
            index=0,
            timestamp=int(time.time()),
            transactions=[],
            previous_hash="0"
        )
        genesis_block.mine_block(self.difficulty)
        self.chain.append(genesis_block)
        print("Genesis block created")
    
    def get_latest_block(self) -> Block:
        """Get the most recent block"""
        return self.chain[-1]
    
    def add_transaction(self, device_wallet: str, amount: float, sender: str = "eden_system") -> str:
        """Add a new payment transaction"""
        transaction = Transaction(
            device_wallet=device_wallet,
            amount=amount,
            timestamp=int(time.time()),
            sender=sender
        )
        self.pending_transactions.append(transaction)
        print(f"Transaction added: {device_wallet} paid {amount}")
        return transaction.transaction_id
    
    def mine_pending_transactions(self):
        """Mine all pending transactions into a new block"""
        if not self.pending_transactions:
            print("No transactions to mine")
            return
        
        block = Block(
            index=len(self.chain),
            timestamp=int(time.time()),
            transactions=self.pending_transactions,
            previous_hash=self.get_latest_block().hash
        )
        
        block.mine_block(self.difficulty)
        self.chain.append(block)
        
        print(f"Block #{block.index} mined with {len(self.pending_transactions)} transactions")
        self.pending_transactions = []
    
    def get_balance(self, wallet_address: str) -> float:
        """Get total payments for a wallet address"""
        balance = 0.0
        for block in self.chain:
            for transaction in block.transactions:
                if transaction.device_wallet == wallet_address:
                    balance += transaction.amount
        return balance
    
    def get_transactions_for_wallet(self, wallet_address: str) -> List[Transaction]:
        """Get all transactions for a specific wallet"""
        transactions = []
        for block in self.chain:
            for transaction in block.transactions:
                if transaction.device_wallet == wallet_address:
                    transactions.append(transaction)
        return transactions
    
    def is_chain_valid(self) -> bool:
        """Validate the entire blockchain"""
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i - 1]
            
            # Check if current block hash is correct
            if current_block.hash != current_block.calculate_hash():
                print(f"Invalid hash at block {i}")
                return False
            
            # Check if previous hash matches
            if current_block.previous_hash != previous_block.hash:
                print(f"Invalid previous hash at block {i}")
                return False
        
        return True
    
    def get_chain_info(self) -> dict:
        """Get blockchain statistics"""
        total_transactions = sum(len(block.transactions) for block in self.chain)
        return {
            'total_blocks': len(self.chain),
            'total_transactions': total_transactions,
            'difficulty': self.difficulty,
            'is_valid': self.is_chain_valid(),
            'latest_block_hash': self.get_latest_block().hash
        }
    
    def export_chain(self, filename: str = "eden_blockchain.json"):
        """Export blockchain to JSON file"""
        chain_data = [block.to_dict() for block in self.chain]
        with open(filename, 'w') as f:
            json.dump(chain_data, f, indent=2)
        print(f"Blockchain exported to {filename}")
    
    def import_chain(self, filename: str = "eden_blockchain.json"):
        """Import blockchain from JSON file"""
        try:
            with open(filename, 'r') as f:
                chain_data = json.load(f)
            
            self.chain = []
            for block_data in chain_data:
                transactions = [
                    Transaction(**tx) for tx in block_data['transactions']
                ]
                block = Block(
                    index=block_data['index'],
                    timestamp=block_data['timestamp'],
                    transactions=transactions,
                    previous_hash=block_data['previous_hash'],
                    nonce=block_data['nonce'],
                    hash=block_data['hash']
                )
                self.chain.append(block)
            
            print(f"Blockchain imported from {filename}")
            print(f"Chain valid: {self.is_chain_valid()}")
        except FileNotFoundError:
            print(f"File {filename} not found")


def main():
    """Demo of Eden Blockchain"""
    print("=" * 60)
    print("Eden Blockchain - Payment Tracking System")
    print("=" * 60)
    
    # Create blockchain
    blockchain = EdenBlockchain(difficulty=2)
    
    # Add some test transactions
    print("\n--- Adding Transactions ---")
    blockchain.add_transaction("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb", 1000.0)
    blockchain.add_transaction("0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063", 500.0)
    blockchain.add_transaction("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb", 250.0)
    
    # Mine transactions
    print("\n--- Mining Block ---")
    blockchain.mine_pending_transactions()
    
    # Add more transactions
    print("\n--- Adding More Transactions ---")
    blockchain.add_transaction("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb", 100.0)
    blockchain.add_transaction("0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063", 300.0)
    
    # Mine again
    print("\n--- Mining Block ---")
    blockchain.mine_pending_transactions()
    
    # Check balances
    print("\n--- Checking Balances ---")
    wallet1 = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
    wallet2 = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"
    
    print(f"Wallet {wallet1[:10]}... balance: {blockchain.get_balance(wallet1)}")
    print(f"Wallet {wallet2[:10]}... balance: {blockchain.get_balance(wallet2)}")
    
    # Get chain info
    print("\n--- Blockchain Info ---")
    info = blockchain.get_chain_info()
    for key, value in info.items():
        print(f"{key}: {value}")
    
    # Validate chain
    print(f"\nBlockchain valid: {blockchain.is_chain_valid()}")
    
    # Export chain
    print("\n--- Exporting Blockchain ---")
    blockchain.export_chain()


if __name__ == '__main__':
    main()
