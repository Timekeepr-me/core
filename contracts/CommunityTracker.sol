// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUserCalendar {
  function createAppointment(
    string memory _title,
    string memory _date,
    uint256 _day,
    address _attendee,
    uint256 _startTime,
    uint256 _endTime) external;
}

contract CommunityTracker {
  address public owner;
  mapping(address => address) userCalendars;

  constructor(address _owner) {
    owner = _owner;
  }

  // 
  /**
   * @dev called during UserCalendar deployment
   * Link EOA account to deployed UserCalendar contract
   */
  function addUserCalendar(address userAddress, address userCalendar) external {
    userCalendars[userAddress] = userCalendar;
  }

  function createGroupAppointment(
    address[] memory userEOAs,
    string memory _title,
    string memory _date,
    uint256 _day,
    address _attendee,
    uint256 _startTime,
    uint256 _endTime ) external {

    // todo: check group availability

    for (uint256 i; i < userEOAs.length; i++) {
      IUserCalendar(userEOAs[i]).createAppointment(_title, _date, _day, _attendee, _startTime, _endTime);
    }
  }
}