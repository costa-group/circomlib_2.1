pragma circom 2.1.5;

include "../../circuits/eddsapedersen.circom";
include "../../circuits/tags-managing.circom";


template A(n){
    input signal msg[n];

    input signal A[256];
    input signal R8[256];
    input signal S[256];

    signal {binary} msg_aux[n] <==  BinaryCheckArray(n)(msg);
    signal {binary} A_aux[256] <==  BinaryCheckArray(256)(A);
    signal {binary} R8_aux[256] <==  BinaryCheckArray(256)(R8);
    signal {binary} S_aux[256] <==  BinaryCheckArray(256)(S);
    
    EdDSAPedersenVerifier(n)(msg_aux, A_aux, R8_aux, S_aux);

}

component main = A(80);
