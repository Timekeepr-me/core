const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("CalendarFactory Test", function () {
  let deployer, users;

  before(async function() {
    [deployer, u1, u2, u3, u4] = await ethers.getSigners();
    signers = [u1, u2, u3, u4];
    users = [u1.address, u2.address, u3.address, u4.address];
    userNames = ["Samantha", "Jonny", "Alex", "Karen"];

    const CommunityTracker = await ethers.getContractFactory("CommunityTracker");
    this.tracker = await CommunityTracker.deploy(deployer.address);
    await this.tracker.deployed();

    const UserCalendar = await ethers.getContractFactory("UserCalendar");
    this.userCal = await UserCalendar.deploy();
    await this.userCal.deployed();

    const CalendarFactory = await ethers.getContractFactory("CalendarFactory");
    this.factory = await CalendarFactory.deploy(deployer.address);
    await this.factory.deployed();

    console.log(`\nCT: ${this.tracker.address}\nUC: ${this.userCal.address}\nCF: ${this.factory.address}`);

    this.factory.setBases(this.userCal.address, this.tracker.address);
  });

  it("create multiple userCalendars and initialize setup", async function(){
    for (let i=0; i<users.length; i++) {
      await this.factory.connect(signers[i]).createUserCal(userNames[i]);
    }
    const cloneList = await this.factory.getAllUserCalendarClones();
    console.log(cloneList);
    expect(cloneList.length).to.equal(4);
  });
});