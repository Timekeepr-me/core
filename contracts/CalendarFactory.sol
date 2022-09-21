// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./UserCalendar.sol";
import "./CloneFactory.sol";

contract CalendarFactory is CloneFactory {
  address public owner;
  address public baseUserCalendar;
  address public communityTracker;

  mapping(address => address) userCalendars;
  UserCalendar[] public userCalendarsArray;

  event UserCalCreated(address userCalAddress);

  constructor(address _owner) {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only owner function");
    _;
  }

  function setBases(address _baseUserCalendar, address _communityTracker) external onlyOwner {
    baseUserCalendar = _baseUserCalendar;
    communityTracker = _communityTracker;
  }

  function createUserCal(string memory userName) external {
    UserCalendar userCalendar = UserCalendar(createClone(baseUserCalendar));
    userCalendar.init(userName, communityTracker);

    userCalendars[msg.sender] = address(userCalendar);
    userCalendarsArray.push(userCalendar);

    emit UserCalCreated(communityTracker);
  }

  function getUserCalendarClone(address user) external view returns (address userCalendar) {
    return userCalendars[user];
  }

  function getAllUserCalendarClones() external view returns (UserCalendar[] memory) {
    return userCalendarsArray;
  }
}
