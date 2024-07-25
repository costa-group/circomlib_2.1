pragma circom 2.1.5;
include "../../circuits/babyjub.circom";

template Main(){
    Point input a;
    Point input b;
    //Point output out <== BabyAdd()(BabyCheck()(a), BabyCheck()(b));
    Point {babyedwards} a_aux <== a;
    Point {babyedwards} b_aux <== b;
    Point output out <== BabyAdd()(a_aux, b_aux);
}


component main = Main();
