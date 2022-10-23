//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Treasury {
    // Fate Token
    address public fateToken;
    address public owner;

    constructor(address _fateToken) {
        fateToken = _fateToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function transferFateToken(address _to, uint256 _amount) public onlyOwner {
        IERC20(fateToken).transfer(_to, _amount);
    }

    function airDrop(address[] memory _to, uint256[] memory _amount) public onlyOwner {
        require(_to.length == _amount.length, "Invalid array length");
        for (uint256 i = 0; i < _to.length; i++) {
            IERC20(fateToken).transfer(_to[i], _amount[i]);
        }
    }

    // set the fate token address
    function setFateToken(address _fateToken) public onlyOwner {
        fateToken = _fateToken;
    }

    // receive ether
    receive() external payable {}

    // withdraw ether
    function withdrawEther(uint256 _amount) public onlyOwner {
        // transfer ether to owner
        payable(owner).transfer(_amount);
    }

    // withdraw token
    function withdrawToken(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(owner, _amount);
    }
}
