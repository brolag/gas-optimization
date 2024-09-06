// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    address private immutable contractOwner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => uint256) private addrToAmount;

    event AddedToWhitelist(address userAddress, uint256 tier);

    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) payable {
        contractOwner = msg.sender;
        balances[contractOwner] = _totalSupply;
        for (uint256 ii = 0; ii < 5;) {
            administrators[ii] = _admins[ii];
            unchecked {
                ii++;
            }
        }
    }

    function checkForAdmin(address _user) external view returns (bool) {
        return _user == contractOwner;
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata) external returns (bool status) {
        uint256 senderBalance = balances[msg.sender];

        unchecked {
            balances[msg.sender] = senderBalance - _amount;
            balances[_recipient] += _amount;
        }
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        if (msg.sender != contractOwner) {
            revert();
        }
        if (_tier >= 255) {
            revert();
        }
        whitelist[_userAddrs] = _tier < 3 ? 2 : 3;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        addrToAmount[msg.sender] = _amount;
        uint256 whitelistAmount = whitelist[msg.sender];
        uint256 senderBalance = balances[msg.sender];

        unchecked {
            balances[msg.sender] = senderBalance - _amount + whitelistAmount;
            balances[_recipient] += _amount - whitelistAmount;
        }
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        uint256 amount = addrToAmount[sender];
        bool status = amount > 0;
        return (status, amount);
    }
}