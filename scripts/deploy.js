
const hre = require("hardhat");

async function main() {


  const NFTmarketplace = await hre.ethers.getContractFactory("NFTmarketplace");
  const NFTmarketplace = await Lock.deploy(NFTmarketplace.sol);

  await lock.deployed();

  console.log(
    `Lock with ${ethers.utils.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
