// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenDepositContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address private tokenAddress;
    uint256 private threshold;
    mapping(address => uint256) private balances;
    bool private locked;

    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensTransferred(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress, uint256 _threshold) {
        tokenAddress = _tokenAddress;
        threshold = _threshold;
    }

    modifier lock() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    function depositTokens(uint256 amount, address recipient) external nonReentrant lock {
        require(recipient != address(0), "Invalid recipient address.");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount.mul(1e18), "Insufficient balance.");

        require(token.transferFrom(msg.sender, address(this), amount.mul(1e18)), "Transfer failed.");

        balances[recipient] = balances[recipient].add(amount);
        emit TokensDeposited(recipient, amount);

        if (balances[recipient] >= threshold) {
            uint256 transferAmount = balances[recipient];
            balances[recipient] = 0;

            require(token.transfer(recipient, transferAmount.mul(1e18)), "Transfer failed.");
            emit TokensTransferred(recipient, transferAmount);
        }
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        emit OwnershipTransferred(owner(), newOwner);
        super.transferOwnership(newOwner);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
}