pragma circom 2.1.5;
include "../../circuits/babyjub.circom";

template Main(){
    Point input a;
    Point input b;
    Point output out;
    out <== BabyAdd()(BabyCheck()(a), BabyCheck()(b));
}


component main = Main();
