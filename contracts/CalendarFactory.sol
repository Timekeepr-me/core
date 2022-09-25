// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./UserCalendar.sol";
import "./CloneFactory.sol";
import "./MoneyRouter.sol";

contract CalendarFactory is CloneFactory {
  address public owner;
  address public baseUserCalendar;
  address public baseMoneyRouter;
  address public communityTracker;
  address[] public bases;

  // EOA address to UserCalendar address
  mapping(address => address) userCalendars;

  UserCalendar[] public userCalendarsArray;
  MoneyRouter[] public moneyRoutersArray;

  event UserCalCreated(address userCalAddress);

  constructor(address _owner) {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only owner function");
    _;
  }

  // set [base] UserCalendar address, set CommunityTracker for intitialization of UserCalendar 
  // note: add onlyOwner for production
  function setBases(address _baseUserCalendar, address _baseMoneyRouter, address _communityTracker) external {
    baseUserCalendar = _baseUserCalendar;
    baseMoneyRouter = _baseMoneyRouter;
    communityTracker = _communityTracker;
    bases.push(_baseUserCalendar);
    bases.push(_baseMoneyRouter);
    bases.push(_communityTracker);
  }

  // create instance of UserCalendar with unique userName and call initialize function (constructor)
  function createUserCal(string memory userName, address host) external {
    // clone
    MoneyRouter moneyRouter = MoneyRouter(createClone(baseMoneyRouter));
    UserCalendar userCalendar = UserCalendar(createClone(baseUserCalendar));

    // initialize clones
    moneyRouter.init(host, msg.sender);
    userCalendar.init(userName, address(moneyRouter), communityTracker);

    // add UserCalendar address to mapping and array for easy lookup
    userCalendars[msg.sender] = address(userCalendar);
    userCalendarsArray.push(userCalendar);

    emit UserCalCreated(communityTracker);
  }

  // verify a single user by thier EOA address
  function getUserCalendarClone(address userEOA) external view returns (address userCalendar) {
    return userCalendars[userEOA];
  }

  // get list of all UserCalendars
  function getAllUserCalendarClones() external view returns (UserCalendar[] memory) {
    return userCalendarsArray;
  }

  // get list of all moneyRouters
  function getMoneyRouterClones() external view returns (MoneyRouter[] memory) {
    return moneyRoutersArray;
  }

  function getBases() external view returns (address[] memory) {
    return bases;
  }
}
