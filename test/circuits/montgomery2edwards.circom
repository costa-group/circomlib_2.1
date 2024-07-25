pragma circom 2.1.5;

include "../../circuits/montgomery.circom";

template Main(){
    Point input a;
    Point output out;
    Point {babymontgomery} a_aux <== a;
    //out <== Montgomery2Edwards()(MontgomeryCheck()(a));
    out <== Montgomery2Edwards()(a_aux);
}


component main = Main();

