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

include "../mux4.circom";
include "escalarmulw4table.circom";
include "../babyjub.circom";
include "../buses.circom";


// The templates and functions of this file only work for finite field F_p = bn128,
// with the prime number p = 21888242871839275222246405745257275088548364400416034343698204186575808495617.


/*
*** EscalarMulWindow(base, k): template that receives two inputs in[2]  and a sel[4] representing a value of the prime field and a binary value respectively, and returns the point out according to the scheme below. This circuit is used in order to multiply a curve of the BabyJub curve by a escalar (val * base with base in the curve). The parameter k indicates the number of window in the protocol 
        - Inputs: in[2] -> field values
                  sel[4] -> binary values
                            requires tag binary
        - Outputs: out[2] -> field values
    
  Scheme:
                                                        ┏━━━━━━━━━━━┓
                                                        ┃           ┃
                                                        ┃           ┃
  (inx, iny) ══════════════════════════════════════════▶┃ EC Point  ┃
                                                        ┃           ╠═▶ (outx, outy)
                                                    ╔══▶┃   Adder   ┃
                                                    ║   ┃           ┃
                                                    ║   ┃           ┃
                                                    ║   ┃           ┃
       ┏━━━━━━━━━━━┓                ┏━━━━━━━━━━━━┓  ║   ┗━━━━━━━━━━━┛
       ┃           ┃                ┃            ┃  ║
       ┃           ┃                ┃            ┃  ║
       ┃           ╠═══(p0x,p0y)═══▶┃            ┃  ║
       ┃           ╠═══(p1x,p1y)═══▶┃            ┃  ║
       ┃           ╠═══(p2x,p2y)═══▶┃            ┃  ║
       ┃           ╠═══(p3x,p3y)═══▶┃            ┃  ║
       ┃           ╠═══(p4x,p4y)═══▶┃            ┃  ║
       ┃           ╠═══(p5x,p5y)═══▶┃            ┃  ║
       ┃           ╠═══(p6x,p6y)═══▶┃            ┃  ║
       ┃ Constant  ╠═══(p7x,p7y)═══▶┃            ┃  ║
       ┃  Points   ┃                ┃    Mux4    ╠══╝
       ┃           ╠═══(p8x,p8y)═══▶┃            ┃
       ┃           ╠═══(p9x,p9y)═══▶┃            ┃
       ┃           ╠══(p10x,p10y)══▶┃            ┃
       ┃           ╠══(p11x,p11y)══▶┃            ┃
       ┃           ╠══(p12x,p12y)══▶┃            ┃
       ┃           ╠══(p13x,p13y)══▶┃            ┃
       ┃           ╠══(p14x,p14y)══▶┃            ┃
       ┃           ╠══(p15x,p15y)══▶┃            ┃
       ┃           ┃                ┃            ┃
       ┃           ┃                ┃            ┃
       ┗━━━━━━━━━━━┛                ┗━━━━━━━━━━━━┛
                                      ▲  ▲  ▲  ▲
                                      │  │  │  │
  s0 ─────────────────────────────────┘  │  │  │
  s1 ────────────────────────────────────┘  │  │
  s2 ───────────────────────────────────────┘  │
  s3 ──────────────────────────────────────────┘


 */

template EscalarMulWindow(base, k) {

    input Point {babyedwards} pin;
    input signal {binary} sel[4];
    output Point {babyedwards} pout;

    var table[16][2];
    component mux;
    component adder;

    var i;

    table = EscalarMulW4Table(base, k);
    mux = MultiMux4(2);
    adder = BabyAdd();

    sel ==> mux.s;

    for (i=0; i<16; i++) {
        mux.c[0][i] <== table[i][0];
        mux.c[1][i] <== table[i][1];
    }

    pin ==> adder.pin1;
    Point {babyedwards} aux;
    aux.x <== mux.out[0];
    aux.y <== mux.out[1];
    aux ==> adder.pin2;
    
    adder.pout ==> pout;
}




/*

*** EscalarMul(n, base): template that receives two inputs inp[2] and in[n] representing a point of BabyJub curve in its Edwards representation and the binary representation of a field value k respectively, and returns the value out according to the scheme below. This circuit is used in order to multiply a point of the BabyJub curve by a escalar (k * inp with inp in the curve). The input in is the binary representation of the value k and in is the point of the curve.
        - Inputs: in[n] -> binary representation of k
                           requires tag binary
                  inp[2] -> input curve point to be multiplied
        - Outputs: out[2] -> output curve point k * inp
    
  Scheme:

                ┏━━━━━━━━━┓      ┏━━━━━━━━━┓                            ┏━━━━━━━━━━━━━━━━━━━┓
                ┃         ┃      ┃         ┃                            ┃                   ┃
      inp  ════▶┃Window(0)┃═════▶┃Window(1)┃════════  . . . . ═════════▶┃ Window(nBlocks-1) ┃═════▶ out
                ┃         ┃      ┃         ┃                            ┃                   ┃
                ┗━━━━━━━━━┛      ┗━━━━━━━━━┛                            ┗━━━━━━━━━━━━━━━━━━━┛
                  ▲ ▲ ▲ ▲          ▲ ▲ ▲ ▲                                    ▲ ▲ ▲ ▲
    in[0]─────────┘ │ │ │          │ │ │ │                                    │ │ │ │
    in[1]───────────┘ │ │          │ │ │ │                                    │ │ │ │
    in[2]─────────────┘ │          │ │ │ │                                    │ │ 0 0
    in[3]───────────────┘          │ │ │ │                                    │ │
    in[4]──────────────────────────┘ │ │ │                                    │ │
    in[5]────────────────────────────┘ │ │                                    │ │
    in[6]──────────────────────────────┘ │                                    │ │
    in[7]────────────────────────────────┘                                    │ │
        .                                                                     │ │
        .                                                                     │ │
  in[n-2]─────────────────────────────────────────────────────────────────────┘ │
  in[n-1]───────────────────────────────────────────────────────────────────────┘

 */

template EscalarMul(n, base) {
    input signal {binary} in[n];
    input Point {babyedwards} pin;   // Point input to be added
    output Point {babyedwards} pout;

    var nBlocks = ((n-1)>>2)+1;
    var i;
    var j;

    signal {binary} aux_0 <== 0;
    component windows[nBlocks];

    // Construct the windows
    for (i=0; i<nBlocks; i++) {
      windows[i] = EscalarMulWindow(base, i);
    }

    // Connect the selectors
    for (i=0; i<nBlocks; i++) {
        for (j=0; j<4; j++) {
            if (i*4+j >= n) {
                windows[i].sel[j] <== aux_0;
            } else {
                windows[i].sel[j] <== in[i*4+j];
            }
        }
    }

    // Start with generator
    windows[0].pin <== pin;

    for(i=0; i<nBlocks-1; i++) {
        windows[i].pout ==> windows[i+1].pin;
    }

    windows[nBlocks-1].pout ==> pout;
}
