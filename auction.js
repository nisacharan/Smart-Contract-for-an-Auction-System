// const assert = require("assert");
// const ganache = require("ganache-cli");
// const Web3 = require("web3");
// const web3 = new Web3(ganache.provider());
const Auction = artifacts.require("./Auction.sol")
const assert = require("assert")
const ethers = require("ethers")


let contractInstance
let contractInstanceAddress
let contractInstanceABI

contract("Auction", (accounts) => {


	const provider = new ethers.providers.Web3Provider(web3.currentProvider);

	beforeEach(async () => {
		contractInstance = await Auction.deployed()
		contractInstanceAddress = contractInstance.address;
		contractInstanceABI = contractInstance.abi;
		contractInstance2 = new ethers.Contract(contractInstanceAddress,contractInstanceABI,provider)
   });

		function wait(ms){
		   var start = new Date().getTime();
		   var end = start;
		   while(end < start + ms) {
		     end = new Date().getTime();
	  		}
		}


		// 

		it("Deploy", async()=>{
			await contractInstance.setNotary( {from:accounts[1]});
			const notaryAdr = await contractInstance.notaries(0);
			const notaryPayment = await contractInstance.notaryPayments(notaryAdr);
			const owner = accounts[1];
			assert.equal(notaryPayment,0,"payment Equal Not Found");
		})

		wait(6000);
			

		
		it("Registration of given bidder", async()=>{

			const lenbefore = await contractInstance2.getBiddersLength();
			console.log("Length of bidders before insertion: ",lenbefore);


			const elem1 = { u:5, v:6};
			const elem2 = { u:7, v:8};
			const ar2 = [elem1,elem2]
			const ar1 = {u:1070,v:6};	

			
			const signer = provider.getSigner(accounts[2]);
			contractInstance2 = contractInstance2.connect(signer);

			const res = await contractInstance2.setBidder(ar1,ar2,{ gasLimit: 3000000});
			const lenafter = await contractInstance2.getBiddersLength();
			console.log("Length of bidders after insertion: ",lenafter);
			assert.equal(1,lenafter-lenbefore,"Bidder Couldn't Register");
		
		})


		it("Registration of given notary", async()=>{

			const lenbefore = await contractInstance2.getNotariesLength();
			console.log("Length of notaries before insertion: ",lenbefore);

			const signer = provider.getSigner(accounts[3]);
			contractInstance2 = contractInstance2.connect(signer);
			const res = await contractInstance2.setNotary({ gasLimit: 3000000});
			const lenafter = await contractInstance2.getNotariesLength();
			console.log("Length of notaries after insertion: ",lenafter);
			assert.equal(1,lenafter-lenbefore,"notary Couldn't Register");
		})


		//-----------helper functions-----------


		//generates prime number of x bits
		function generatePrime(x,callback){			
			var bits = x;
			var forge = require('node-forge');
			var pr = forge.prime.generateProbablePrime(bits, function(err, num) {
    		return callback(num);
    		});
		}

		function generatePair(x,q,min,max){
		    var min=min;
		    var max=max; 
		    var u = Math.floor(Math.random() * (+max - +min)) + +min;
		    var v = ((x-u)%q)%q;
		    return [parseInt(u),parseInt(v)];			
		}

		function generateRandomNumber(min,max) {
			var min=min;
		    var max=max; 
		    return Math.floor(Math.random() * (+max - +min)) + +min;
		}
	

		//------------------------------------------------------------

		it("Random bidder registration", async()=>{
					
			var largePrime;
			generatePrime(8,function(ans){
				largePrime = ans
			})

			var q = largePrime.data[0]
			console.log("q: ",q);

			var w = generateRandomNumber(0,q/2);
			console.log("w: ",w);

			var M = generateRandomNumber(0,20);
			console.log("M: ",M);

			var uv = generatePair(w,largePrime,0,20)
			console.log("pair: ",uv);

			var itemsArray=[]; 
			for(var i=0;i<M;i++){
				var temp = generatePair(i,largePrime,0,20);
				const tempItem = { u: temp[0], v: temp[1]};
				//considering biddr is interested in all the items
				itemsArray.push(temp)
			}

			const wPair = { u:uv[0],v:uv[1]}
			const signer = provider.getSigner(accounts[4]);
			contractInstance2 = contractInstance2.connect(signer);
			const lenbefore = await contractInstance2.getBiddersLength();
			const res = await contractInstance2.setBidder(wPair,itemsArray,{ gasLimit: 3000000});
			const lenafter = await contractInstance2.getBiddersLength();
			assert.equal(1,lenafter-lenbefore,"Random Bidder Couldn't Register");
		})


		it("Multiple random bidder registration", async()=>{
			

			var largePrime;
			generatePrime(8,function(ans){
				largePrime = ans
			})

			var q = largePrime.data[0]
			console.log("q: ",q);

			var M = generateRandomNumber(1,20);
			console.log("M: ",M);
			
			for(var i=5;i<8;i++)
			{
		
				var w = generateRandomNumber(0,q/2);
				console.log("w: ",w);			

				var uv = generatePair(w,largePrime,50,100)
				console.log("pair: ",uv);

				console.log("items selected: ")
				var itemsArray=[]; 
				for(var j=0;j<M;j++){
					var temp = generatePair(j,largePrime,0,20);
					console.log(temp);
					const tempItem = { u: temp[0], v: temp[1]};
					//considering biddr is interested in all the items
					itemsArray.push(temp)
				}



				const wPair = { u:uv[0],v:uv[1]}
				const signer = provider.getSigner(accounts[i]);
				contractInstance2 = contractInstance2.connect(signer);
				const lenbefore = await contractInstance2.getBiddersLength();
				const res = await contractInstance2.setBidder(wPair,itemsArray,{ gasLimit: 3000000});
				const lenafter = await contractInstance2.getBiddersLength();
				console.log("Bidder Added, +",lenafter)
				// assert.equal(1,lenafter-lenbefore,"Random Bidder Couldn't Register");
			}

		})


		it("Checking sorting", async()=>{
			

			var largePrime;
			generatePrime(8,function(ans){
				largePrime = ans
			})

			var q = 541//largePrime.data[0]
			console.log("q: ",q);

			var M = generateRandomNumber(1,5);
			console.log("M: ",M);
			
			for(var i=8;i<12;i++)
			{
		
				var w = generateRandomNumber(0,q/2);
				console.log("w: ",w);			

				var uv = generatePair(w,largePrime,50,100)
				console.log("pair: ",uv);

				console.log("items selected: ")
				var itemsArray=[]; 
				for(var j=0;j<M;j++){
					var temp = generatePair(j,largePrime,0,20);
					console.log(temp);
					const tempItem = { u: temp[0], v: temp[1]};
					//considering biddr is interested in all the items
					itemsArray.push(temp)
				}



				const wPair = { u:uv[0],v:uv[1]}
				const signer = provider.getSigner(accounts[i]);
				console.log("Address: ",accounts[i])
				contractInstance2 = contractInstance2.connect(signer);
				const lenbefore = await contractInstance2.getBiddersLength();
				const res = await contractInstance2.setBidder(wPair,itemsArray);//,{ gasLimit: 3000000});
				const lenafter = await contractInstance2.getBiddersLength();
				console.log("Bidder Added, +",lenafter)
				// assert.equal(1,lenafter-lenbefore,"Random Bidder Couldn't Register");
			}
			const lenOfBidders = await contractInstance2.getBiddersLength();
			await contractInstance2.quickSort(0,lenOfBidders);
			var res = await contractInstance2.bidders
			console.log(">>>strd",res);

		})

});


		//check validity
		//w < q/2
		//sort working or not
		//uniq mapping or not
		//decide winner
		//winner payment
		//M out of scope
		//w -ve value
		//Incomplete auction
