#!/usr/bin/env python3
"""
Test script for Eden Blockchain
"""

import requests
import json

BASE_URL = "http://localhost:5000"

def test_blockchain():
    print("Testing Eden Blockchain API\n")
    
    # Test 1: Get blockchain info
    print("1. Getting blockchain info...")
    response = requests.get(f"{BASE_URL}/api/info")
    print(json.dumps(response.json(), indent=2))
    
    # Test 2: Submit payment
    print("\n2. Submitting payment...")
    payment_data = {
        "device_wallet": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        "amount": 1000.0,
        "sender": "test_user"
    }
    response = requests.post(f"{BASE_URL}/api/payment", json=payment_data)
    print(json.dumps(response.json(), indent=2))
    
    # Test 3: Get balance
    print("\n3. Getting balance...")
    wallet = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
    response = requests.get(f"{BASE_URL}/api/balance/{wallet}")
    print(json.dumps(response.json(), indent=2))
    
    # Test 4: Validate chain
    print("\n4. Validating blockchain...")
    response = requests.get(f"{BASE_URL}/api/validate")
    print(json.dumps(response.json(), indent=2))

if __name__ == '__main__':
    test_blockchain()
