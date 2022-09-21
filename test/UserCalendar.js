const { ethers } = require("hardhat");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("UserCalendar Test", function () {
  let deployer, users;

  before(async function() {
    [deployer, u1, u2, u3, u4] = await ethers.getSigners();
    users = [u1.address, u2.address, u3.address, u4.address];

    const CommunityTracker = await ethers.getContractFactory("CommunityTracker");
    this.tracker = await CommunityTracker.deploy();
    await this.tracker.deployed();

    const UserCalendar = await ethers.getContractFactory("UserCalendar");
    this.userCal = await UserCalendar.deploy(this.tracker.address);
    await this.userCal.deployed();

    // set availability
    let end = 2100;
    for (let i=0; i<7; i++) {
      this.userCal.setAvailability(i, 0800, end + (i*25));
    }
  });

  it("read availability", async function(){
    const schedule = await this.userCal.readAvailability();
    // console.log(schedule);
    expect(schedule.length).to.equal(7);
  });

  it("set and check UTC", async function (){
    this.userCal.createUtc(8);
    expect(await this.userCal.getUtc()).to.equal("8");
  });

  it("return current time based on UTC zone", async function() {
    this.userCal.createUtc(8);
    const now = Math.floor(new Date().getTime() / 1000) + (8*60*60);
    const time = (Number(await this.userCal.currentTime()) + Number(await this.userCal.getUtc()));
    // console.log(`${now}\n${time}`)
    expect((time >= now && time-25 <= now)).to.equal(true);
  });

  it("set and check rate", async function (){
    this.userCal.createRate(5);
    expect(await this.userCal.getRate()).to.equal("5");
  });

  it("create 3 appointments and read list", async function (){
    this.userCal.createAppointment(
      "initial meet",
      "20220925",
      0,
      users[0],
      1000,
      4
    );
    this.userCal.createAppointment(
      "second meet",
      "20220926",
      1,
      users[2],
      1300,
      4
    );
    this.userCal.createAppointment(
      "third meet",
      "20220924",
      6,
      users[1],
      1500,
      3
    );

    const apptList = await this.userCal.readAppointments();
    // console.log(apptList);
    expect(apptList.length).to.equal(3);
  });

  it("delete 2nd appointment and read list", async function() {
    const apptID = 2;
    await this.userCal.deleteAppointment(apptID);

    const apptList = await this.userCal.readAppointments();
    // console.log(apptList);
    expect(apptList[apptID-1].id).to.equal(0);
  });

  it("create 2/3 appointments to manage schedule conflict and sort", async function (){
    this.userCal.createAppointment(
      "fifth meet",
      "20220927",
      2,
      users[2],
      0900,
      4
    );
    this.userCal.createAppointment(
      "fourth meet",
      "20220927",
      2,
      users[0],
      0800,
      4
    );
    this.userCal.createAppointment(
      "sixth meet",
      "20220927",
      2,
      users[1],
      0930,
      3
    );

    const apptList = await this.userCal.readAppointments();
    // console.log(apptList);
    expect(apptList.length).to.equal(5);
  });

  it("create appointments only within availability", async function (){
    this.userCal.createAppointment(
      "seventh meet",
      "20220928",
      3,
      users[0],
      0800,
      4
    );
    this.userCal.createAppointment(
      "eighth meet",
      "20220929",
      4,
      users[0],
      0600,
      4
    );

    const apptList = await this.userCal.readAppointments();
    // console.log(apptList);
    expect(apptList.length).to.equal(6);
  });

  it("sort appointments in order of date", async function (){
    await this.userCal.sortAppointments();
    const apptList = await this.userCal.readAppointments();
    console.log(apptList);
  })
});
