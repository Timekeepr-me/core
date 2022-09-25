require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  solidity: '0.8.13',
  networks: {
    // mumbai: {
    //   url: process.env.MUMBAI_URL,
    //   accounts: [process.env.PRI_KEY]
    // }
  }
};