pragma circom 2.1.5;

include "../../circuits/montgomery.circom";
include "../../circuits/babyjub.circom";

template Main(){
    Point input a;
    Point output out;
    out <== Edwards2Montgomery()(BabyCheck()(a));
}


component main = Main();

