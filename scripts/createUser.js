const hre = require("hardhat");
const { Framework } = require("@superfluid-finance/sdk-core");
require('dotenv').config();

/**
 * @dev npx hardhat run scripts/deployAll.js --network mumbai
 */

const deployerAddress = process.env.PUB_KEY;
const userName = "Jason";

async function main() {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.MUMBAI_URL);

  const sf = await Framework.create({
    chainId: (await provider.getNetwork()).chainId,
    provider,
    customSubgraphQueriesEndpoint: "",
    dataMode: "WEB3_ONLY"
  });

  await this.factory.createUserCal(userName, sf.settings.config.hostAddress);
  console.log(await this.factory.getAllUserCalendarClones());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
