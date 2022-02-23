const chai = require("chai");
const path = require("path");
const assert = require("assert");
const bigintModArith = require('bigint-mod-arith');
const utils = require('./utils');
const { performance } = require('perf_hooks');

const wasm_tester = require("circom_tester").wasm;

describe("Modulus Test", () => {

	describe("when performing modulus on a number in prime field 25519 ", () => {
		const p = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");

		it("should calculate the modulus correctly", async () => {
			const cir = await wasm_tester(path.join(__dirname, "circuits", "modulus0.circom"));
			const a = BigInt("107896044618658097711785492504343953926634992332820282019728792003956564819949");
			const buf = utils.bigIntToLEBuffer(a);
			const asBits = utils.buffer2bits(buf);
			const witness = await cir.calculateWitness({ "in": asBits}, true);

			const expected = utils.pad(utils.buffer2bits(utils.bigIntToLEBuffer(bigintModArith.modPow(a, 1, p))), 255);
			assert.ok(witness.slice(1, 256).every((u, i) => {
				return u === expected[i];
			}));
		});
	});

	describe("when performing modulus on a number in prime field 25519 ", () => {
		const p = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");

		it("should calculate the modulus correctly", async () => {
			const cir = await wasm_tester(path.join(__dirname, "circuits", "modulus0.circom"));
			const a = BigInt("3953926634992332820282019728792003956564819949");
			const buf = utils.bigIntToLEBuffer(a);
			const asBits = utils.pad(utils.buffer2bits(buf), 256);
			const witness = await cir.calculateWitness({ "in": asBits}, true);

			const expected = utils.pad(utils.buffer2bits(utils.bigIntToLEBuffer(bigintModArith.modPow(a, 1, p))), 255);
			assert.ok(witness.slice(1, 256).every((u, i) => {
				return u === expected[i];
			}));
		});
	});

	describe("when performing modulus  on a binary number of 240 bits in prime field of prime 25519", () => {
		const p = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");

		it("should calculate the modulus of the binary number correctly", async () => {
			const cir = await wasm_tester(path.join(__dirname, "circuits", "modulus1.circom"));
			const a = BigInt("44618658097711785492504343953926634992332820282019728792003956564819949");
			const buf = utils.bigIntToLEBuffer(a);
			const asBits = utils.buffer2bits(buf);
			const witness = await cir.calculateWitness({ "a": asBits}, true);

			const expected = utils.pad(utils.buffer2bits(utils.bigIntToLEBuffer(bigintModArith.modPow(a, 1, p))), 255);
			assert.ok(witness.slice(1, 256).every((u, i) => {
				return u === expected[i];
			}));
		});
	});

	describe("when performing modulus  on a binary number of 264 bits in prime field of prime 25519", () => {
		const p = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");

		it("should calculate the modulus of the binary number correctly", async () => {
			const cir = await wasm_tester(path.join(__dirname, "circuits", "modulus2.circom"));
			const a = BigInt("1257896044618658097711785492504343953926634992332820282019728792003956564819949");
			const buf = utils.bigIntToLEBuffer(a);
			const asBits = utils.buffer2bits(buf);
			// var startTime = performance.now();
			const witness = await cir.calculateWitness({ "a": asBits}, true);
			// var endTime = performance.now();
			// console.log(`Call to calculate witness took ${endTime - startTime} milliseconds`);

			const expected = utils.pad(utils.buffer2bits(utils.bigIntToLEBuffer(bigintModArith.modPow(a, 1, p))), 264);
			assert.ok(witness.slice(1, 255).every((u, i) => {
				return u === expected[i];
			}));
		});
	});

	describe("when performing modulus on a number of 32 chunks each chunk of size 51 bits in  prime field of prime 25519", () => {
		const p = BigInt("57896044618658097711785492504343953926634992332820282019728792003956564819949");

		it("should calculate the modulus of that number correctly",async () =>{
			const cir = await wasm_tester(path.join(__dirname,"circuits", "chunkedmodulus.circom"));
			const chunk = [2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n,
				2251799813685247n];
			const witness = await cir.calculateWitness({"a":chunk},true);

			const expected = [2251799813685247n, 2251799813685247n, 47045880n, 0n, 0n];	
			assert.ok(witness.slice(1, 6).every((u, i)=>{
				return u === expected[i];
			}));
		});
	});
});
      