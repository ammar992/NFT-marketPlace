// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract NFTMarketPlace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _soldItems;

    uint256 listingPrice = 0.0025 ether;
    

    uint256 private constant DURATION = 7 days;


    uint256 public nftId;
    address public nft;
    address payable public seller;
    uint256 public startingPrice;
    uint256 public discountRate;
    uint256 public startAt;
    uint256 public expiresAt;


    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 _tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed _tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor(uint256 _startingPrice,uint256 _discountRate,address _nft,uint256 _nftId) ERC721("NFT Token", "NT") {
        owner = payable(msg.sender);
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;


        require(_startingPrice>=_discountRate + DURATION,"Starting price is too low");

        nft = _nft;
        nftId = _nftId;

    }



modifier onlyOwner{
    require(msg.sender==owner,"You are not an owner");
    _;
}

    function updateListingPrice(
        uint256 _ListingPrice
    ) public payable onlyOwner {
        listingPrice = _ListingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //////////////////////////// Lets create NFT functoion Token

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "You are not an owner of this NFT"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _soldItems.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    function BuyNFt(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;
        require(msg.value == price, "Please submit the asking price in order");
        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _soldItems.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoleItemCount = itemCount - _soldItems.current();
        uint index = 0;

        MarketItem[] memory items = new MarketItem[](unSoleItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[index] = currentItem;
                index += 1;
            }
        }

        return items;
    }




function FetchMyNFT()public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 index = 0;


        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory item = new MarketItem[](itemCount);
            for (uint256 i=0;i<totalCount;i++){
                if (idMarketItem[i+1].owner==msg.sender){
                    uint256 currentId = i+1;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    item[index] = currentItem;
                    index++;
                }
            }
            return item;
    } 


    function _transferFrom(address _from,address _to,uint256 _nftId)external {};

   function getPrice ()public view returns(uint256){
        uint256 time = block.timestamp - startAt;
        uint256 discount = discountRate * time;
        return startingPrice - discount;
    }

    function buy()public payable{
        require(block.timestamp < expiresAt,"This nft biding has ended");

        uint256 price = getPrice();
        require(msg.value>=price,"The amount of ether is less then the price");

        nft._transferFrom(seller,msg.sender,nftId);

uint256 refund = msg.value - price; 

if(refund>0){
    payable(msg.sender).transfer(refund);
}

selfdestruct(seller);



    }





}
