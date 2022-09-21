// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICommunityTracker {
  function addUserCalendar(address, address) external;
}

contract UserCalendar {
  uint256 public utc;
  uint256 public rate;
  uint256 public appointmentId = 1; // index for appointmentsArray, MUST START AT 1
  address public owner;
  string public name;
  bool initialization;

  struct Appointment {
    uint256 id;
    string title;
    address attendee;
    uint256 date;
    uint256 day;
    uint256 startTime;
    uint256 duration;
    uint256 payRate;
  }

  //(0 - 6 days) => (0000 - 2345) => true
  mapping (uint256 => mapping(uint256 => bool)) public availability;

  // 20220918 => (0000 - 2345) => true
  mapping (uint256 => mapping(uint256 => bool)) public appointments;

  uint256[2][7] public availabilityArray = [[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0]];
  Appointment[] public appointmentsArray;

  function init(string memory userName, address communityTracker) external {
    require(initialization == false);
    owner = msg.sender;
    name = userName;
    ICommunityTracker(communityTracker).addUserCalendar(msg.sender, address(this));
    initialization = true;
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

    availabilityArray[_day] = [_startTime, _endTime];
  }
  
  function readAvailability() external view returns (uint256[2][7] memory) {
    return availabilityArray;
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
    uint256 _date,
    uint256 _day,
    address _attendee,
    uint256 _startTime,
    uint256 _duration
  ) external {

    require(_day >= 0 && _day <= 6, "day is invalid");

    // manage scheduling conflict
    for (uint256 i=0; i < _duration; i++) {
      require(availability[_day][_startTime + (i*25)] == true, "appointment date/time is outside of availability");
      require(appointments[_date][_startTime + (i*25)] != true, "appointment date/time is not available");
    }

    Appointment memory appointment;
    appointment.id = appointmentId;
    appointment.title = _title;
    appointment.date = _date;
    appointment.day = _day;
    appointment.attendee = _attendee;
    appointment.startTime = _startTime;
    appointment.duration = _duration;
    appointment.payRate = rate;

    appointments[_date][_startTime] = true;

    for (uint256 j=0; j < _duration; j++) {
      appointments[_date][j] = true;
    }

    appointmentsArray.push(appointment);
    appointmentId = appointmentId+1;
  }

  function readAppointments() external view returns (Appointment[] memory) {
    return appointmentsArray;
  }

  function sortAppointments() external {
    bool swapped = true;
    while (swapped) {
      swapped = false;
      for (uint i=0; i < appointmentsArray.length-1; i++) {
        if (appointmentsArray[i].date > appointmentsArray[i+1].date) {
          Appointment memory temp = appointmentsArray[i];
          appointmentsArray[i] = appointmentsArray[i+1];
          appointmentsArray[i+1] = temp;
          swapped = true;
        }
        if (appointmentsArray[i].date == appointmentsArray[i+1].date) {
          if (appointmentsArray[i].startTime > appointmentsArray[i+1].startTime) {
            Appointment memory temp = appointmentsArray[i];
            appointmentsArray[i] = appointmentsArray[i+1];
            appointmentsArray[i+1] = temp;
            swapped = true;
          }
        }
      }
    }
  }

  function deleteAppointment(uint256 _appointmentId) external onlyOwner {
    uint256 positionId = _appointmentId - 1;
    uint256 date = appointmentsArray[positionId].date;
    uint256 start = appointmentsArray[positionId].startTime;
    uint256 duration = appointmentsArray[positionId].duration;

    for (uint256 i=0; i < duration; i++) {
      appointments[date][start + (i*25)] = false;
    }
    // does not remove appt from array, only sets all data to 0
    delete appointmentsArray[positionId];
  }
}