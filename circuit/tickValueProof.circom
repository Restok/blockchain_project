pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template TickValueProof() {
    // Public inputs
    signal input threshold;
    signal input tokenValueHash;

    // Private inputs
    signal input tokenId;
    signal input tokenValue;

    // Hash the tokenId and tokenValue
    component hasher = Poseidon(2);
    hasher.inputs[0] <== tokenId;
    hasher.inputs[1] <== tokenValue;

    component greaterThan = GreaterThan(252);
    greaterThan.in[0] <== tokenValue;
    greaterThan.in[1] <== threshold;

    signal output isValid;
    component equalityCheck = IsEqual();
    equalityCheck.in[0] <== hasher.out;
    equalityCheck.in[1] <== tokenValueHash;
    isValid <== greaterThan.out * equalityCheck.out;
}

component main = TickValueProof();