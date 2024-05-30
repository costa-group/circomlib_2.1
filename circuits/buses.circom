pragma circom 2.1.5;


bus BinaryNumber(n) {
    signal {binary} bits[n];
}


bus Point(){
    signal x;
    signal y;
}


bus BinaryPoint(n) {
    BinaryNumber(n) binY;
    signal {binary} signX;
}
