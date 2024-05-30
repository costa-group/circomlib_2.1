pragma circom 2.1.5;

include "../../circuits/mux2.circom";
include "../../circuits/bitify.circom";


template Constants() {
    var i;
    signal output out[4];

    out[0] <== 37;
    out[1] <== 47;
    out[2] <== 53;
    out[3] <== 71;
}

template Main() {
    signal input selector;//private
    signal output out;

    component mux = Mux2();
    component n2b = Num2Bits(2);
    component cst = Constants();

    selector ==> n2b.in;
    n2b.out.bits ==> mux.s;
    cst.out ==> mux.c;

    mux.out ==> out;
}

component main = Main();
