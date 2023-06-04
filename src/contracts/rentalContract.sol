//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../../node_modules/ethereum-datetime/contracts/DateTime.sol";

contract rentalContract is ERC721, Ownable, DateTime{

    //Variables
    publicNotary public publicnotary;
    bool public lock;

    //Mappings
    mapping(uint256 => uint256) public assetFee; // Stores the total fees for each asset
    mapping(uint256 => address) public tokenTenant; // Stores the tenant of each asset
    mapping(uint256 => uint256) public totalMonthsUnpaid; // Stores the accumulated months the tenant doesn't paid
    mapping(uint256 => mapping(bytes32 => uint256)) public tokenCharges; // Stores the monthly charge for each asset
    mapping(uint256 => mapping(bytes32 => uint256)) public tokenPayments; // Stores the monthly payments for each asset
    mapping(uint256 => uint256) public lastTokenPayment; // Stores the date of the last payment made for each asset
    mapping(uint256 => uint256) public rentDate; // Stores the rent date of each asset
    mapping(uint256 => uint256) public tokenMonthlyPrice; // Stores the monthly price of each asset

    //Events
    event assetBought(address, uint256);
    event monthlyPay(address, uint256);

    //Structs
    struct publicNotary{ 
        string name; 
        string firstSurname; 
        string id; //Personal ID
        uint256 NotaryID; // Public notary ID
    }

    constructor(string memory notaryName, string memory firstSurname, string memory id, uint256 NotaryID) 
                ERC721("LandRent", "LR"){
        //Set the public notary data
        publicnotary = publicNotary(notaryName, firstSurname, id, NotaryID);
    }

    //Modifiers
    modifier onlyTenant(uint256 tokenId){
        require(msg.sender == tokenTenant[tokenId]);
        _;
    }

    modifier mutex(){
        require(!lock);
        lock = true;
        _;
        lock = false;
    }

    function mint(uint256 tokenId, uint256 price) external onlyOwner {
        tokenMonthlyPrice[tokenId] = price; //Price is passed in Wei
        _mint(msg.sender, tokenId); 
    }

    function rentAsset(uint256 tokenId) external payable {
        require(tokenTenant[tokenId] == address(0), "Token already rented");
        require(msg.sender != ownerOf(tokenId), "You are the asset owner");
        require(assetFee[tokenId] == 0, "Asset has fees to pay");

        uint256 deposit = tokenMonthlyPrice[tokenId]; //Deposit is the equivalent to pay one month
        require(msg.value == deposit, "Entry fee is not correct"); 
        
        address tokenOwner = ownerOf(tokenId); 
                
        rentDate[tokenId] = block.timestamp; 
        tokenTenant[tokenId] = msg.sender;
        payEntryFee(tokenOwner, msg.value);
        
        emit assetBought(msg.sender, tokenId);
    }

    function pay(address tokenOwner, uint256 price) private {
        (bool success, ) = payable(tokenOwner).call{value: price}(""); //Pay to tokenOwner
        require(success, "Entry fee payment failed");
    }

    //@audit-ok checks, effects, interactions pattern used
    function monthlyPayment(uint256 tokenId) external payable onlyTenant(tokenId){
        bytes32 date = keccak256(abi.encodePacked(getYear(block.timestamp), getMonth(block.timestamp))); // Hashing the year and the month payment
        require(tokenPayments[tokenId][date] == 0, "Month already paid");

        uint256 monthlyPrice = tokenMonthlyPrice[tokenId];
        require(msg.value == monthlyPrice, "Payment not correct");

        address tokenOwner = ownerOf(tokenId);
        
        lastTokenPayment[tokenId] = block.timestamp; 
        tokenPayments[tokenId][date] = monthlyPrice; 
        pay(tokenOwner, msg.value);

        emit monthlyPay(msg.sender, tokenId); 
    }

    //Pay previous charges
    // @audit-ok -> The function doesn't follows checks, effects, interactions pattern but a mutex is used
    function payCharge(uint256 tokenId, uint16 year, uint8 month) public payable onlyTenant(tokenId) mutex {

        bytes32 date = keccak256(abi.encodePacked(year, month)); //Date hash
                                                                   //The year and month validity should be checked offchain

        require(tokenCharges[tokenId][date] > 0, "Month paid previously");

        uint256 monthlyPrice = tokenMonthlyPrice[tokenId];
        
        require(msg.value == monthlyPrice, "Payment must be the monthly price");

        address tokenOwner = ownerOf(tokenId);

        pay(tokenOwner, msg.value);

        tokenCharges[tokenId][date] = 0; //Delete the fee
        tokenPayments[tokenId][date] = monthlyPrice; //Register the payment
        assetFee[tokenId] -= monthlyPrice;
        totalMonthsUnpaid[tokenId] -=1;

    }

    //Token's owner can add a charge to a month
    function addCharge(uint256 tokenId, uint256 amount, uint16 year, uint8 month) external onlyOwner { 

        bytes32 date = keccak256(abi.encodePacked(year, month)); //Month and year hash
                                                                   //The year and month validity should be checked offchain
        require(tokenPayments[tokenId][date] == 0, "Month already paid"); 
       
        //Avoid owner set charges for future dates
        if(month >= getMonth(block.timestamp)){
            require(year < getYear(block.timestamp), "Impossible to add charge for future dates"); //Owner sets a charge for a month of the past year
        } else if(month < getMonth(block.timestamp)) {
            require(year <= getYear(block.timestamp), "Impossible to add charge for future dates"); //Owner sets a charge for a month of the current year
        } 
       
        uint16 yearAdquired = getYear(rentDate[tokenId]); 
        uint8 monthAdquired = getMonth(rentDate[tokenId]); 

        require(yearAdquired < year || yearAdquired == year && monthAdquired <= month, "Charges cannot be entered for dates prior to the purchase of the asset"); 

        assetFee[tokenId] += amount;
        tokenCharges[tokenId][date] += amount; 
        totalMonthsUnpaid[tokenId] +=1;

    }

    function seizeAsset(uint256 tokenId) external onlyOwner {
        require(totalMonthsUnpaid[tokenId] >= 5, "Tenant must debt at least 5 months");
        tokenTenant[tokenId] = address(0);
    }

    //Check if a month is already paid
    function getPayment(uint256 tokenId, uint16 year, uint8 month) external view returns(uint256){
        bytes32 date = keccak256(abi.encodePacked(year, month)); 
        return tokenPayments[tokenId][date]; 
    }

    //Get asset fees
    function getFees(uint256 tokenId) external view returns(uint256){
        return assetFee[tokenId];
    }

    //Get total of unpaid months
    function getUnpaidMonths(uint256 tokenId) external view returns(uint256){
        return totalMonthsUnpaid[tokenId];
    }

    //Get monthly price
    function getAssetPrice(uint256 tokenId) external view returns(uint256){
        return tokenMonthlyPrice[tokenId];
    }

    function accquiredDate(uint256 tokenId) external view returns(uint16, uint8){
        uint16 yearAdquired = getYear(rentDate[tokenId]); 
        uint8 monthAdquired = getMonth(rentDate[tokenId]); 
        return(yearAdquired, monthAdquired);
    }
}