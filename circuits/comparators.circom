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

include "bitify.circom";
include "binsum.circom";
include "gates.circom";
include "buses.circom";

// The templates and functions of this file only work for any prime field


/*
*** IsZero(): template that receives an input in representing a field value and returns 1 if the input value is zero, 0 otherwise.
        - Inputs: in -> field value
        - Outputs: out -> in == 0
                          satisfies tag binary
         
    Example: IsZero()(5) = 0, IsZero()(0) = 0
          
*/

template IsZero() {
    input signal in;
    output signal {binary} out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}



/*
*** IsEqual(): template that receives two inputs in[0] and in[1] representing field values and returns 1 if in[0] == in[1], 0 otherwise.
        - Inputs: in[2] -> array of 2 field values
        - Outputs: out -> in[0] == in[1]
                          satisfies tag binary
         
    Example: IsEqual()([5, 2]) = 0, IsZero()([2, 2]) = 0
          
*/

template IsEqual() {
    input signal in[2];
    output signal {binary} out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}


/*
*** ForceEqualIfEnabled(): template that receives two inputs in[0] and in[1] representing field values and checks that in[0] == in[1] in case enabled == 1
        - Inputs: in[2] -> array of 2 field values
                  enabled -> binary value
                             requires tag binary
        - Outputs: None
         
    Example: ForceEqualIfEnabled()([5, 2], 1) is not satisfiable as in[0] != in[1] and enabled = 1
          
*/

template ForceEqualIfEnabled() {
    input signal {binary} enabled;
    input signal in[2];

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    (1 - isz.out)*enabled === 0;
}



/*

*** LessThan(n): template that receives two inputs in[0] and in[1] representing field values and returns 1 if in[0] < in[1], 0 otherwise.
        - Inputs: in[2] -> array of 2 field values
                           requires tag maxbit with in.maxbit <= n
        - Outputs: out -> in[0] < in[1]
                          satisfies tag binary
         
    Example: LessThan()([5, 2]) = 0, LessThan()([1, 2]) = 1
          
*/

template LessThan(n) {
    assert(n <= maxbits()-2);
    input signal {maxbit} in[2];
    output signal {binary} out;
    
    assert(in.maxbit <= n);

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.out[n];
}


/*

*** LessEqThan(n): template that receives two inputs in[0] and in[1] representing field values and returns 1 if in[0] <= in[1], 0 otherwise.
        - Inputs: in[2] -> array of 2 field values
                           requires tag maxbit with in.maxbit <= n
        - Outputs: out -> in[0] <= in[1]
                          satisfies tag binary
         
    Example: LessEqThan()([5, 2]) = 0, LessEqThan()([2, 2]) = 1
          
*/

template LessEqThan(n){
    input signal {maxbit} in[2];
    output signal {binary} out;
    assert(in.maxbit <= n);

    component gt = GreaterThan(n);
    gt.in <== in;
    
    component nt = NOT();
    nt.in <== gt.out;
    nt.out ==> out;

}


/*

*** GreaterThan(n): template that receives two inputs in[0] and in[1] representing field values and returns 1 if in[0] > in[1], 0 otherwise.
        - Inputs: in[2] -> array of 2 field values
                           requires tag maxbit with in.maxbit <= n
        - Outputs: out -> in[0] > in[1]
                          satisfies tag binary
         
    Example: GreaterThan()([5, 2]) = 1, GreaterThan()([2, 2]) = 0
          
*/


template GreaterThan(n) {
    input signal {maxbit} in[2];
    output signal {binary} out;
    
    assert(in.maxbit <= n);

    component lt = LessThan(n);

    lt.in[0] <== in[1];
    lt.in[1] <== in[0];
    lt.out ==> out;
}



/*

*** GreaterEqThan(n): template that receives two inputs in[0] and in[1] representing field values and returns 1 if in[0] >= in[1], 0 otherwise.
        - Inputs: in[2] -> array of 2 field values
                           requires tag maxbit with in.maxbit <= n
        - Outputs: out -> in[0] >= in[1]
                          satisfies tag binary
         
    Example: GreterEqThan()([5, 2]) = 1, GreaterEqThan()([2, 2]) = 1
          
*/

template GreaterEqThan(n) {
    input signal {maxbit} in[2];
    output signal {binary} out;
    
    assert(in.maxbit <= n);

    component gt = LessThan(n);
    gt.in <== in;
    
    component nt = NOT();
    nt.in <== gt.out;
    nt.out ==> out;
}


/*
*** Sign(): template that receives an input in representing a value in binary using maxbits() bits and checks if the value is positive or negative. We consider a number positive in case in <= p \ 2 and negative otherwise 
        - Inputs: in[maxbits()] -> array of maxbits() bits
                             requires tag binary
        - Outputs: sign -> 0 in case in <= prime \ 2, 1 otherwise
                           satisfies tag binary
         
          
*/

template Sign() {
    input signal {binary} in[maxbits()];
    output signal {binary} sign;

    component comp = CompConstant(- 1 \ 2);

    var i;
    
    comp.in <== in;

    sign <== comp.out;
}



/*
*** CompConstant(ct): template that receives an input in representing a value in binary using maxbits() bits and checks if its value is greater than the constant value ct given as a parameter
        - Inputs: in[maxbits()] -> array of maxbits() bits
                             requires tag binary
        - Outputs: out -> binary value, out = in > ct
                          satisfies tag binary
 
    Example: CompConstant(10)([0, ..., 0]) = 0, CompConstant(10)([1, ..., 1]) = 1              
          
*/

template CompConstant(ct) {
    input signal {binary} in[254];
    output signal {binary} out;

    signal parts[127];
    signal sout;

    var clsb;
    var cmsb;
    var slsb;
    var smsb;

    var sum=0;

    var b = (1 << 128) -1;
    var a = 1;
    var e = 1;
    var i;

    for (i=0;i<127; i++) {
        clsb = (ct >> (i*2)) & 1;
        cmsb = (ct >> (i*2+1)) & 1;
        slsb = in[i*2];
        smsb = in[i*2+1];

        if ((cmsb==0)&&(clsb==0)) {
            parts[i] <== -b*smsb*slsb + b*smsb + b*slsb;
        } else if ((cmsb==0)&&(clsb==1)) {
            parts[i] <== a*smsb*slsb - a*slsb + b*smsb - a*smsb + a;
        } else if ((cmsb==1)&&(clsb==0)) {
            parts[i] <== b*smsb*slsb - a*smsb + a;
        } else {
            parts[i] <== -a*smsb*slsb + a;
        }

        sum = sum + parts[i];

        b = b -e;
        a = a +e;
        e = e*2;
    }

    sout <== sum;

    component num2bits = Num2Bits(135);

    num2bits.in <== sout;

    out <== num2bits.out[127];
}

template CompConstant_new(n,ct) {
    assert(n <= nbits(ct));
    input signal {binary} in[n];
    output signal {binary} out;

    signal {binary} res[n];
    if (ct & 1 == 0) {
        res[0] <== in[0];
    } else {
        res[0] <== 0;
    }
    for (var i=1; i < n; i++) {
        // re[i-1] says if in[0..i-1] > ct[0..i-1] (upto bit i-1)
        if ((ct >> i) & 1 == 0) {
            res[i] <== OR()(res[i-1],in[i]);
        } else {
            res[i] <== AND()(res[i-1],in[i]);
	}
    }
    out <== res[n-1];
}    

