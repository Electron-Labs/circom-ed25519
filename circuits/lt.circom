pragma circom 2.0.0;

include "../circomlib/circuits/bitify.circom";
template LessThanPower51() {
  signal input in;
  signal output out;

  out <-- 1 - ((in >> 51) > 0);
  out * (out - 1) === 0;
}
