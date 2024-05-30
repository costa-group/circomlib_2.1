pragma circom 2.1.5;

include "../../circuits/montgomery.circom";

template Main(){
    Point input a;
    Point input b;
    Point output out;
    out <== MontgomeryAdd()(MontgomeryBabyCheck()(a), MontgomeryBabyCheck()(b));
}


component main = Main();
