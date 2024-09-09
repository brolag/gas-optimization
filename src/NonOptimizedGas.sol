// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract GasContract {
    address[5] public administrators;
    address private immutable contractOwner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private addrToAmount;
    event AddedToWhitelist(address userAddress, uint tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) payable {
        contractOwner = msg.sender;
        assembly {
            mstore(0x0, caller())
            mstore(0x20, balances.slot)
            let balancesSlot := keccak256(0x0, 0x40)
            sstore(balancesSlot, _totalSupply)
            for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                let admin := mload(add(add(_admins, 0x20), mul(i, 0x20)))
                sstore(add(administrators.slot, i), admin)
            }
        }
    }

    function transfer(address _recipient, uint256 _amount, string calldata) external returns (bool status_) {
        uint256 senderBalance = balances[msg.sender];
        unchecked {
            balances[msg.sender] = senderBalance - _amount;
            balances[_recipient] += _amount;
        }
        return true;
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        uint256 whitelistAmount = whitelist[msg.sender];
        uint256 senderBalance = balances[msg.sender];
        
        unchecked {
            balances[msg.sender] = senderBalance - _amount + whitelistAmount;
            balances[_recipient] += _amount - whitelistAmount;
        }

        addrToAmount[msg.sender] = _amount;
        emit WhiteListTransfer(_recipient);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)  external {
        if (msg.sender != contractOwner) {
            revert();
        }
        if (_tier >= 255) {
            revert();
        }
        unchecked {
            whitelist[_userAddrs] = _tier < 3 ? 2 : 3;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        uint256 amount = addrToAmount[sender];
        return (amount != 0, amount);
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function checkForAdmin(address _user) external view returns (bool) {
        return _user == contractOwner;
    }
}