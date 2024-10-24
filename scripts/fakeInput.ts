const { buildPoseidon } = require("circomlibjs");
const fs = require("fs");

async function generateInputs(threshold) {
  const poseidon = await buildPoseidon();

  // Generate a random token ID (assuming uint256)
  const tokenId = BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER));

  // Generate a random token value that's greater than the threshold
  const tokenValue =
    BigInt(threshold) + BigInt(Math.floor(Math.random() * 1000)) + 1n;

  // Calculate the Poseidon hash of tokenId and tokenValue
  const hash = poseidon([tokenId, tokenValue]);
  const tokenValueHash = poseidon.F.toString(hash);

  const input = {
    threshold: threshold.toString(),
    tokenValueHash: tokenValueHash,
    tokenId: tokenId.toString(),
    tokenValue: tokenValue.toString(),
  };

  // Write the input to a JSON file
  fs.writeFileSync("./circuit/input.json", JSON.stringify(input, null, 2));

  console.log("Input file generated: ./circuit/input.json");
  console.log("Inputs:", input);
}

// Usage: node generateInputs.js <threshold>
const threshold = process.argv[2] || "1000";
generateInputs(BigInt(threshold));
