//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IRouter02.sol";

interface IFate {
    function burn(uint256 amount) external;
}

contract Adjustor {
    // Token Address
    address private immutable token;

    // Address => Can Adjust
    mapping(address => bool) private canAdjust;

    // Liquidity Pool Address
    address private immutable LP;

    // Dead Wallet
    address private constant dead = 0x000000000000000000000000000000000000dEaD;

    // DEX Router
    IRouter02 private router;

    // Path
    address[] path;

    modifier onlyAdjustor() {
        require(canAdjust[msg.sender], "Only Adjustors");
        _;
    }

    constructor(address token_) {
        // token
        token = token_;

        // permission to adjust
        canAdjust[msg.sender] = true;

        address currentRouter = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

        // DEX Router
        router = IRouter02(currentRouter);

        // Liquidity Pool Token
        LP = IFactoryV2(router.factory()).getPair(token_, router.WAVAX());

        // swap path
        path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = token_;
    }

    function setAdjustor(address adjustor_, bool canAdjust_)
        external
        onlyAdjustor
    {
        canAdjust[adjustor_] = canAdjust_;
    }

    function adjust(uint256 amount, address destination) external onlyAdjustor {
        _adjust(amount, destination);
    }

    function withdrawLP() external onlyAdjustor {
        IERC20(LP).transfer(msg.sender, lpBalance());
    }

    function withdrawToken() external onlyAdjustor {
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    function withdraw() external onlyAdjustor {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    receive() external payable {}

    function _adjust(uint256 amount, address destination) internal {
        // Approve Router For Amount
        IERC20(LP).approve(address(router), amount);

        // Remove `Amount` Liquidity
        router.removeLiquidityAVAXSupportingFeeOnTransferTokens(
            token,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 5000000
        );

        // Swap ETH Received For More Tokens
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(0, path, address(this), block.timestamp + 300);

        // Forward All Tokens Received
        if (destination == dead) {
            IFate(token).burn(IERC20(token).balanceOf(address(this)));
        } else {
            IERC20(token).transfer(
                destination,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function lpBalance() public view returns (uint256) {
        return IERC20(LP).balanceOf(address(this));
    }
}
