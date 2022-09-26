// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";

interface ICommunityTracker {
  function addUserCalendar(address, address) external;
}

// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract UserCalendar {
  uint256 public utc;
  uint256 public rate;
  uint256 public appointmentId = 1; // index for appointmentsArray, MUST START AT 1
  address public owner;
  string public name;
  bool initialization;
  address public channel;
  bool public showTitle;
  bool public showBody;
  address public pushComm = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;
  string public availabilityEncodedStr = "";

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

  Appointment[] public appointmentsArray;

  function init(string memory userName, address communityTracker, address _owner) external {
    require(initialization == false);
    owner = _owner;
    name = userName;
    ICommunityTracker(communityTracker).addUserCalendar(_owner, address(this));
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

  function createRate(uint256 _rate) external  {
    rate = _rate;
  }

  function getRate() external view returns(uint256) {
    return rate;
  }

  /**
   * @dev set an availability block per day
   * @param _availabilityEncoded string day, start time and end time encoded in one string
   * day of the week, start time, duration
   * example: '1017503' -> 1 = Tuesday 0175 = 1:45am 03 = 3 * 15 = 45 minutes duration
   */
  function setAvailability(string memory _availabilityEncoded) external onlyOwner {
    availabilityEncodedStr = _availabilityEncoded;
    console.log(
        "setAvailability _availabilityEncoded %s",
        _availabilityEncoded
    ); 
    clearAvailability();
    uint256 i = 0;
    uint256 strLength = utfStringLength(_availabilityEncoded);
    console.log(
      "strLength %s",
      strLength
    );
    for (i; i < strLength; i += 7) {
      string memory daySubStr = substring(_availabilityEncoded, i, i + 1);
      console.log(
          "daySubStr %s",
          daySubStr
      );
      uint256 day = stringToUint(daySubStr);
      console.log(
          "day %s",
          day
      );
      uint256 startTime = stringToUint(substring(_availabilityEncoded, i + 1, i + 5));
      console.log(
          "startTime %s",
          startTime
      );
      uint256 duration = stringToUint(substring(_availabilityEncoded, i + 5, i + 7));
      console.log(
          "duration %s",
          duration
      );
      uint256 endTime = startTime + (duration * 25);
      uint256 _time = startTime;
      for (_time; _time < endTime; _time += 25) {
        availability[day][_time] = true;
      }
    }
  }

  function clearAvailability() internal {
    uint256 day = 0;
    for (day; day < 7; day++) {
      uint256 hour = 0;
      for (hour; hour < 2400; hour += 25) {
        availability[day][hour] = false;
      }
    }
  }

  function deleteAvailability(uint256 _day, uint256 _startTime, uint256 _duration) external onlyOwner {
    require(_day >= 0 && _day <= 6, "day is invalid");

    uint256 i = _startTime;
    uint256 endTime = _startTime + (_duration * 25);
    for (i; i < endTime; i + 25) {
      availability[_day][i] = false;
    }
  }

  /**
   * @param _date "20220918" -> September 18th, 2022
   * @param _day 4 -> day of the week
   * @param _startTime 1725 -> 5:15pm
   * @param _duration number of how many 15 minute blocks
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
      require(appointments[_date][_startTime + (i * 25)] != true, "appointment date/time is not available");
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

  // EPNS
  function setEPNS(bool _showTitle, bool _showBody, address _channel, address _pushComm) external {
    showTitle = _showTitle;
    showBody = _showBody;
    channel = _channel;
    pushComm = _pushComm;
  }

  function pushEPNS(string memory text) internal {
    string memory title = "";
    string memory body = "";
    if (showTitle) {
      title = text;
    }
    if (showBody) {
      body = text;
    }
    IPUSHCommInterface(pushComm).sendNotification(
      channel, // from channel - recommended to set channel via dApp and put it's value -> then once contract is deployed, go back and add the contract address as delegate for your channel
      owner, // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
      bytes(
        string(
          // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
          abi.encodePacked(
            "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
            "+", // segregator
            "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
            "+", // segregator
            title, // this is notificaiton title
            "+", // segregator
            body // notification body
          )
        )
      )
    );
  }

  // utils
  function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    console.log(
      "substring %s start %s, end %s",
      str,
      startIndex,
      endIndex
    );

    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function utfStringLength(string memory str) pure internal returns (uint length) {
    uint i=0;
    bytes memory string_rep = bytes(str);

    while (i<string_rep.length)
    {
        if (string_rep[i]>>7==0)
            i+=1;
        else if (string_rep[i]>>5==bytes1(uint8(0x6)))
            i+=2;
        else if (string_rep[i]>>4==bytes1(uint8(0xE)))
            i+=3;
        else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
            i+=4;
        else
            //For safety
            i+=1;

        length++;
    }
  }

  function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
  }
}