const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("CommunityTracker Test", function () {
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

    // set availabilities for multiple users
  });

  it("test", async function(){

  });
});