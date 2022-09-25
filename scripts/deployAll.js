const hre = require("hardhat");
const { Framework } = require("@superfluid-finance/sdk-core");
require('dotenv').config();

/**
 * @dev npx hardhat run scripts/deployAll.js --network mumbai
 */

const deployerAddress = process.env.PUB_KEY;
const environment = process.env.ENVIRONMENT;

async function main() {
  const CommunityTracker = await ethers.getContractFactory("CommunityTracker");
  this.tracker = await CommunityTracker.deploy(deployerAddress);
  await this.tracker.deployed();

  const MoneyRouter = await ethers.getContractFactory("MoneyRouter");
  this.router = await MoneyRouter.deploy();
  await this.router.deployed();

  const UserCalendar = await ethers.getContractFactory("UserCalendar");
  this.userCal = await UserCalendar.deploy();
  await this.userCal.deployed();

  const CalendarFactory = await ethers.getContractFactory("CalendarFactory");
  this.factory = await CalendarFactory.deploy(deployerAddress);
  await this.factory.deployed();

  await this.factory.setBases(this.userCal.address, this.router.address, this.tracker.address);
  
  console.log('bases');
  console.log(await this.factory.getBases());

  console.log(`
<<<<<<< HEAD
  Deployer Address: ${deployerAddress}\n
  CommunityTracker: ${this.tracker.address}\n
  [base] MoneyRouter: ${this.router.address}\n
  [base] UserCalendar: ${this.userCal.address}\n
  CalendarFactory: ${this.factory.address}\n`);

  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.MUMBAI_URL);

  const sf = await Framework.create({
    chainId: (await provider.getNetwork()).chainId,
    provider,
    customSubgraphQueriesEndpoint: "",
    dataMode: "WEB3_ONLY"
  });

  const userName = "Jason";

  await this.factory.createUserCal(userName, sf.settings.config.hostAddress);

  console.log(await this.factory.getAllUserCalendarClones());
  console.log(await this.factory.getMoneyRouterClones());
}
=======
    Deployer Address: ${deployerAddress}\n
    CommunityTracker: ${this.tracker.address}\n
    [base] UserCalendar: ${this.userCal.address}\n
    CalendarFactory: ${this.factory.address}\n`);
  }
>>>>>>> 741e75b295a05e4fcc6fa9ec59e903f622ead80a

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/**
  Deployer Address: 0x1A4B691738C9c8Db8f2EDf0b9207f6acb24ADF07

  CommunityTracker: 0x1ee2fCCce7494aB4FC0AA25ddd5080B87a289953

  [base] MoneyRouter: 0x21fd70A9A629a05f82e5873773bfeD610d9027CD

  [base] UserCalendar: 0x3B3cf798496F05dbcD798116157D87965B55AE60

  CalendarFactory: 0xd59DB211Cb835DdC75D204682c59cE67c159c40E
 */