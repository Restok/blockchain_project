import { ethers } from "hardhat";
import { Tick, Groth16Verifier } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
const { buildPoseidon } = require("circomlibjs");
import * as fs from "fs";

// Import the snarkjs library for proof generation
const snarkjs = require("snarkjs");

async function main() {
  let tick: Tick;
  let verifier: Groth16Verifier;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;

  [owner, user] = await ethers.getSigners();
  const poseidon = await buildPoseidon();

  // Deploy the Groth16Verifier contract
  const Groth16VerifierFactory = await ethers.getContractFactory(
    "Groth16Verifier"
  );
  verifier = await Groth16VerifierFactory.deploy();
  await verifier.waitForDeployment();
  console.log("Groth16Verifier deployed to:", await verifier.getAddress());

  // Deploy the Tick contract
  const TickFactory = await ethers.getContractFactory("Tick");
  tick = await TickFactory.deploy(
    await owner.getAddress(),
    await verifier.getAddress()
  );
  await tick.waitForDeployment();
  console.log("Tick contract deployed to:", await tick.getAddress());

  // Mint a new token
  const tokenP = 100; // 50% chance of increment
  const updateInterval = 1; //
  const incrementAmount = 100;
  await tick.safeMint(user.address, tokenP, updateInterval, incrementAmount);
  const tokenId = 0; // First token minted
  // Wait for 1 second
  await new Promise((resolve) => setTimeout(resolve, 1000));
  await tick.updateTokenValue(tokenId);
  // Get the current token value hash
  // Prepare input for the circuit
  const threshold = 0;
  const tokenValue = await tick.tokenValue(tokenId);
  console.log("Token value:", tokenValue.toString());
  let tokenValueHash = poseidon([BigInt(tokenId), BigInt(tokenValue)]);
  tokenValueHash = poseidon.F.toString(tokenValueHash);
  const input = {
    threshold: threshold,
    tokenValueHash: tokenValueHash,
    tokenId: tokenId,
    tokenValue: tokenValue.toString(),
  };

  console.time("Proof Generation");
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    "build/tickValueProof_js/tickValueProof.wasm",
    "keys/tickValueProof_final.zkey"
  );
  // Convert the data into Solidity calldata that can be sent as a transaction
  const calldataBlob = await snarkjs.groth16.exportSolidityCallData(
    proof,
    publicSignals
  );

  const argv = calldataBlob
    .replace(/["[\]\s]/g, "")
    .split(",")
    .map((x: string) => BigInt(x).toString());

  const a = [argv[0], argv[1]];
  const b = [
    [argv[2], argv[3]],
    [argv[4], argv[5]],
  ];
  const c = [argv[6], argv[7]];
  const Input = argv.slice(8);
  console.timeEnd("Proof Generation");

  // Time the proof verification
  console.time("Proof Verification");
  const isValid = await tick.submitProof(a, b, c, Input);
  console.log("Proof is valid:", isValid);
  console.timeEnd("Proof Verification");

  console.log("Proof is valid:", isValid);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
