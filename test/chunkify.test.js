const chai = require("chai");
const path = require("path");
const assert = require("assert");
const utils = require("./utils");

const wasm_tester = require("circom_tester").wasm;

describe("Chunkify Test", () => {
	describe("when chunking a 256 bit number", () => {
		it("should chunk it correctly", async () => {
			const cir = await wasm_tester(path.join(__dirname, "circuits", "chunkify1.circom"));
			const a = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");
			const buf1 = utils.bigIntToLEBuffer(a);
			const asBits1 = utils.buffer2bits(buf1);
			const witness = await cir.calculateWitness({ "in": asBits1}, true);

       		numChunks = calcChunks(asBits1.length);
     		var x = BigInt("0");
			for (var i=0; i<numChunks; i++) {
				x = x + BigInt(witness[i+1]) * (BigInt(2) ** (BigInt(i) * BigInt(51)));
			}
      		assert.ok(x == a);
		});
	});
});

function calcChunks(n) {
  var numChunks = Math.floor(n/51);
  if (n % 51 != 0) {
    numChunks++;
  }
  return numChunks;
}