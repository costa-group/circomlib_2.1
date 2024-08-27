pragma circom 2.1.5;

include "../../circuits/montgomery.circom";

template Main(){
    Point input a;
    Point output out;
    out <== MontgomeryDouble()(MontgomeryBabyCheck()(a));
}


component main = Main();
