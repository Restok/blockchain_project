const snarkjs = require("snarkjs");
const fs = require("fs");

async function generateProof(
  privateKey,
  publicOwnerAddress,
  tokenId,
  tokenValue,
  threshold
) {
  // Load circuit
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    {
      privateKey: privateKey,
      publicOwnerAddress: publicOwnerAddress,
      tokenId: tokenId,
      tokenValue: tokenValue,
      threshold: threshold,
    },
    "tick_value_proof.wasm",
    "tick_value_proof_final.zkey"
  );

  // Write proof to file
  fs.writeFileSync("proof.json", JSON.stringify(proof, null, 1));
  fs.writeFileSync("public.json", JSON.stringify(publicSignals, null, 1));

  return { proof, publicSignals };
}

// // Example usage
// (async () => {
//   const privateKey = "0x1234..."; // Replace with actual private key
//   const publicOwnerAddress = "0x5678..."; // Replace with actual public address
//   const tokenId = "1";
//   const tokenValue = "1000";
//   const threshold = "500";

//   const { proof, publicSignals } = await generateProof(
//     privateKey,
//     publicOwnerAddress,
//     tokenId,
//     tokenValue,
//     threshold
//   );

//   console.log("Proof generated successfully!");
//   console.log("Proof:", proof);
//   console.log("Public Signals:", publicSignals);
// })();
