pragma circom 2.1.5;

include "../../circuits/mux1.circom";
include "../../circuits/bitify.circom";


template Constants() {
    var i;
    signal output out[2];

    out[0] <== 37;
    out[1] <== 47;
}

template Main() {
    signal input selector;//private
    signal output out;

    component mux = Mux1();
    component n2b = Num2Bits(1);
    component cst = Constants();

    selector ==> n2b.in;
    n2b.out[0] ==> mux.s;
    cst.out ==> mux.c;

    mux.out ==> out;
}

component main = Main();
