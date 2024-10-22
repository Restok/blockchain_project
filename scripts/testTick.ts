import { ethers } from "hardhat";
import { Tick } from "../typechain-types";

async function main() {
  console.log("Starting script...");

  try {
    // Deploy the contract
    console.log("Deploying Tick contract...");
    const Tick = await ethers.getContractFactory("Tick");
    const tick = (await Tick.deploy(
      await (await ethers.getSigners())[0].getAddress(),
      50
    )) as Tick;
    await tick.waitForDeployment();
    console.log("Tick deployed to:", await tick.getAddress());

    // Mint a token
    console.log("Minting a token...");
    const mintTx = await tick.safeMint(
      await (await ethers.getSigners())[0].getAddress(),
      50,
      1,
      ethers.parseEther("0.1")
    );
    await mintTx.wait();
    console.log("Token minted");

    // Update value every second for 10 seconds
    console.log("Updating token value...");
    for (let i = 0; i < 10; i++) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      const updateTx = await tick.updateValue(0);
      await updateTx.wait();
      const value = await tick.tokenValue(0);
      console.log(
        `Token value after ${i + 1} seconds:`,
        ethers.formatEther(value)
      );
    }
  } catch (error) {
    console.error("An error occurred:", error);
  }

  console.log("Script finished.");
}

main();
