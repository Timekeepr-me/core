// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./UserCalendar.sol";

contract UserCalendarFactory {

    address public calendarTemplate;
    uint256 public calendarId = 0;
    address[] public allCalendars;

    constructor(address _calendarTemplate) {
        calendarTemplate = _calendarTemplate;
    }

    event UserCalendarCreated(address indexed calAddress, string indexed name);

    function createUserCalendar(
            string memory _name
        ) external returns (address) {

        UserCalendar userCalendar = Shop(_createClone(shopTemplate));
        shop.initialize(
            msg.sender,
            _name,
            calendarId,
            address(this)
        );

        emit UserCalendarCreated(address(userCalendar), _name);

        allCalendars.push(address(userCalendar));
        calendarId++;
        return address(userCalendar);
    }


    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}
