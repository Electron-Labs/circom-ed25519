pragma circom 2.0.0;

include "binsub.circom";
include "binadd.circom";
include "binmulfast.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "chunkedadd.circom";
include "chunkedsub.circom";
include "lt.circom";
include "utils.circom";

/*
                    ┌────────────┐
                    │            │
                    │            │
  ┌─────────┐       │   modulus  │        ┌─────────────────┐
  │ n wires ├──────▶│    25519   │───────▶│max(n, 255) wires│
  │(n < 255)│       │            │        │replicated input │
  └─────────┘       │            │        └─────────────────┘
                    └────────────┘

                            ┌───────────┐                                       
               ┌───────────▶│           ╠mod0═══╗                               
               │  ┌────────▶│           │.      ║                               
┌──────────┐   │  │         │   Mod2p   │.      ║                               
│          │   │  │         │           │.      ║                               
│          ├in0┘  │  ┌─────▶│           ╠mod254 ║                               
│          ├in1───┘  │      └───────────┘   ║   ║                               
│          │ .       │                      ║   ║                               
│          │ .       │                      ║   ║  ┌───────────┐    ┌─────────┐
│ n wires  ├in254────┘                      ║   ╚═▶│ a (n wire)│    │         │
│(n >= 255)│                                ╚═════▶│ b (n wire)│    │         │
│          │                                       │           ╠═══▶│  Mod2p  │
│          ├in255────┐                             │    Add    │    │         │
│          │ .       │                      ╔═════▶│           │    │         │
│          │ .       │                      ║   ╔═▶│ out (n+1) │    │         │
│          ├inN──┐   │      ┌───────────┐   ║   ║  └───────────┘    └─────────┘
│          │     │   └─────▶│ a (n wire)│   ║   ║                               
│          │     │          │ b (m wire)│   ║   ║                               
└──────────┘     └─────────▶│           │   ║   ║                               
┌──────────┐                │  Multiply │   ║   ║                               
│          ├const0─────────▶│           │   ║   ║                               
│   const  │ .      ┌──────▶│ out (m+n) │   ║   ║                               
│    19    │ .      │       └─╦──────╦──┘   ║   ║                               
│  5 wires ├const4──┘         ║  ..  ║      ║   ║                               
│          │                  ║      ║      ║   ║                               
└──────────┘                mult0 mult(m+n) ║   ║                               
                              ║      ║      ║   ║                               
                              ▼      ▼      ║   ║                               
                           ┌──────────────┐ ║   ║                               
                           │              ╠mod0 ║                               
                           │ Modulus25519 │.    ║                               
                           │  recursive   │.    ║                               
                           │   circuit    ╠mod254                               
                           └──────────────┘                              
*/

template ModulusWith25519(n) {
  signal input a[n];
  signal output out[255];
  var nineteen[5] = [1, 1, 0, 0, 1];
  var i;

  component mod2p;
  component mul;
  component mod;
  component adder;
  component mod2pfinal;
  if (n < 255) {
    for (i=0; i<n; i++) {
      out[i] <== a[i];
    }
    for (i=n; i<255; i++) {
      out[i] <== 0;
    }
  } else {
    mod2p = ModulusAgainst2P();
    for (i=0; i<255; i++) {
      mod2p.in[i] <== a[i];
    }
    mod2p.in[255] <== 0;

    mul = BinMulFast(n-255, 5);
    for(i=0; i<n-255; i++) {
      mul.in1[i] <== a[255+i];
    }
    for(i=0; i<5; i++) {
      mul.in2[i] <== nineteen[i];
    }
    mod = ModulusWith25519(n-255+5);
    for (i=0; i<n-255+5; i++) {
      mod.a[i] <== mul.out[i];
    }

    adder = BinAdd(255);
    for (i=0; i<255; i++) {
      adder.in[0][i] <== mod2p.out[i];
      adder.in[1][i] <== mod.out[i];
    }

    mod2pfinal = ModulusAgainst2P();
    for (i=0; i<256; i++) {
      mod2pfinal.in[i] <== adder.out[i];
    }

    for (i=0; i<255; i++) {
      out[i] <== mod2pfinal.out[i];
    }
  }
}

/*
                              ╔══════════~s255══════════╗                 
                              ║                         ║                 
                              ║                         ║                 
                              ║                         ║                 
                              ║                         ▼                 
  ┌────────┐              ┌───╩────┐               ┌──────────┐           
  │        │              │        │               │          │           
  │        ╠═════p0══════▶│        ╠═════s0═══════▶│          │           
  │        │      ◦       │        │      ◦        │          ╠══out0════▶
  │        │      ◦       │   b    │      ◦        │          ╠══out1════▶
  │        ╠════p254═════▶│        ╠════s254══════▶│          │    ◦      
  │2^255-19│    ══0══════▶│        │               │   Mux2   │    ◦      
  │        │              │sub(a-b)│               │          │    ◦      
  │        │    ┌────────▶│        │      ┌───────▶│          ╠═out254═══▶
  │        │    │      ◦  │        │      │    ◦   │          │           
  │        │    │      ◦  │   a    │      │    ◦   │          │           
  │        │    │ ┌──────▶│        │      │  ┌────▶│          │           
  │        │    │ │  ┌───▶│        │      │  │     │          │           
  └────────┘    │ │  │    └────────┘      │  │     └──────────┘           
                │ │  │                    │  │                            
                │ │  │                    │  │                            
in0─────────────┴─┼──┼────────────────────┘  │                            
                  │  │                       │                            
in254─────────────┴──┼───────────────────────┘                            
in255────────────────┘ 
*/

