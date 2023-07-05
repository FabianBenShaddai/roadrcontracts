// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public tokenUSDTAddress;
    address public tokenROADRAddress;
    address public feeWallet;
    uint256 public roadrPrice;  // Precio de cada token ROADR en USDT
    uint256 public sellPrice;  // Precio de venta en USDT por cada token ROADR

    constructor(
        address _tokenUSDTAddress,
        address _tokenROADRAddress,
        address _feeWallet,
        uint256 _roadrPrice,
        uint256 _sellPrice
    )
    {
        tokenUSDTAddress = _tokenUSDTAddress;
        tokenROADRAddress = _tokenROADRAddress;
        feeWallet = _feeWallet;
        roadrPrice = _roadrPrice;
        sellPrice = _sellPrice;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    function setRoadrPrice(uint256 _roadrPrice) external onlyOwner {
        require(_roadrPrice > 0, "Price must be greater than zero.");
        roadrPrice = _roadrPrice;
    }

    function setSellPrice(uint256 _sellPrice) external onlyOwner {
        require(_sellPrice > 0, "Price must be greater than zero.");
        sellPrice = _sellPrice;
    }

    function swap(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero.");

        IERC20 tokenUSDT = IERC20(tokenUSDTAddress);
        IERC20 tokenROADR = IERC20(tokenROADRAddress);

        require(tokenUSDT.allowance(msg.sender, address(this)) >= amount, "Insufficient USDT allowance.");
        require(tokenUSDT.balanceOf(msg.sender) >= amount, "Insufficient USDT balance.");

        // Cálculo de tokens ROADR a recibir
        uint256 roadrAmount = amount.mul(1e18).div(roadrPrice);

        // Cálculo de la comisión (0.10 USDT)
        uint256 feeAmount = amount.mul(100).div(1000);

        // Transferencia de USDT al contrato
        tokenUSDT.transferFrom(msg.sender, address(this), amount);

        // Transferencia de tokens ROADR al usuario
        tokenROADR.transfer(msg.sender, roadrAmount);

        // Transferencia de la comisión a la billetera de comisiones
        tokenUSDT.transfer(feeWallet, feeAmount);
    }

    function sell(uint256 amount) external nonReentrant {
        require(amount >= 100e18, "Amount must be equal or greater than 100 tokens.");

        IERC20 tokenUSDT = IERC20(tokenUSDTAddress);
        IERC20 tokenROADR = IERC20(tokenROADRAddress);

        require(tokenROADR.allowance(msg.sender, address(this)) >= amount, "Insufficient ROADR allowance.");
        require(tokenROADR.balanceOf(msg.sender) >= amount, "Insufficient ROADR balance.");

        // Cálculo de USDT a recibir por la venta de tokens ROADR
        uint256 usdtAmount = amount.mul(sellPrice).div(1e18);

        // Transferencia de tokens ROADR al contrato
        tokenROADR.transferFrom(msg.sender, address(this), amount);

        // Transferencia de USDT al usuario
        tokenUSDT.transfer(msg.sender, usdtAmount);
    }
    
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    function addUSDT(uint256 amount) external onlyOwner {
        IERC20 tokenUSDT = IERC20(tokenUSDTAddress);
        tokenUSDT.transferFrom(msg.sender, address(this), amount);
    }

    function addROADR(uint256 amount) external onlyOwner {
        IERC20 tokenROADR = IERC20(tokenROADRAddress);
        tokenROADR.transferFrom(msg.sender, address(this), amount);
    }
}