pragma circom 2.1.5;

include "../../circuits/comparators.circom";
include "../../circuits/tags-managing.circom";

template A(){
    signal input in[254];
    component sign = Sign();
    sign.in <== BinaryCheckArray(254)(in);
    signal output {binary} out <== sign.sign;

}

component main = A();
