pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2;


contract Auction {
    address notary;
    
    uint auctionStart;
    uint auctionEnd;
    
    address highestBidder;
    uint highestBid;
    
    address public moderator;
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
    
    
    struct Bidder {
        
        address adr;
        uint[] u; 
        uint[] v;
        
        //mapping (uint => uint) uvPairs;
        uint Wu; 
        uint Wv;
        
    }
    
    Bidder[20] public bidders; // Taking 20 bidders at a time;
    
    //Bidder[] public bidders; //(optional)
    address[] public notaries;
    
    
    //mapping notary addresses and payment
    mapping ( address => uint) notaryPayments;
    
    //keeping track of all public keys for duplicate verification
    mapping ( address => bool) publicKeys;
    
    //mapping bidders to notaries.
    mapping ( address => address) biddersNotaries;

    mapping (address => uint) pendingReturns;
    
    //function checks whether given pk is unique or not.
    function checkValidity( address _pk) public constant returns(bool){
        //check with all public keys present.
        if(publicKeys[_pk]) return true; // duplicate key
         
        // insert this
        publicKeys[_pk] = true;
        return false; 
        
    }
    

    
    //initialize bidders
    function setBidder( address _pk,uint w,uint[] setItems) public {
        
        //verify for unique public key.
        require(!checkValidity(_pk),"Bidder's PublicKey entered already exits!!");
        
        //initialize bidder.
        Bidder b ;
        address baddr = _pk;
        b.adr = baddr;
        
        //function for generation of (u,v) pairs.
        //generatePairs(b,w,setItems);
        

    }
    

    
    //initialize notary
    function setNotary( address _pk)
    {
        require(!checkValidity(_pk),"Public Key entered already exits");
        
        notaries.push(_pk);
        
        //making initial payments to zero.
        notaryPayments[_pk] = 0;
        
    }
    
   
    
    //mapping bidders to notaries.
    //under progress....
    function mapNotaries()
    {
        uint l = bidders.length;
        uint index = uint(block.blockhash(block.number-1))%l + 1;
        
        for(uint i = 0; i<l;i++){
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
}