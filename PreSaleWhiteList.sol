//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract PreSaleWhiteList {
    address public owner;
    mapping(address => bool) public whiteList;
    IERC20 public tokenAddress;
    IERC20 public stableCoinAddress;
    uint256 public tokenPrice; // 1 token = ? stable coin (6 decimals)
    bool whiteListRestrict = true;
    bool presaleEnable = false;

    constructor(
        address _tokenAddress,
        address _stableCoinAddress,
        uint256 _tokenPrice
    ) {
        owner = msg.sender;
        tokenAddress = IERC20(_tokenAddress);
        stableCoinAddress = IERC20(_stableCoinAddress);
        tokenPrice = _tokenPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function addToWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }
    }

    function removeFromWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = false;
        }
    }

    // set the token address
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }

    // set the stable coin address
    function setStableCoinAddress(address _stableCoinAddress) public onlyOwner {
        stableCoinAddress = IERC20(_stableCoinAddress);
    }

    // set the token price
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    // set pre sale status
    function setPreSaleStatus(bool status) public onlyOwner {
        presaleEnable = status;
    }

    // set whitelist status
    function setWhiteListStatus(bool status) public onlyOwner {
        presaleEnable = status;
    }

    // buy tokens
    function buyTokens(uint256 _amount) public {
        require(
            presaleEnable,
            "Sale is not active. You can not buy currently."
        );
        if (whiteListRestrict)
            require(whiteList[msg.sender], "You are not in the whitelist");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens in the contract"
        );
        // deduct the stable coin from the user
        require(
            stableCoinAddress.transferFrom(msg.sender, address(this),( _amount * tokenPrice) / 1e18),
            "Transfer failed"
        );
        IERC20(tokenAddress).transfer(msg.sender, _amount);
    }

    // withdraw stable coin
    function withdrawStableCoin(uint256 _amount) public onlyOwner {
        require(
            stableCoinAddress.balanceOf(address(this)) >= _amount,
            "Not enough stable coin in the contract"
        );
        stableCoinAddress.transfer(msg.sender, _amount);
    }

    // withdraw tokens
    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens in the contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, _amount);
    }

    // withdraw all tokens
    function withdrawAllTokens() public onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
    }

    // withdraw all stable coin
    function withdrawAllStableCoin() public onlyOwner {
        uint256 balance = stableCoinAddress.balanceOf(address(this));
        stableCoinAddress.transfer(msg.sender, balance);
    }
}
