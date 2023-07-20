// SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Marketplace Contract
 * @notice This contract allows users to create, update, and remove products in a marketplace.
 * @dev The contract interacts with an ERC-20 token to handle payments.
 */
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

/**
 * @title Marketplace Contract
*/
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

 /**
  * @dev Event emitted when a new product is added to the marketplace
*/
    event ProductAdded(
        uint indexed index,
        address owner,
        string name,
        string image,
        string description,
        string location,
        uint price
    );

/**
 * @dev Event emitted when a product is updated
*/
    event ProductUpdated(
        uint indexed index,
        string name,
        string image,
        string description,
        string location,
        uint price
    );

/**
 * @dev Event emitted when a product is removed from the marketplace
*/
    event ProductRemoved(uint indexed index);

    modifier onlyProductOwner(uint _index) {
        require(_index < productsLength, "Invalid product index");
        require(msg.sender == products[_index].owner, "You are not the product owner");
        _;
    }


/**
     * @notice Update an existing product in the marketplace
     * @param _index The index of the product to update
     * @param _name The new name of the product
     * @param _image The new image URL of the product
     * @param _description The new description of the product
     * @param _location The new location of the product
     * @param _price The new price of the product
*/
    function updateProduct(
        uint _index,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _location,
        uint _price
    ) public onlyProductOwner(_index) {
        // Validate the input parameters (similar to writeProduct function)
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(bytes(_name).length <= 100, "Product name is too long");
        require(bytes(_image).length > 0, "Product image cannot be empty");
        require(bytes(_description).length > 0, "Product description cannot be empty");
        require(bytes(_location).length > 0, "Product location cannot be empty");
        require(_price > 0, "Product price must be greater than zero");

        // Get the product from the mapping
        Product storage product = products[_index];

        // Update the product details
        product.name = _name;
        product.image = _image;
        product.description = _description;
        product.location = _location;
        product.price = _price;

        emit ProductUpdated(
            _index,
            _name,
            _image,
            _description,
            _location,
            _price
        );

    }


/**
     * @notice Remove a product from the marketplace
     * @param _index The index of the product to remove
*/
    function removeProduct(uint _index) public onlyProductOwner(_index) {
        // Get the product from the mapping
        Product storage product = products[_index];

        // Remove the product from the mapping
        delete products[_index];

        // Decrement the productsLength to reflect the removal
        productsLength--;
        emit ProductRemoved(_index);
    }

/**
 * @dev Add a new product to the marketplace.
 * @param _name The name of the product.
 * @param _image The URL of the product image.
 * @param _description The description of the product.
 * @param _location The location of the product.
 * @param _price The price of the product in cUSD.
 * @notice This function allows users to add a new product to the marketplace.
 * @dev Only the product owner can call this function.
 * @dev The product name must not be empty and should be less than or equal to 100 characters.
 * @dev The product image URL must not be empty.
 * @dev The product description must not be empty.
 * @dev The product location must not be empty.
 * @dev The product price must be greater than zero.
 * @return The index of the newly added product.
*/
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

        emit ProductAdded(
            productsLength - 1,
            msg.sender,
            _name,
            _image,
            _description,
            _location,
            _price
        );
        
    }

/**
 * @dev Read the details of a product from the marketplace.
 * @param _index The index of the product to read.
 * @notice This function allows users to read the details of a product from the marketplace.
 * @dev The product index must be valid.
 * @return The address of the product owner.
 * @return The name of the product.
 * @return The URL of the product image.
 * @return The description of the product.
 * @return The location of the product.
 * @return The price of the product in cUSD.
 * @return The number of times the product has been sold.
*/
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

/**
 * @dev Buy a product from the marketplace.
 * @param _index The index of the product to buy.
 * @notice This function allows users to buy a product from the marketplace.
 * @dev The product index must be valid.
 * @dev The buyer must send enough funds to purchase the product.
 * @dev The product owner will receive the payment in cUSD tokens.
 * @dev The product's sold count will be incremented.
*/
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


/**
 * @dev Get the number of products stored in the marketplace.
 * @notice This function returns the number of products currently stored in the marketplace.
 * @return The number of products stored in the marketplace.
*/
    function getProductsLength() public view returns (uint) {
        return productsLength;
    }

}
