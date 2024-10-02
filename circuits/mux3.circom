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

// The templates and functions in this file are general and work for any prime field

/*

*** MultiMux3(n): template that implements a multiplexer 8-to-1 between eight inputs of n elements
    - If s == 0 then out = c[0]
    - If s == 1 then out = c[1]
       .
       .
       .
       
    - If s == 6 then out = c[6]
    - If s == 7 then out = c[7]
    
        - Inputs: s[3] -> binary values, selector
                          requires tag binary
                  c[n][8] -> eight arrays of n elements that correspond to the inputs of the mux: c[i][0] => first input, c[i][1] => second input, ... 
        - Output: out[n] -> array of n elements, it takes the value c[i][0] if s == [0, 0, 0], c[i][1] if s == [1, 0, 0], ... , c[i][7] if s == [1, 1, 1]
        
    Example: MultiMux3(2)([[1, 2, 4, 1, 1, 6, 7, 3], [3, 1, 3, 1, 4, 6, 6, 2]], [1, 0 , 1]) = [6, 6]

 */

template MultiMux3(n) {
    input signal c[n][8];  // Constants
    input signal {binary} s[3];   // Selector
    output signal out[n];

    signal a210[n];
    signal a21[n];
    signal a20[n];
    signal a2[n];

    signal a10[n];
    signal a1[n];
    signal a0[n];
    signal a[n];

    // 4 constrains for the intermediary variables
    signal  s10;
    s10 <== s[1] * s[0];

    for (var i=0; i<n; i++) {

         a210[i] <==  ( c[i][ 7]-c[i][ 6]-c[i][ 5]+c[i][ 4] - c[i][ 3]+c[i][ 2]+c[i][ 1]-c[i][ 0] ) * s10;
          a21[i] <==  ( c[i][ 6]-c[i][ 4]-c[i][ 2]+c[i][ 0] ) * s[1];
          a20[i] <==  ( c[i][ 5]-c[i][ 4]-c[i][ 1]+c[i][ 0] ) * s[0];
           a2[i] <==  ( c[i][ 4]-c[i][ 0] );

          a10[i] <==  ( c[i][ 3]-c[i][ 2]-c[i][ 1]+c[i][ 0] ) * s10;
           a1[i] <==  ( c[i][ 2]-c[i][ 0] ) * s[1];
           a0[i] <==  ( c[i][ 1]-c[i][ 0] ) * s[0];
            a[i] <==  ( c[i][ 0] );

          out[i] <== ( a210[i] + a21[i] + a20[i] + a2[i] ) * s[2] +
                     (  a10[i] +  a1[i] +  a0[i] +  a[i] );

    }
}


/*

*** Mux3(): template that implements a multiplexer 8-to-1 
    - If s == 0 then out = c[0]
    - If s == 1 then out = c[1]
      . 
      .
      .
      
    - If s == 6 then out = c[6]
    - If s == 7 then out = c[7]

        - Inputs: s[3] -> binary values, selector
                          requires tag binary
                  c[8] -> eight elements that correspond to the inputs of the mux: c[0] => first input, c[1] => second input, ...
        - Output: out -> field element, it takes the value c[0] if s == [0, 0, 0], c[1] if s == [1, 0, 0], . . ., c[7] if s == [1, 1, 1] 
        
    Example: Mux3()([1, 5, 4, 2, 6, 3, 1, 5], [0, 1, 1]] = 1

 */

template Mux3() {
    var i;
    input signal c[8];  // Constants
    input signal {binary} s[3];   // Selector
    output signal out;

    component mux = MultiMux3(1);

    for (i=0; i<8; i++) {
        mux.c[0][i] <== c[i];
    }

    for (i=0; i<3; i++) {
      s[i] ==> mux.s[i];
    }

    mux.out[0] ==> out;
}
