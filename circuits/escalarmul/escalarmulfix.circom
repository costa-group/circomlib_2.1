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

include "../mux3.circom";
include "../montgomery.circom";
include "../babyjub.circom";
include "../buses.circom";


// The templates and functions of this file only work for finite field F_p = bn128,
// with the prime number p = 21888242871839275222246405745257275088548364400416034343698204186575808495617.

/*

    The scalar is s = a0 + a1*2^3 + a2*2^6 + ...... + a81*2^243
    First We calculate Q = B + 2^3*B + 2^6*B + ......... + 2^246*B

    Then we calculate S1 = 2*2^246*B + (1 + a0)*B + (2^3 + a1)*B + .....+ (2^243 + a81)*B

    And Finaly we compute the result: RES = SQ - Q

    As you can see the input of the adders cannot be equal nor zero, except for the last
    substraction that it's done in montgomery.

    A good way to see it is that the accumulator input of the adder >= 2^247*B and the other input
    is the output of the windows that it's going to be <= 2^246*B
 */
 
 
/*

*** WindowMulFix(): template that given a point in Montgomery representation base and a binary input in, calculates:
        out = base + base*in[0] + 2*base*in[1] + 4*base*in[2]
        out8 = 8*base

    This circuit is used in order to multiply a fixed point of the BabyJub curve by a escalar (k * p with p a fixed point of the curve). 
        - Inputs: in[3] -> binary value
                         requires tag binary
                  base[2] -> input curve point in Montgomery representation
        - Outputs: out[2] -> output curve point in Montgomery representation
                   out8[2] -> output curve point in Montgomery representation
    
 */
 
template WindowMulFix() {
    input signal {binary} in[3];
    input Point {babymontgomery} base;
    output Point {babymontgomery} pout;
    output Point {babymontgomery} pout8;   // Returns 8*Base (To be linked)

    component mux = MultiMux3(2);

    mux.s[0] <== in[0];
    mux.s[1] <== in[1];
    mux.s[2] <== in[2];

    component dbl2 = MontgomeryDouble();
    component adr3 = MontgomeryAdd();
    component adr4 = MontgomeryAdd();
    component adr5 = MontgomeryAdd();
    component adr6 = MontgomeryAdd();
    component adr7 = MontgomeryAdd();
    component adr8 = MontgomeryAdd();

// in[0]  -> 1*BASE

    mux.c[0][0] <== base.x;
    mux.c[1][0] <== base.y;

// in[1] -> 2*BASE
    dbl2.pin <== base;
    mux.c[0][1] <== dbl2.pout.x;
    mux.c[1][1] <== dbl2.pout.y;

// in[2] -> 3*BASE
    adr3.pin1 <== base;
    adr3.pin2 <== dbl2.pout;
    mux.c[0][2] <== adr3.pout.x;
    mux.c[1][2] <== adr3.pout.y;

// in[3] -> 4*BASE
    adr4.pin1 <== base;
    adr4.pin2 <== adr3.pout;
    mux.c[0][3] <== adr4.pout.x;
    mux.c[1][3] <== adr4.pout.y;

// in[4] -> 5*BASE
    adr5.pin1 <== base;
    adr5.pin2 <== adr4.pout;
    mux.c[0][4] <== adr5.pout.x;
    mux.c[1][4] <== adr5.pout.y;

// in[5] -> 6*BASE
    adr6.pin1 <== base;
    adr6.pin2 <== adr5.pout;
    mux.c[0][5] <== adr6.pout.x;
    mux.c[1][5] <== adr6.pout.y;

// in[6] -> 7*BASE
    adr7.pin1 <== base;
    adr7.pin2 <== adr6.pout;
    mux.c[0][6] <== adr7.pout.x;
    mux.c[1][6] <== adr7.pout.y;

// in[7] -> 8*BASE
    adr8.pin1 <== base;
    adr8.pin2 <== adr7.pout;
    mux.c[0][7] <== adr8.pout.x;
    mux.c[1][7] <== adr8.pout.y;

    pout8 <== adr8.pout;

    pout.x <== mux.out[0];
    pout.y <== mux.out[1];
}


/*

*** SegmentMulFix(nWindows): template used to perform a segment of the multiplications needed to perform a multiplication of a scalar times a fix base (k * BASE). 
        - Inputs: e[3 * nWindows] -> binary representation of the scalar
                                     requires tag binary
                  base[2] -> input curve point in Edwards representation
        - Outputs: out[2] -> output curve point in Edwards representation
                   dbl[2] -> output curve point in Montgomery representation (to be linked to the next segment)
    
 */

