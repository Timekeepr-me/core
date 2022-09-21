// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICommunityTracker {
  function addUserCalendar(address, address) external;
}

contract UserCalendar {
  uint256 public utc;
  uint256 public rate;
  uint256 public appointmentId = 1; // index for appointmentsArr, MUST START AT 1
  address public owner;

  struct Appointment {
    uint256 id;
    string title;
    address attendee;
    string date;
    uint256 day;
    uint256 startTime;
    uint256 endTime;
    uint256 payRate;
    bool isActive;
  }

  /**
   * 0 - 6 days
   * mapping
   * 0000 - 2345 => true
   * 1315 -
   */
  mapping (uint256 => mapping(uint256 => bool)) public availability;

  /**
   * @dev "20220918" => (1330 => true) = appointment on September 18th, 1:30PM 
   */
  mapping (string => mapping(uint256 => bool)) public appointments;

  Appointment[] public appointmentsArr;

  constructor(address communityTracker) {
    owner = msg.sender;
    ICommunityTracker(communityTracker).addUserCalendar(msg.sender, address(this));
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only owner function");
    _;
  }

  function createUtc(uint256 _utc) external onlyOwner {
    // UTC range from -12 to +12
    utc = _utc;
  }

  function getUtc() external view returns(uint256) {
    return utc;
  }

  function currentTime() external view returns(uint256) {
    return uint256(block.timestamp + (utc * 60 * 60));
  }

  function createRate(uint256 _rate) external onlyOwner {
    rate = _rate;
  }

  function getRate() external view returns(uint256) {
    return rate;
  }

  /**
   * @dev set an availability block per day
   * @param _day 0-6 day of the week
   * @param _startTime 0000 - 2345 hour and minute block by 15 minute intervals
   * @param _endTime end time same format as start time
   */
  function setAvailability(uint256 _day, uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(_day >= 0 && _day <= 6, "day is invalid");
    require(_startTime >= 0, "start time is invalid");
    require(_endTime <= 2345, "start time is invalid");

    uint256 i = _startTime;
    for (i; i < _endTime; i += 15) {
      availability[_day][i] = true;
    }
  }

  function deleteAvailability(uint256 _day, uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(_day >= 0 && _day <= 6, "day is invalid");

    uint256 i = _startTime;
    for (i; i < _endTime; i += 15) {
      availability[_day][i] = false;
    }
  }

  /**
   * @param _title string
   * @param _date "20220918" -> September 18th, 2022
   * @param _day 4 -> day of the week
   * @param _startTime 1715 -> 5:15pm
   */
  function createAppointment(
    string memory _title,
    string memory _date,
    uint256 _day,
    address _attendee,
    uint256 _startTime,
    uint256 _endTime
  ) external {

    // check if time is available

    require(_day >= 0 && _day <= 6, "day is invalid");

    uint256 i = _startTime;
    for (i; i < _endTime; i += 15) {
      require(availability[_day][i] == true, "this appointment date and time is not available");
      require(appointments[_date][i] != true, "this appointment date and time is not available because of a preexisting appointment");
    }
    // todo: check if no appointment already exists

    Appointment memory appointment;
    appointment.id = appointmentId;
    appointment.title = _title;
    appointment.date = _date;
    appointment.day = _day;
    appointment.attendee = _attendee;
    appointment.startTime = _startTime;
    // consider uisng duration of 15 min blocks
    appointment.endTime = _endTime;
    appointment.payRate = rate;

    // wip
    appointments[_date][_startTime] = true;

    i = _startTime;
    for (i; i < _endTime; i += 15) {
      appointments[_date][i] = true;
    }

    appointmentsArr.push(appointment);
    appointmentId = appointmentId+1;
  }

  function readAppointments() external view returns (Appointment[] memory) {
    // todo: get start and end dates
    return appointmentsArr;
  }

  function deleteAppointment(uint256 _appointmentId) external onlyOwner {
    string memory date = appointmentsArr[_appointmentId].date;
    uint256 i = appointmentsArr[_appointmentId].startTime;
    uint256 end = appointmentsArr[_appointmentId].endTime;

    for (i; i < end; i += 15) {
      appointments[date][i] = false;
    }
    // does not remove appt from array, only sets all data to 0
    delete appointmentsArr[_appointmentId];
  }
}