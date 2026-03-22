# Smart Contract Guide

Example Solidity smart contract for Eden payment system.

## Overview

The Eden backend listener monitors a smart contract for `PaymentReceived` events. When a payment is detected, it updates the device's loan balance in Supabase.

## Minimal Contract Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EdenPaymentContract
 * @dev Simple payment contract for Eden device payments
 */
contract EdenPaymentContract {
    
    // Event emitted when payment is received
    event PaymentReceived(
        address indexed wallet,
        uint256 amount,
        uint256 timestamp
    );
    
    // Owner of the contract (Eden Services)
    address public owner;
    
    // Mapping of wallet addresses to total payments
    mapping(address => uint256) public totalPaid;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Make a payment for a device
     * @param deviceWallet The wallet address associated with the device
     */
    function makePayment(address deviceWallet) external payable {
        require(msg.value > 0, "Payment must be greater than 0");
        require(deviceWallet != address(0), "Invalid device wallet");
        
        // Record payment
        totalPaid[deviceWallet] += msg.value;
        
        // Emit event (this is what the backend listens for)
        emit PaymentReceived(deviceWallet, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw collected payments (owner only)
     */
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get total paid by a wallet
     */
    function getTotalPaid(address wallet) external view returns (uint256) {
        return totalPaid[wallet];
    }
}
```

## ERC-20 Token Version

For payments using ERC-20 tokens (USDC, USDT, etc.):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EdenTokenPayment {
    
    event PaymentReceived(
        address indexed wallet,
        uint256 amount,
        uint256 timestamp
    );
    
    address public owner;
    IERC20 public paymentToken;
    
    mapping(address => uint256) public totalPaid;
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        paymentToken = IERC20(_tokenAddress);
    }
    
    function makePayment(address deviceWallet, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(deviceWallet != address(0), "Invalid device wallet");
        
        // Transfer tokens from sender to contract
        require(
            paymentToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        
        totalPaid[deviceWallet] += amount;
        
        emit PaymentReceived(deviceWallet, amount, block.timestamp);
    }
    
    function withdrawTokens() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = paymentToken.balanceOf(address(this));
        require(paymentToken.transfer(owner, balance), "Transfer failed");
    }
}
```

## Deployment

### Using Remix IDE

1. Go to https://remix.ethereum.org
2. Create new file: `EdenPayment.sol`
3. Paste contract code
4. Compile with Solidity 0.8.20+
5. Deploy to network:
   - **Polygon Mumbai (Testnet)**: ChainID 80001
   - **Polygon Mainnet**: ChainID 137
   - **BSC Testnet**: ChainID 97
   - **BSC Mainnet**: ChainID 56

### Using Hardhat

```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

npx hardhat init

# Edit hardhat.config.js
# Add deployment script
npx hardhat run scripts/deploy.js --network polygon
```

### Deployment Script (Hardhat)

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const EdenPayment = await hre.ethers.getContractFactory("EdenPaymentContract");
  const contract = await EdenPayment.deploy();
  
  await contract.deployed();
  
  console.log("EdenPayment deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

## Backend Configuration

After deploying, update your backend `.env`:

```bash
# Polygon Mainnet
RPC_URL=https://polygon-rpc.com
CONTRACT_ADDRESS=0xYourDeployedContractAddress
CHAIN_ID=137

# Or BSC Mainnet
RPC_URL=https://bsc-dataseed.binance.org
CONTRACT_ADDRESS=0xYourDeployedContractAddress
CHAIN_ID=56
```

## Testing Payments

### Test on Polygon Mumbai

```javascript
// Using ethers.js
const { ethers } = require("ethers");

const provider = new ethers.providers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com");
const wallet = new ethers.Wallet("YOUR_PRIVATE_KEY", provider);

const contractAddress = "0xYourContractAddress";
const contractABI = [...]; // Your contract ABI

const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// Make payment
const deviceWallet = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb";
const amount = ethers.utils.parseEther("0.1"); // 0.1 MATIC

const tx = await contract.makePayment(deviceWallet, { value: amount });
await tx.wait();

console.log("Payment sent:", tx.hash);
```

### Test via Remix

1. Deploy contract on Mumbai testnet
2. Get test MATIC from https://faucet.polygon.technology
3. Call `makePayment` function with:
   - `deviceWallet`: Device's wallet address
   - `value`: Amount in Wei (e.g., 100000000000000000 = 0.1 MATIC)

## Event Monitoring

The backend listener watches for this event:

```solidity
event PaymentReceived(
    address indexed wallet,  // Device wallet address
    uint256 amount,          // Payment amount in Wei
    uint256 timestamp        // Block timestamp
);
```

**Important:** The event signature must match exactly for the backend to detect it.

## Gas Optimization

For production, consider:

1. **Batch Payments**: Allow multiple payments in one transaction
2. **Gas Tokens**: Use CHI or GST2 for gas savings
3. **Layer 2**: Deploy on Polygon or Arbitrum for lower fees

## Security Considerations

1. **Reentrancy Protection**: Use OpenZeppelin's ReentrancyGuard
2. **Access Control**: Implement proper owner controls
3. **Pausable**: Add emergency pause functionality
4. **Upgradeable**: Consider using proxy pattern for upgrades

## Example with Security Features

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EdenPaymentSecure is ReentrancyGuard, Pausable, Ownable {
    
    event PaymentReceived(
        address indexed wallet,
        uint256 amount,
        uint256 timestamp
    );
    
    mapping(address => uint256) public totalPaid;
    
    function makePayment(address deviceWallet) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        require(msg.value > 0, "Payment must be greater than 0");
        require(deviceWallet != address(0), "Invalid device wallet");
        
        totalPaid[deviceWallet] += msg.value;
        
        emit PaymentReceived(deviceWallet, msg.value, block.timestamp);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}
```

## Verification on Block Explorer

After deployment, verify your contract:

1. Go to PolygonScan or BSCScan
2. Find your contract address
3. Click "Verify and Publish"
4. Upload source code and constructor arguments
5. Contract will be publicly verifiable

## Resources

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Polygon Documentation](https://docs.polygon.technology/)
- [BSC Documentation](https://docs.bnbchain.org/)
