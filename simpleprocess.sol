pragma solidity ^0.4.21;

contract test {


  /// The seller's address
  address public owner;
  /// The buyer's address
  address public buyer;

  address RecipientBank;
  address ObiligorBank;
  uint num;
  uint totalprice;

  Stage public stage;

  enum Stage { Deployed, Created, Auctionstart, Auction, Payment}

    struct MarketToken {

        string goods;
        uint quantity;
        uint id;
        uint price;
        address owner;
    }

    struct Buyerorder {
        uint256 num;
        string Addr;
        string name;
    }

    struct Shipment {
        uint id;
        string courier;
        uint deliveryprice;
        address owner;
        address buyer;
        uint deliverydate;
    }

  mapping (uint => MarketToken) marketTokens;
  mapping (uint => Shipment) shipments;
  mapping (uint => Buyerorder) orders;

  //events
  event goodsinfo(address owner, uint num,string  _goods,uint _quantity,uint id, uint _price);
  event PurchaseOrder(address owner, uint num, address buyer, uint orderdate );
  event ConfirmOrder(address owner, uint num, address buyer, uint starteddate);
  event RequestSent(address owner, uint num, uint price, address buyer, uint requestdate);
  event OB(address ObiligorBank, uint num);
  event Inform(address RecipientBank, uint num, uint estiblishment_date);
  event InvoiceSent1(uint num,uint id, string courier, uint deliveryprice, uint deliverydate);
  event InvoiceSent2(address owner, uint num, uint quantity, uint price,  uint deliveryprice,uint deliverydate,uint totalprice);
  event ItemReceived(uint num);
  event transferFund(uint num, uint value,uint balance, uint time);


  constructor() public payable {
    owner = msg.sender;
  }
  

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlyObiligorBank {
        require(msg.sender == ObiligorBank);
        _;
    }
    modifier onlyRecipientBank {
        require(msg.sender == RecipientBank);
        _;
    }

    modifier inStage(Stage _stage) {
        require(stage == _stage);
        _;
    }
    
    function uploadgoods(
        string _goods,
        uint _quantity,
        uint _id,
        uint _price

    )
        public
        onlyOwner
        inStage(Stage.Deployed)

    {
        num++;
        require( _price!= 0 && _quantity >=1 && _id != 0);
        marketTokens[num] = MarketToken (_goods, _quantity, _id, _price, msg.sender);
        emit goodsinfo(owner, num, _goods, _quantity, _id, _price);

    }

///fillOrder

///get information of goods
    function getInfo(uint _num)
        public 
        view 
        onlyBuyer 
        returns (string, uint, uint, address) 
    {
          MarketToken memory _goods = marketTokens[_num];
          return (_goods.goods, _goods.id, _goods.price, _goods.owner);
    }
    
    function Deal(address _buyer) public {
        buyer = _buyer;
   }

///buyer fill order: num addr name
    function sendOrder(uint _num, string _addr, string _name)
            public
            onlyBuyer
            inStage(Stage.Deployed)
    {

         /// Create the order register
            orders[_num] = Buyerorder(_num, _addr, _name);
            stage = Stage.Created;

            emit PurchaseOrder(owner, _num, msg.sender, block.timestamp);

     }

///Seller Accept Order
     function confirmOrder(uint256 _num)
            public
            onlyOwner
            inStage(Stage.Created)
      {
            require(num!=0);
            stage = Stage.Auction;

            emit ConfirmOrder(msg.sender, _num, buyer, block.timestamp);
      }

///Buyer request BPO
     function sendRequest(uint256 _num)
            public
            onlyBuyer
            inStage(Stage.Auction)
     {

            emit RequestSent(owner, _num, marketTokens[_num].price, buyer, block.timestamp);
            stage = Stage.Auctionstart;
     }
/// Bank accept Request from buyer

     function payerbank(address _payerbank) 
            payable 
            public
     {
         require(stage >= Stage.Auctionstart );
         ObiligorBank = _payerbank;
     }
     
     function acceptRequest(uint _num)
            public
            onlyObiligorBank
            inStage(Stage.Auctionstart)
      {
            
            stage = Stage.Auction;
            emit OB(ObiligorBank,_num);
      }
      
/// Inform of BPO estiblishment
      function sellerbank(address _sellerbank)
           payable
           public
           
     {
           require(stage >= Stage.Auctionstart );
           RecipientBank = _sellerbank;
     }
      
      function BPOestiblishment(uint256 _num)
            public
            onlyRecipientBank
            inStage(Stage.Auction)
      {
           
            emit Inform(RecipientBank, _num, block.timestamp);
      }



///transport and invoice data
    function sendInvoicetobank(uint _num, uint _id, uint _delivery_date, string  _courier, uint _price )
            public
            onlyOwner
            inStage(Stage.Auction)
    {

            shipments[_id] = Shipment(_id, _courier, _price, owner, buyer, _delivery_date);

            emit InvoiceSent1(_num, _id, _courier, _price, block.timestamp);
      }



///Invoice and shipping documents
    function sendInvoice(uint _num, uint _id)
            public
            inStage(Stage.Auction)
    {
            totalprice  = marketTokens[_num].price +  shipments[_id].deliveryprice ;
            /// Trigger the event
            emit InvoiceSent2(buyer, _num, marketTokens[_num].quantity, marketTokens[_num].price, shipments[_id].deliveryprice,shipments[_id].deliverydate, totalprice);
    }


///buyer confirm receive goods
    function confirmReceived(uint _num)
            public
            onlyBuyer
            inStage(Stage.Auction)
        {
            stage = Stage.Payment;
            emit ItemReceived(_num);
        }
///payment
    function banlance()
          public
          view
          onlyRecipientBank
          returns(uint) 
          {
             return(RecipientBank.balance);
          }
 

    function transferFunds(uint _num)
            payable
            public
            onlyObiligorBank
           inStage(Stage.Payment)
    {
            
            RecipientBank.transfer(totalprice);
            emit transferFund(_num, totalprice,RecipientBank.balance, block.timestamp);
            

    }

/// view Stage
    function updateStage() public view returns (Stage) {
          return stage;
      }


}
