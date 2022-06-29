// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface INFB{
    function balanceOf(address _owner) external view returns (uint256);
    function totalHolders() external view returns(uint256);
}

interface IBEP20{
    function balanceOf(address _owner) external view returns (uint256);
}

contract NFBHandlePayout{
    using SafeMath for uint256;
    address public owner;
    uint256 _totalPayout;
    uint256 deploymentEpoch;
    INFB NFBTokenContract;

    address BUSDContractAddress= address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IBEP20 BUSDContract = IBEP20(BUSDContractAddress);

    mapping (address => User) payoutInfo;

    struct User{
        uint256 payoutCredited;
    }

    constructor(address _NFBTokenContractAddress){
        owner=msg.sender;
        deploymentEpoch=block.timestamp;
        NFBTokenContract= INFB(_NFBTokenContractAddress);
    }

    function checkEligibiltyForPayout(address sender) public view returns(bool){
        if(block.timestamp < deploymentEpoch + 5 * 365 days) return false;
        else if(NFBTokenContract.balanceOf(sender)==0) return false;
        return true;
    }

    function _transferPayout(address payable recepient, uint256 amnt) public payable{
        (bool sent, bytes memory data) = recepient.call{value: amnt}("");
        require (sent, "Failed to send");
    }

    function withdrawPayout(address recepient) public {
        require(checkEligibiltyForPayout(recepient),"Not eligible");
        User storage _user = payoutInfo[recepient];
        require(_user.payoutCredited > 0, "No amount to withdraw");
        _user.payoutCredited = BUSDContract.balanceOf(address(this)).div(NFBTokenContract.totalHolders());
        _transferPayout(payable(msg.sender), _user.payoutCredited);
        _user.payoutCredited = 0;
    }

}