pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template TickValueProof() {
    // Public inputs
    signal input publicOwnerAddress;
    signal input tokenId;
    signal input threshold;

    // Private inputs
    signal input privateKey;
    signal input tokenValue;

    // Intermediate signals
    signal calculatedAddress;

    // 1. Prove ownership
    // Hash the private key to get the public address
    component hasher = Poseidon(1);
    hasher.inputs[0] <== privateKey;
    calculatedAddress <== hasher.out;

    // Check if calculated address matches the public owner address
    calculatedAddress === publicOwnerAddress;

    // 2. Prove token value is above threshold
    component greaterThan = GreaterThan(252);
    greaterThan.in[0] <== tokenValue;
    greaterThan.in[1] <== threshold;
    greaterThan.out === 1;
}

component main = TickValueProof();