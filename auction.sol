pragma solidity ^0.4.24;
contract Auction {
    address notary;
    uint auctionStart;
    uint auctionEnd;
    address highestBidder;
    uint highestBid;
    address public moderator;
    bool end;
    // Taking total no of items as 200;
    uint[200] m;
    struct Bidder {
        address adr;
        uint w;
        uint[100] s; // Taking max itms to be selected by bidders as 100;
    }
    Bidder[20] public bidders; // Taking 20 bidders at a time;
    
    mapping (address => uint) pendingReturns;
    modifier onlyBefore (uint _time) {require(now < _time,"You are late"); _;}
    modifier onlyAfter (uint _time) {require(now > _time, "You are too early"); _;}
    modifier onlyModerator () {require(moderator == msg.sender, "Only moderator is allowed"); _;}
    
    
    constructor (address _notary) public {
        notary = _notary;
        auctionStart = block.timestamp;
        auctionEnd = auctionStart + now;
    }
    
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

