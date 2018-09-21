pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;

//Current version:0.4.25+commit.59dbf8f1.Emscripten.clang



contract Auction {
    
    address notary;
    uint constant numOfBidders  = 20;
    uint auctionStart;
    uint auctionEnd;
    
    address highestBidder;
    uint highestBid;
    
    address private moderator;
    bool end;
  
    uint256 q;
    uint M;
    
    
    // Taking total no of items as 200;
    /*I think it is better to store u,v pairs
        for m no need of array because just we need upper limit
    */
    // uint[200] m;
    // struct Bidder {
    //     address adr;
    //     uint w;
    //     uint[100] s; // Taking max itms to be selected by bidders as 100;
    // }
    

    //initializing q, M
    constructor () public
    {
        //generate large prime number
        q = 541;
        M = 100;
    }
    
    struct uvPair
    {
        uint u;
        uint v;
    }
    uvPair[5] testarr;
    
    struct Bidder 
    {
        
        address adr;

        uvPair[] selectedItems;
        //TODO: Max number of items to be set as M. use require at appropriate place

        uvPair Wpair;
        
    }
    
    Bidder[] private bidders; // Taking 20 bidders at a time;
    //TODO: Min & Max number of bidders to be set as in [https://hackernoon.com/building-a-raffle-contract-using-oraclize-e746e5edff6b]
    
    //Bidder[] public bidders; //(optional)
    address[] private notaries;
    
    
    //mapping notary addresses and payment
    mapping ( address => uint) notaryPayments;
    
    //keeping track of all public keys for duplicate verification
    mapping ( address => bool) publicKeys;
    
    //mapping bidders to notaries.
    mapping ( address => address) biddersNotaries;

    mapping (address => uint) pendingReturns;
    
    function getRandomNumber(address adr,uint256 modValue) private constant returns(uint256)
    {
        //TODO : think of seeds which differ so that random number will be random. or think of some other way
        return uint(uint256(keccak256(block.timestamp, block.difficulty,adr))%modValue);
    }
    
    
    //function checks whether given pk is unique or not.
    function checkValidity( address _pk) private returns(bool)
    {
        //check with all public keys present.
        if(publicKeys[_pk]) return true; // duplicate key
         
        // insert this
        publicKeys[_pk] = true;
        return false; 
        
    }
    
    //to pass struct as param ABIencoder is added.
    function generatePair(uint x,address adr) private constant returns(uvPair)
    {
        uvPair uv;
        uint modValue = 100; //TODO: should make this Dynamic or Global Parameter !
        uv.u = getRandomNumber(adr,modValue);
        uv.v = (x-uv.u)%q;
        return uv;
        
    }

    
    //initialize bidders
    function setBidder( address _pk,uint w,uint[] setItems) public {
        
        //verify for unique public key.
        require(!checkValidity(_pk),"Bidder's PublicKey entered already exits!!");
        
        //assign address of bidder.
        Bidder B ;
        B.adr = _pk;
        
        //function for generation of (u,v) pair of W.
        B.Wpair = generatePair(w,B.adr);
        
        //function for generation of (u,v) pairs.
        for(uint i =0;i<setItems.length;i++)
        {
            B.selectedItems.push(generatePair(setItems[i] , B.adr));
        }
        
        bidders.push(B);

    }
    
    //get count of bidders
    function getBidders() private view returns(uint)
    {
        //return number of bidders
        return ;
    }
    
    //initialize notary
    function setNotary( address _pk)
    {
        require(!checkValidity(_pk),"Public Key entered already exits");
        
        notaries.push(_pk);
        
        //making initial payments to zero.
        notaryPayments[_pk] = 0;
        
    }
    
    function getNotaries() private view returns(uint)
    {
        //return number of notaries
        return ;
    }
    
    
    //mapping bidders to notaries.
    //under progress....
    function mapNotaries()
    {
        uint256 l = bidders.length;
        
        for(uint i = 0; i<l;i++)
        {
            uint index = getRandomNumber(bidders[i].adr,l);
            biddersNotaries[bidders[i].adr] = notaries[index];
        }
        
    }
    
        
    modifier onlyBefore (uint _time) {require(now < _time,"You are late"); _;}
    modifier onlyAfter (uint _time) {require(now > _time, "You are too early"); _;}
    modifier onlyModerator () {require(moderator == msg.sender, "Only moderator is allowed"); _;}
    
    //I didn't understand how to add to changed constructor--- please check and add'
    // constructor (address _notary) public {
    //     notary = _notary;
    //     auctionStart = block.timestamp;
    //     auctionEnd = auctionStart + now;
    // }
    
    function bid() public 
    payable
    onlyBefore(auctionEnd)
    {
        require(msg.value > highestBid, "Bid not enough");
        if (highestBid != 0)
        {
            pendingReturns[highestBidder] = highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    
    function endAuction() public
    onlyAfter(auctionEnd)
    {
        if(end != true)
        {
            end = true;
            pendingReturns[notary] = highestBid;
        }
    } 
    
      // to be done by notary
    function generate1(uvPair x,uvPair y) public returns(uint)
    {
        uint val1=x.u-y.u;
        uint val2=x.v-y.v;
        
        return val1+val2;
    
        
    }
    // to be done by Auctioner;
    function compare(uvPair x,uvPair y) public returns (uint)
    {
        uint a=generate1(x,y);
        if(a==0)
        return 0;
        else if(a<q/2)
        return 1;
        else
        return 2;
    }
    
    //copying elements from input array to global array testarr
    function insert(uvPair[5] x) public returns (uvPair[5])
    {
     for(uint i=0;i<5;i++)
     testarr[i]=x[i];   
     
     return testarr;
    }
    
    // Using quicksort to sort the array based on comparisons procedure..
    function quickSort(uint left, uint right) public returns(uvPair[5])
    {
        uint i = left;
        uint j = right;
        uvPair pivot = testarr[left + (right - left) / 2];
        while (i <= j) {
            while (compare(testarr[i] , pivot)==2) 
            i++;
            while (compare(testarr[i] , pivot)==1)
            j--;
            if (i <= j) {
                (testarr[i], testarr[j]) = (testarr[j], testarr[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(left, j);
        if (i < right)
            quickSort(i, right);
            
            return testarr;
    }
}
