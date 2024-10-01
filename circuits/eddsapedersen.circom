/*
    Copyright 2018 0KIMS association.

    This file is part of circom (Zero Knowledge Circuit Compiler).

    circom is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    circom is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with circom. If not, see <https://www.gnu.org/licenses/>.
*/

pragma circom 2.1.5;

// The templates and functions of this file only work for prime field bn128 (21888242871839275222246405745257275088548364400416034343698204186575808495617)

include "comparators.circom";
include "pointbits.circom";
include "pedersen.circom";
include "escalarmul/escalarmulany.circom";
include "escalarmul/escalarmulfix.circom";

/*

*** EdDSAPedersenVerifier(n): template that implements the EdDSA verification protocol based on Pedersen hash for a message of size n. The circuit receives the message that we want to verify and the public and private keys (that are points of a curve in Edwards representation encoded using 256 bits) and checks if the message is correct.
        - Inputs: msg[n] -> msg encoded in bits
                            requires tag binary
                  A[256] -> encoding of a point of a curve in Edwards representation using 256 bits
                            requires tag binary
                  R8[256] -> encoding of a point of a curve in Edwards representation using 256 bits
                             requires tag binary
                  S[256] -> value of the subgroup generated by the prime 2736030358979909402780800718157159386076813972158567259200215660948447373041
                            requires tag binary
        - Outputs: None
*/


template EdDSAPedersenVerifier(n) {
    input signal {binary} msg[n];

    input BinaryPoint(254) A;
    input BinaryPoint(254) R8;
    input BinaryPoint(254) S;
    
    Point pA;
    Point pR8;


    var i;

// Ensure S<Subgroup Order

    component  compConstant = CompConstant(2736030358979909402780800718157159386076813972158567259200215660948447373040);

    S.binY ==> compConstant.in;
    compConstant.out === 0;
    S.signX === 0;

// Convert A to Field elements (And verify A)
    pA <== Bits2Point_Strict()(A);


// Convert R8 to Field elements (And verify R8)
    pR8 <== Bits2Point_Strict()(R8);

// Calculate the h = H(R,A, msg)

    component hash = Pedersen(510+n);

    for (i=0; i<254; i++) {
        hash.in[i] <== R8.binY[i];
    }
    hash.in[254] <== R8.signX;
    
    for (i=0; i<254; i++) {
        hash.in[255 + i] <== A.binY[i];
    }
    hash.in[509] <== A.signX;
    
    for (i=0; i<n; i++) {
        hash.in[510+i] <== msg[i];
    }

    component point2bitsH = Point2Bits_Strict();
    point2bitsH.pin <== hash.pout;

// Calculate second part of the right side:  right2 = h*8*A

    // Multiply by 8 by adding it 3 times.  This also ensure that the result is in
    // the subgroup.
    component dbl1 = BabyDbl();
    dbl1.pin <== pA;
    component dbl2 = BabyDbl();
    dbl2.pin <== dbl1.pout;
    component dbl3 = BabyDbl();
    dbl3.pin <== dbl2.pout;

    // We check that A is not zero.
    component isZero = IsZero();
    isZero.in <== dbl3.pin.x;
    isZero.out === 0;

    component mulAny = EscalarMulAny(255);
    for (i=0; i<254; i++) {
        mulAny.e[i] <== point2bitsH.out.binY[i];
    }
    mulAny.e[254] <== point2bitsH.out.signX;
    
    mulAny.pin <== dbl3.pout;

// Compute the right side: right =  R8 + right2

    component addRight = BabyAdd();
    addRight.pin1 <== pR8;
    addRight.pin2 <== mulAny.pout;

// Calculate left side of equation left = S*B8

    var BASE8[2] = [
        5299619240641551281634865583518297030282874472190772894086521144482721001553,
        16950150798460657717958625567821834550301663161624707787222815936182638968203
    ];
    component mulFix = EscalarMulFix(255, BASE8);
    for (i=0; i<254; i++) {
        mulFix.e[i] <== S.binY[i];
    }
    mulFix.e[254] <== S.signX;

// Do the comparation left == right

    mulFix.pout === addRight.pout;
}

