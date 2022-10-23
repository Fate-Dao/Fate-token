//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRouter02.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract FateSwapper is Ownable {
    // Fate Token
    address public immutable token;

    // router
    IRouter02 router =
        IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    // path
    address[] path;

    constructor(address _token) {
        token = _token;
        path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = _token;
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function withdraw() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function buyToken(address recipient, uint256 minOut) external payable {
        _buyToken(recipient, msg.value, minOut);
    }

    function buyToken(address recipient) external payable {
        _buyToken(recipient, msg.value, 0);
    }

    function buyToken() external payable {
        _buyToken(msg.sender, msg.value, 0);
    }

    receive() external payable {
        _buyToken(msg.sender, msg.value, 0);
    }

    function _buyToken(
        address recipient,
        uint256 value,
        uint256 minOut
    ) internal {
        require(value > 0, "Zero Value");
        require(recipient != address(0), "Recipient Cannot Be Zero");
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: value}(
            minOut,
            path,
            recipient,
            block.timestamp + 300
        );
    }
}
