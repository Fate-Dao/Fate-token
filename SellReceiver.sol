//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IFate {
    function getOwner() external view returns (address);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

contract SellReceiver {
    // Fate token
    address public token;

    // Recipients Of Fees
    // TODO: need to set the addresses for treasury and marketing
    address public treasury;
    address public marketing;

    /**
        Minimum Amount Of Fate In Contract To Trigger `trigger` Unless `approved`
            If Set To A Very High Number, Only Approved May Call Trigger Function
            If Set To A Very Low Number, Anybody May Call At Their Leasure
     */
    uint256 public minimumTokensRequiredToTrigger;

    // Address => Can Call Trigger
    mapping(address => bool) public approved;

    // Events
    event Approved(address caller, bool isApproved);

    // Trust Fund Allocation
    uint256 public marketingPercentage = 412;
    uint256 public treasuryPercentage = 588;

    modifier onlyOwner() {
        require(msg.sender == IFate(token).getOwner(), "Only Fate Token Owner");
        _;
    }

    constructor(address tokenAddress, address treasuryAddress, address marketingAddress) {
        // set initial approved
        approved[msg.sender] = true;

        // only approved can trigger at the start
        minimumTokensRequiredToTrigger = 10**30;

        // set token address
        token = tokenAddress;

        // set treasury address
        treasury = treasuryAddress;

        // set marketing address
        marketing = marketingAddress;
    }

    function trigger() external {
        // Fate Balance In Contract
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < minimumTokensRequiredToTrigger && !approved[msg.sender]) {
            return;
        }

        // fraction out tokens
        uint256 part1 = (balance * treasuryPercentage) / 1000;
        uint256 part2 = (balance * marketingPercentage) / 1000;

        // send to destinations
        _send(treasury, part1);
        _send(marketing, part2);
    }

    function setApproved(address caller, bool isApproved) external onlyOwner {
        approved[caller] = isApproved;
        emit Approved(caller, isApproved);
    }

    function setMinTriggerAmount(uint256 minTriggerAmount) external onlyOwner {
        minimumTokensRequiredToTrigger = minTriggerAmount;
    }

    function setTreasuryPercentage(uint256 newAllocatiton) external onlyOwner {
        treasuryPercentage = newAllocatiton;
    }

    function setMarketingPercentage(uint256 newAllocatiton) external onlyOwner {
        marketingPercentage = newAllocatiton;
    }

    function withdraw() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setTreasuryWallet(address wallet) external onlyOwner {
        treasury = wallet;
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        marketing = wallet;
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    receive() external payable {}

    function _send(address recipient, uint256 amount) internal {
        bool s = IERC20(token).transfer(recipient, amount);
        require(s, "Failure On Token Transfer");
    }
}