template ModulusAgainst2P() {
  signal input in[256];
  signal output out[255];
  var i;
  var p[255] = [1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1];

  component sub = BinSub(256);
  for (i=0; i<255; i++) {
    sub.in[0][i] <== in[i];
    sub.in[1][i] <== p[i];
  }
  sub.in[0][255] <== in[255];
  sub.in[1][255] <== 0;

  component mux = MultiMux1(255);
  for (i=0; i<255; i++) {
    mux.c[i][0] <== in[i];
    mux.c[i][1] <== sub.out[i];
  }

  mux.s <== 1 + sub.out[255] - 2*sub.out[255];
  for (i=0; i<255; i++) {
    out[i] <== mux.out[i];
  }
}

template ModulusWith252c(n) {
  signal input a[n];
  signal output out[253];
  var c[125] = [1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1,
   1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0,
   0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0,
   1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1,
   1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1];
  var q[253] = [1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1,
   1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0,
   0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0,
   1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1,
   1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];
  var i;

  component mul;
  component mod;
  component sub;
  component adder;
  component mod2pfinal;
  if (n < 253) {
    for (i=0; i<n; i++) {
      out[i] <== a[i];
    }
    for (i=n; i<253; i++) {
      out[i] <== 0;
    }
  } else {

    mul = BinMulFast(n-252, 125);
    for(i=0; i<n-252; i++) {
      mul.in1[i] <== a[252+i];
    }
    for(i=0; i<125; i++) {
      mul.in2[i] <== c[i];
    }
    mod = ModulusWith252c(n-252+125);
    for (i=0; i<n-252+125; i++) {
      mod.a[i] <== mul.out[i];
    }
    sub = BinSub(253);
    for (i=0; i<253; i++) {
      sub.in[0][i] <== q[i];
      sub.in[1][i] <== mod.out[i];
    }

    adder = BinAdd(253);
    for (i=0; i<252; i++) {
      adder.in[0][i] <== a[i];
      adder.in[1][i] <== sub.out[i];
    }
    adder.in[0][i] <== 0;
    adder.in[1][252] <== sub.out[i];

    mod2pfinal = ModulusAgainst2Q();
    for (i=0; i<254; i++) {
      mod2pfinal.in[i] <== adder.out[i];
    }

    for (i=0; i<253; i++) {
      out[i] <== mod2pfinal.out[i];
    }
  }
}

template ModulusAgainst2Q() {
  signal input in[254];
  signal output out[253];
  var i;
  var q[253] = [1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1,
   1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0,
   0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0,
   1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1,
   1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];

  component sub = BinSub(254);
  for (i=0; i<253; i++) {
    sub.in[0][i] <== in[i];
    sub.in[1][i] <== q[i];
  }
  sub.in[0][253] <== in[253];
  sub.in[1][253] <== 0;

  component mux = MultiMux1(253);
  for (i=0; i<253; i++) {
    mux.c[i][0] <== in[i];
    mux.c[i][1] <== sub.out[i];
  }

  mux.s <== 1 + sub.out[253] - 2*sub.out[253];
  for (i=0; i<253; i++) {
    out[i] <== mux.out[i];
  }
}

template ModulusWith25519Chunked51(n) {
  signal input a[n];
  signal output out[5];
  var i;

  component mod2p;
  component mul;
  component mod;
  component adder;
  component mod2pfinal;
  if (n < 5) {
    for (i=0; i<n; i++) {
      out[i] <== a[i];
    }
    for (i=n; i<5; i++) {
      out[i] <== 0;
    }
  } else {
    mod2p = ModulusAgainst2PChunked51();
    for (i=0; i<5; i++) {
      mod2p.in[i] <== a[i];
    }
    mod2p.in[5] <== 0;

    mul = BinMulFastChunked51(n-5, 1);
    for(i=0; i<n-5; i++) {
      mul.in1[i] <== a[5+i];
    }
    mul.in2[0] <== 19;

    mod = ModulusWith25519Chunked51(n-5+1);
    for (i=0; i<n-5+1; i++) {
      mod.a[i] <== mul.out[i];
    }

    adder = BinAddChunked51(5, 2);
    for (i=0; i<5; i++) {
      adder.in[0][i] <== mod2p.out[i];
      adder.in[1][i] <== mod.out[i];
    }

    mod2pfinal = ModulusAgainst2PChunked51();
    for (i=0; i<6; i++) {
      mod2pfinal.in[i] <== adder.out[i];
    }

    for (i=0; i<5; i++) {
      out[i] <== mod2pfinal.out[i];
    }
  }
}

template ModulusAgainst2PChunked51() {
  signal input in[6];
  signal output out[5];
  var i;
  var p[6] = [2251799813685229, 2251799813685247, 2251799813685247, 2251799813685247, 2251799813685247, 0];

  component sub = BigSub51(6);

  in[5] * (in[5] - 1) === 0;
  for (i=0; i<6; i++) {
    sub.a[i] <== in[i];
    sub.b[i] <== p[i];
  }

  component mux = MultiMux1(6);
  for (i=0; i<6; i++) {
    mux.c[i][0] <== in[i];
    mux.c[i][1] <== sub.out[i];
  }

  mux.s <== 1 + sub.underflow - 2*sub.underflow;
  for (i=0; i<5; i++) {
    out[i] <== mux.out[i];
  }
}
