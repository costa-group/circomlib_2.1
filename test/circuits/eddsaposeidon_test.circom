pragma circom 2.1.5;

include "../../circuits/eddsaposeidon.circom";
include "../../circuits/tags-managing.circom";
include "../../circuits/babyjub.circom";

template A(){
    signal input enabled;
    Point input A; // point in Edwards representation

    signal input S;
    Point input R8; // point in Edwards representation

    signal input M; // mesage 
    
    signal enabled_aux <== BinaryCheck()(enabled);
    Point A_aux <== BabyCheck()(A);
    Point R8_aux <== BabyCheck()(R8);
    
    EdDSAPoseidonVerifier()(enabled_aux, A_aux, S, R8_aux, M);


}

component main = A();
