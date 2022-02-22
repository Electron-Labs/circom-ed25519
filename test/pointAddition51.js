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
            const P = [15112221349535400772501151409588531511454012693041857206046113283949847762202n, 46316835694926478169428394003475163141307993866256225615783033603165251855960n, 1n, 46827403850823179245072216630277197565144205554125654976674165829533817101731n];
            const Q = [15112221349535400772501151409588531511454012693041857206046113283949847762202n, 46316835694926478169428394003475163141307993866256225615783033603165251855960n, 1n, 46827403850823179245072216630277197565144205554125654976674165829533817101731n];
            // const P = [43933056957747458452560886832567536073542840507013052263144963060608791330050n, 16962727616734173323702303146057009569815335830970791807500022961899349823996n, 1n, 47597536765056690778342994103149503974598380825968728087754575050160026478564n];
            // const Q = [13962987660910639259224605671776417853092151825807229756583828943347773489899n,16962727616734173323702303146057009569815335830970791807500022961899349823996n, 1n, 10298507853601406933442498401194449952036611506851553931974216953796538341385n];
            // const p = BigInt(2**255)-BigInt(19);
            
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
            // const P = [[1738742601995546,
            //     1146398526822698,
            //     2070867633025821,
            //     562264141797630,
            //     587772402128613],
            //     [1801439850948184,
            //     1351079888211148,
            //     450359962737049,
            //     900719925474099,
            //     1801439850948198],
            //     [1,0,0,0,0],
            //     [1841354044333475,
            //         16398895984059,
            //         755974180946558,
            //         900171276175154,
            //         1821297809914039]
                   
            // ]
            // const Q = [[1738742601995546,
            //     1146398526822698,
            //     2070867633025821,
            //     562264141797630,
            //     587772402128613],
            //     [1801439850948184,
            //     1351079888211148,
            //     450359962737049,
            //     900719925474099,
            //     1801439850948198],
            //     [1,0,0,0,0],
            //     [1841354044333475,
            //         16398895984059,
            //         755974180946558,
            //         900171276175154,
            //         1821297809914039]
                   
            // ]
            const witness = await cir.calculateWitness({"P":chunk1,"Q":chunk2},true);

            // const res  = utils.point_add(P,Q);
            
            
            // for different convention of modulus 
            // function modulus(num, p){
            //     return ((num%p)+p)%p;
            // }
            // const xp = [];
            // for(let i=0;i<4;i++){
            //     // let temp = res[i];
            //     // if (temp < 0n){
            //     //     temp = temp + p;

            //     // }
            //     // let 
            //     xp.push(utils.chunkBigInt(res[i])); 
            // }

            // const expected = [];
            // for(let i=0;i<4;i++){
            //     for(let j=0;j<5;j++){
            //         expected.push(xp[i][j]);
            //     }
            // }
            
            const wt = witness.slice(1, 21);
            for(i=0;i<20;i++){
                console.log(wt[i]);
            }
            // let sum = 0n;
            // for(let i=0;i<4;i++){
            //     sum += (BigInt(2)**BigInt(51*i))*wt[i];
            // }
            // console.log(sum);

            assert.ok(witness.slice(1, 21).every((u, i)=>{
                return u === expected[i];
            }));


            // 2128266030960994n
            // 1279605069589912n
            // 1207721033820905n
            // 446493586708288n
            // 1941329293604910n
            // 1741453722230468n
            // 737571062238667n
            // 186609519849319n
            // 854272334943042n
            // 1071171714962781n
            // 918572359382682n
            // 1634616568285311n
            // 991187026668873n



        });
    });
}); 