template SegmentMulFix(nWindows) {
    input signal {binary} e[nWindows*3];
    input Point {babyedwards} base;
    output Point {babyedwards} pout;
    output Point {babymontgomery} dbl;

    var i;
    var j;

    // Convert the base to montgomery

    component e2m = Edwards2Montgomery();
    e2m.pin <== base;

    component windows[nWindows];
    component adders[nWindows];
    component cadders[nWindows];

    // In the last step we add an extra doubler so that numbers do not match.
    component dblLast = MontgomeryDouble();

    for (i=0; i<nWindows; i++) {
        windows[i] = WindowMulFix();
        cadders[i] = MontgomeryAdd();
        if (i==0) {
            windows[i].base <== e2m.pout;
            cadders[i].pin1 <== e2m.pout;
        } else {
            windows[i].base <== windows[i-1].pout8;
            cadders[i].pin1 <== cadders[i-1].pout;
        }
        for (j=0; j<3; j++) {
            windows[i].in[j] <== e[3*i+j];
        }
        if (i<nWindows-1) {
            cadders[i].pin2 <== windows[i].pout8;
        } else {
            dblLast.pin <== windows[i].pout8;
            cadders[i].pin2 <== dblLast.pout;
        }
    }

    for (i=0; i<nWindows; i++) {
        adders[i] = MontgomeryAdd();
        if (i==0) {
            adders[i].pin1 <== dblLast.pout;
        } else {
            adders[i].pin1 <== adders[i-1].pout;
        }
        adders[i].pin2 <== windows[i].pout;
    }

    component m2e = Montgomery2Edwards();
    component cm2e = Montgomery2Edwards();

    m2e.pin <== adders[nWindows-1].pout;
    cm2e.pin <== cadders[nWindows-1].pout;

    component cAdd = BabyAdd();
    cAdd.pin1 <== m2e.pout;
    
    Point {babyedwards} aux;
    aux.x <== -cm2e.pout.x;
    aux.y <== cm2e.pout.y;
    cAdd.pin2 <== aux;

    cAdd.pout ==> pout;

    windows[nWindows-1].pout8 ==> dbl;
}


/*

*** EscalarMulFix(n, BASE): template that does a multiplication of a scalar times a fixed point BASE. It receives a point in Edwards representation BASE and a binary input e representing a value k using n bits, and calculates the point k * p.
        - Inputs: e[n] -> binary representation of the scalar k
                          requires tag binary
        - Outputs: out[2] -> output curve point in Edwards representation out = k * BASE
    
 */
 
 
template EscalarMulFix(n, BASE) {
    input signal {binary} e[n];              // Input in binary format
    output Point {babyedwards} pout;           // Point (Twisted format)

    var nsegments = (n-1)\246 +1;       // 249 probably would work. But I'm not sure and for security I keep 246
    var nlastsegment = n - (nsegments-1)*249;

    component segments[nsegments];

    component m2e[nsegments-1];
    component adders[nsegments-1];
    
    Point {babyedwards} aux_base;
    aux_base.x <== BASE[0];
    aux_base.y <== BASE[1];

    var s;
    var i;
    var nseg;
    var nWindows;
    
    signal {binary} aux_0 <== 0;

    for (s=0; s<nsegments; s++) {

        nseg = (s < nsegments-1) ? 249 : nlastsegment;
        nWindows = ((nseg - 1)\3)+1;

        segments[s] = SegmentMulFix(nWindows);

        for (i=0; i<nseg; i++) {
            segments[s].e[i] <== e[s*249+i];
        }

        for (i = nseg; i<nWindows*3; i++) {
            segments[s].e[i] <== aux_0;
        }

        if (s==0) {
            segments[s].base <== aux_base;
        } else {
            m2e[s-1] = Montgomery2Edwards();
            adders[s-1] = BabyAdd();

            segments[s-1].dbl ==> m2e[s-1].pin;

            m2e[s-1].pout ==> segments[s].base;

            if (s==1) {
                segments[s-1].pout ==> adders[s-1].pin1;
            } else {
                adders[s-2].pout ==> adders[s-1].pin1;
            }
            segments[s].pout ==> adders[s-1].pin2;
        }
    }

    if (nsegments == 1) {
        segments[0].pout ==> pout;
    } else {
        adders[nsegments-2].pout ==> pout;
    }
}
