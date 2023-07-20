// SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

//nsert the interface of an ERC-20 token so your contract can interact with it.

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Marketplace {
    
    //in this section, we will optimise our contract
    //we will create a state variable that keeps track of how many products are stored in our contract
    //this variable will also help you to create the indexes for our products
    uint internal productsLength = 0;

    //the address of the cUSD ERC-20 token on the Celo alfajores test network so we can interact with it
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Product {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
    }

    mapping (uint => Product) internal products;


    //we need to adapt our writeProduct function
    //When a user adds a new product to your marketplace contract, you set _sold to the value 0
    //because it tracks the number of times the product was sold
    //this is initially always zero, and therefore you don't need a parameter.

    function writeProduct(
        string memory _name,
        string memory _image, //örnek: orange.png
        string memory _description,
        string memory _location,
        uint _price
    ) public {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(bytes(_name).length <= 100, "Product name is too long");
        require(bytes(_image).length > 0, "Product image cannot be empty");
        require(bytes(_description).length > 0, "Product description cannot be empty");
        require(bytes(_location).length > 0, "Product location cannot be empty");
        require(_price > 0, "Product price must be greater than zero");
        uint _sold = 0;
        products[productsLength]= Product (
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            _sold
        );
        productsLength++; //when a new product has been stored, we count productsLength up by one
        
    }

    //we need to change the readProduct function
    function readProduct(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint
    ) {
        require(_index < productsLength, "Invalid product index");
        return (
            products[_index].owner,
            products[_index].name,
            products[_index].image,
            products[_index].description,
            products[_index].location,
            products[_index].price,
            products[_index].sold
        );
    }

    //we need to create a function to buy products from our contract.
    function buyProduct(uint _index) public payable {

    require(_index < productsLength, "Invalid product index");

    // Get the product from the mapping
    Product storage product = products[_index];

    // Calculate the total cost of the product
    uint totalCost = product.price;

    // Ensure the buyer sends enough funds to purchase the product
    require(msg.value >= totalCost, "Insufficient funds");

    // Attempt to transfer funds from the buyer to the product owner
    try IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        product.owner,
        totalCost
    ) returns (bool success) {
        require(success, "Transfer failed");
    } catch Error(string memory errorMessage) {
        revert(errorMessage);
    } catch {
        revert("Unknown error occurred during transfer");
    }

    // Update the product state
    product.sold++;

    // Refund excess funds back to the buyer
    if (msg.value > totalCost) {
        uint refundAmount = msg.value - totalCost;
        (bool refundSuccess, ) = msg.sender.call{value: refundAmount}("");
        require(refundSuccess, "Refund failed");
    }
}


    //create a public function to return the number of products stored
    function getProductsLength() public view returns (uint) {
        return productsLength;
    }

}
