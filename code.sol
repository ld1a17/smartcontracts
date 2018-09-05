
pragma solidity ^0.4.21;

contract test {


  /// The seller's address
  address public owner;
  /// The buyer's address
  address public buyer;

  address RecipientBank;
  address ObiligorBank;
  uint num;


  Stage public stage;

  enum Stage { Deployed, Created, Auctionstart, Auction, Locked, Inactive}

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
        address courier;
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
  event RequestSent(address owner, uint num, address buyer, uint requestdate);
  event OB(address ObiligorBank, uint num);
  event Inform(address RecipientBank, uint num, uint estiblishment_date);
  event InvoiceSent1(address buyer, uint num, address courier, uint deliveryprice, uint deliverydate);
  event InvoiceSent2(address owner, uint num, address courier, uint deliveryprice, uint deliverydate);
  event InvoiceSent3(address owner, uint num, uint quantity, uint price,  uint deliveryprice,uint deliverydate);
  event OrderDelivered(address buyer, uint num, uint delivey_date, address courier);
  event transferFund(uint num, uint value, uint time);


  constructor(address _buyer, address _RecipientBank, address _ObiligorBank) public payable {
    owner = msg.sender;
    buyer = _buyer;
    RecipientBank = _RecipientBank;
    ObiligorBank = _ObiligorBank;
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
    function getInfo(uint _num) public view returns (string, uint, uint, address) {
          require(stage <= Stage.Locked);
          MarketToken memory _goods = marketTokens[_num];
          return (_goods.goods, _goods.id, _goods.price, _goods.owner);
    }

///buyer fill order: num addr name
    function sendOrder(uint _num, string _addr, string _name)
            public
            onlyBuyer
            inStage(Stage.Created)
    {

         /// Create the order register
            orders[_num] = Buyerorder(_num, _addr, _name);

            emit PurchaseOrder(owner, _num, msg.sender, block.timestamp);

     }

///Seller Accept Order
     function confirmoOrder(uint256 _num)
            public
            onlyOwner
            inStage(Stage.Created)
      {
            stage = Stage.Auction;

            emit ConfirmOrder(msg.sender, _num, buyer, block.timestamp);
      }

///Buyer request BPO
     function sendRequest(uint256 _num)
            public
            onlyBuyer
            inStage(Stage.Auctionstart)
     {

            emit RequestSent(owner, _num, msg.sender, block.timestamp);
     }

     function acceptRequest(uint256 _num)
            public
            onlyObiligorBank
            inStage(Stage.Auctionstart)
      {
            stage = Stage.Auction;
            emit OB(ObiligorBank,_num);
      }
/// Inform of BPO estiblishment
      function BPOestiblishment(uint256 _num)
            public
            onlyRecipientBank
            inStage(Stage.Auction)
      {
            stage = Stage.Locked;
            emit Inform(RecipientBank, _num, block.timestamp);
      }



///transport and invoice data
    function sendInvoicetobank(uint _id, uint _delivery_date, address _courier, uint _price )
            public
            onlyOwner
            inStage(Stage.Locked)
    {

            shipments[_id] = Shipment(_id,_courier,_price, msg.sender,buyer, _delivery_date);

            emit InvoiceSent1(buyer, _id, _courier, _price, _delivery_date);
      }

///transport and invoice data
    function sendInvoicetobuyer(uint256 _id)
            public
            onlyObiligorBank
            inStage(Stage.Locked)
    {
            Shipment memory _ship = shipments[_id];
            emit InvoiceSent2(owner, _id, _ship.courier, _ship.deliveryprice, block.timestamp);
    }

///Invoice and shipping documents
    function sendInvoice(uint _id, uint _num)
            public
            onlyOwner
            inStage(Stage.Locked)
    {

            MarketToken memory _goods = marketTokens[_num];
            Shipment memory _ship = shipments[_id];

            /// Trigger the event
            emit InvoiceSent3(buyer, _num, _goods.quantity, _goods.price, _ship.deliveryprice, _ship.deliverydate);
    }


///buyer confirm receive goods
    function confirmReceived()
            public
            onlyBuyer
            inStage(Stage.Locked)
        {
            stage = Stage.Inactive;

        }
///payment
    function totalprice(uint _id, uint _num) public view returns(uint){
            uint _totalprice;
            MarketToken memory _goods = marketTokens[_num];
            Shipment memory _ship = shipments[_id];
            _totalprice  = _goods.price + _ship.deliveryprice ;

            return _totalprice;
    }

    function transferFunds(uint256 _id, uint _num)
            payable
            public
            onlyObiligorBank
            inStage(Stage.Inactive)
    {
            require(msg.value >= totalprice(_id,_num));
            {
                ObiligorBank.transfer(msg.value);
                RecipientBank.transfer(ObiligorBank.balance);
            }

            emit transferFund(_num, totalprice(_id,_num), block.timestamp);

    }

/// view Stage
    function updateStage() public view returns (Stage) {
          return stage;
      }


}
