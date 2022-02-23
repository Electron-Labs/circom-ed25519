const chai = require("chai");
const path = require("path");
const assert = require("assert");
const utils = require("./utils");
const { LOADIPHLPAPI } = require("dns");

const wasm_tester = require("circom_tester").wasm;

describe("Point Addition test on ed25519", ()=>{
    describe("when performing point addition on the EC of 255 bits ",()=>{
        it("should add them correctly ", async() =>{
            const cir = await wasm_tester(path.join(__dirname,"circuits","point-addition51.circom"));
            let p = BigInt(2**255) - BigInt(19);
            const P = [15112221349535400772501151409588531511454012693041857206046113283949847762202n, 46316835694926478169428394003475163141307993866256225615783033603165251855960n, 1n, 46827403850823179245072216630277197565144205554125654976674165829533817101731n];
            const Q = [15112221349535400772501151409588531511454012693041857206046113283949847762202n, 46316835694926478169428394003475163141307993866256225615783033603165251855960n, 1n, 46827403850823179245072216630277197565144205554125654976674165829533817101731n];
      
            const chunk1 = [];
            const chunk2 = [];
            for(let i=0;i<4;i++){
                chunk1.push(utils.chunkBigInt(P[i]));
                chunk2.push(utils.chunkBigInt(Q[i]));
            }
            for(let i=0;i<4;i++){
                utils.pad(chunk1[i],5);
                utils.pad(chunk2[i],5);
            }            
            const witness = await cir.calculateWitness({"P":chunk1,"Q":chunk2},true);
            const res  = utils.point_add(P,Q);
            const expected = [];
            for(let i=0;i<4;i++){  
                expected.push((utils.modulus(res[i],p))); 
            }
            const wt = witness.slice(1, 21);
            const chunk= [];
            for(let i=0;i<4;i++){
                chunk.push(wt.slice(5*i, 5*i+5));
            }
           
            const dechunked_wt = [];
            for( let i=0;i<4;i++){
                dechunked_wt.push(utils.dechunk(chunk[i]));
            }
            
            assert.ok(
                utils.point_equal(expected,dechunked_wt)
            );
        });
    });
}); 