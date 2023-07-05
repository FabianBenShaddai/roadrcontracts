// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FeeBeneficiary.sol";

contract TokenSwap is Ownable {
    using SafeMath for uint256;

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public buyPrice;  // Valor de compra: 1.05
    uint256 public sellPrice; // Valor de venta: 0.95
    FeeBeneficiary public feeBeneficiary;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensSold(address indexed seller, uint256 amount);

    constructor(address _tokenA, address _tokenB, address _feeBeneficiary) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        buyPrice = 105;  // Dividido por 100 para obtener el valor real: 1.05
        sellPrice = 95;  // Dividido por 100 para obtener el valor real: 0.95
        feeBeneficiary = FeeBeneficiary(_feeBeneficiary);
    }

    function depositTokenA(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        tokenA.transferFrom(msg.sender, address(this), _amount);
    }

    function depositTokenB(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        tokenB.transferFrom(msg.sender, address(this), _amount);
    }

    function swapTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        uint256 allowance = tokenA.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");

        uint256 tokensToBuy = _amount.mul(buyPrice).div(100);

        require(tokenB.balanceOf(address(this)) >= tokensToBuy, "Insufficient liquidity");

        tokenA.transferFrom(msg.sender, address(this), _amount);
        tokenB.transfer(msg.sender, tokensToBuy);

        uint256 feeAmount = _amount.mul(10).div(100); // 0.10 (10%)
        tokenA.transfer(address(feeBeneficiary), feeAmount);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }


    function sellTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        uint256 allowance = tokenB.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");

        uint256 tokensToSell = _amount.mul(sellPrice).div(100);

        require(tokenA.balanceOf(address(this)) >= tokensToSell, "Insufficient liquidity");

        tokenB.transferFrom(msg.sender, address(this), _amount);
        tokenA.transfer(msg.sender, tokensToSell);

        emit TokensSold(msg.sender, tokensToSell);
    }

    function setBuyPrice(uint256 _price) external onlyOwner {
        buyPrice = _price;
    }

    function setSellPrice(uint256 _price) external onlyOwner {
        sellPrice = _price;
    }

    function setFeeBeneficiaryAddress(address _feeBeneficiary) external onlyOwner {
        feeBeneficiary = FeeBeneficiary(_feeBeneficiary);
    }
}