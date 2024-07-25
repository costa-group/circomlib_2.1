pragma circom 2.1.5;

include "../../circuits/montgomery.circom";

template Main(){
    Point input a;
    Point input b;
    Point output out;
    Point {babymontgomery} a_aux <== a;
    Point {babymontgomery} b_aux <== b;
    out <== MontgomeryAdd()(a_aux, b_aux);
}


component main = Main();
