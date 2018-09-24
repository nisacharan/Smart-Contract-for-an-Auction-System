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
  
    uint256 public q;
    uint public M;
    
    //initializing q, M
    constructor () public
    {
        //TODO: generate large prime number
        q = 541;
        M = 100;
    }
    
    struct uvPair
    {
        uint u;
        uint v;
    }

    // uvPair[5] testarr;
    
    struct Bidder 
    {
        address adr;
        uvPair[] selectedItems;

        //TODO: Max number of items to be set as M. use require at appropriate place = setBidder
        uvPair Wpair;    
    }
    
    Bidder[] private bidders; // Taking 20 bidders at a time;
    //TODO: Min & Max number of bidders to be set as in [https://hackernoon.com/building-a-raffle-contract-using-oraclize-e746e5edff6b]
    
    mapping(uint => bool) isWinner; //used to query if a biddet at index'i' in bidders array is winner or not
    uint[] private winnerPrice;
    Bidder[] private winners;
    
    //Bidder[] public bidders; //(optional)
    address[] private notaries;
    
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
    
    
    // //to pass struct as param ABIencoder is added.
    // function generatePair(uint x,address adr) private constant returns(uvPair)
    // {
    //     uvPair uv;
    //     uint modValue = 100; //TODO: should make this Dynamic or Global Parameter !
    //     uv.u = getRandomNumber(adr,modValue);
    //     uv.v = (x-uv.u)%q;
    //     return uv;
        
    // }


    //initialize bidders
    function setBidder( uvPair w,uvPair[] setItems) public 
    {
        
        //verify for unique public key.
        require(!checkValidity(msg.sender),"Bidder's PublicKey entered already exits!!");
        
        //assign address of bidder.
        Bidder B ;
        B.adr = msg.sender;
        
        //taking input of (u,v) pairs from user.
        B.Wpair = w;
        
        for(uint i = 0;i<setItems.length;i++)
        {
            B.selectedItems.push(setItems[i]);
        }
        bidders.push(B);

    }
    

    
    //initialize notary
    function setNotary() public
    {
        require(!checkValidity(msg.sender),"Public Key entered already exits");
        
        notaries.push(msg.sender);
        
        //making initial payments to zero.
        notaryPayments[msg.sender] = 0;
        
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
    function generate1(uvPair x,uvPair y)  private constant returns(uint)
    {
        uint val1=x.u-y.u;
        uint val2=x.v-y.v;
        return val1+val2;
    }
    
    // to be done by Auctioner;
    function compare(uvPair x,address notary1,uvPair y,address notary2) private returns (uint)
    {
        uint a=generate1(x,y);
        
        //------added payment to notary-------
        
        //making payment to notary
        notaryPayments[notary1]+=1;
        notaryPayments[notary2]+=1;
        
        if(a==0)
        return 0; //means equal
        else if(a<q/2)
        return 1; //means x>y
        else
        return 2; //means x<y
    }
    
    
    //removed global array and used directly bidders array.
    // Using quicksort to sort the array based on comparisons procedure..
    function quickSort(uint left, uint right) private
    {
        uint i = left;
        uint j = right;
        uint mid = left + (right - left) / 2;
        
        uvPair pivot = bidders[mid].Wpair;
        
        while (i <= j) {
            while (compare(bidders[i].Wpair ,biddersNotaries[bidders[i].adr], pivot,biddersNotaries[bidders[mid].adr])==2) 
            i++;
            while (compare(bidders[i].Wpair,biddersNotaries[bidders[i].adr], pivot,biddersNotaries[bidders[mid].adr])==1)
            j--;
            if (i <= j) {
                (bidders[i], bidders[j])  = (bidders[j], bidders[i]);
                i++;
                j--;
            }
        }
        
        if (left < j)
            quickSort(left, j);
        if (i < right)
            quickSort(i, right);
            
            return ;
    }

    //this method uses merge-sort technique. 
    //give only sorted arrays into it for minimum comparisions in O(mlogn+nlogm)
    function isDisjoint(uvPair[] arr1,address notary1, uvPair[] arr2,address notary2) private returns(bool)
    {
    // Check for same elements using merge like process
    uint m = arr1.length;
    uint n = arr2.length;
    
        for(uint i=0;i<m;i++)
        {
            for(uint j=0;j<n;j++)
            {
                if(compare(arr1[i],notary1,arr2[j],notary2)==0) //means they're equal and hence not Disjoint
                    return false;
            }
        }
        return true;
    }
    
    
    //----------------deciding winner set--------------------
    function makeWinnerSelectedItems() private
    {
            quickSort(0,bidders.length);
            
            winners.push(bidders[0]);
            
            for(uint i=1;i<bidders.length;i++)
            {
                for(uint j=0;j< winners.length;j++)
                {
                    address notary1Address = biddersNotaries[winners[j].adr];
                    address notary2Address = biddersNotaries[bidders[i].adr];
                    
                    if(isDisjoint(winners[j].selectedItems,notary1Address,bidders[i].selectedItems,notary2Address))
                    {
                        isWinner[i]=true;
                        winners.push(bidders[i]);
                    }
                }
                
            }
    }
