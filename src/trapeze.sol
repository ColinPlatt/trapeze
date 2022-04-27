//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';


// exponential decay on cost to change (target 0.1 MATIC after 24 hours)
// owner pays if updating more than once per day
// burned NFT metadata still lives, all fees go to the contract
// remint after burn reaquire original sequence


error nonTransferrable();

contract trapeze is ERC721 {

    uint256 TILE_SIZE = 300; // each NFT metadata is 300x300 

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 sequence; // counter for minting sequenece to place coordinates
    mapping(uint256 => uint256) public mintSequence; //mintSequence[NFTID(address)][sequence]
    
    //metadata imagery storage 
    struct ELEMENT {
        bytes4 functionSig;
        string props;
        string children;
        uint256 lastUpdate;
    }

    struct PICTURE {
        ELEMENT[20] elements;
    }

    mapping(uint256 => PICTURE) private pictures; //pictures[NFTID(address)][PICTURE]


    /*//////////////////////////////////////////////////////////////
                            VIEW-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        
        return 'x';
    }

    // Token IDs are the uint256 representation of their owners' address
    function getTokenId(address tokenAddr) public pure returns (uint256) {
        return uint256(uint160(address(tokenAddr)));
    }

    function getSequence(address tokenAddr) public view returns (uint256) {
        return mintSequence[getTokenId(tokenAddr)];
    }

    //Inspired by https://github.com/pxlgen/contracts/blob/master/contracts/PxlGen.sol
    function getCoordinates(address tokenAddr) public view returns (uint256 group, uint256 x, uint256 y) {
        uint256 index = mintSequence[getTokenId(tokenAddr)];
        require(index >= 1, "Invalid index");
        group = index / 100;
        uint256 order = (index-1) % 100;
        
        x = order % 10 * TILE_SIZE;
        y = order / 10 * TILE_SIZE;

        return (group, x, y);
    }

    function getCoordinates(uint256 index) public view returns (uint256 group, uint256 x, uint256 y) {
        require(index >= 1, "Invalid index");
        group = index / 100;
        uint256 order = (index-1) % 100;
        
        x = order % 10 * TILE_SIZE;
        y = order / 10 * TILE_SIZE;

        return (group, x, y);
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/


   

    /*//////////////////////////////////////////////////////////////
                        MINT AND BURN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NFT IDs are assigned to an address (and are thus not sequential), at claiming sequence kept and matched to the index
    function claim() public {
        
        //check that a wallet has not been assigned an ID before, if not increment the sequence counter
        if (mintSequence[getTokenId(msg.sender)] != 0) {
            sequence++;
            mintSequence[getTokenId(msg.sender)] = sequence; 
        } else {
            // pay me
        }
        _mint(msg.sender, getTokenId(msg.sender));
    }

    // TODO: redirect burnt payables to contract address
    function dismiss() public {
        _burn(getTokenId(msg.sender));
    }

    /*//////////////////////////////////////////////////////////////
                            TREASURY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getUpdatePrice(uint256 value, uint256 t) public pure returns (uint256 price) {
        value >>= (t / 4 hours);
        t %= 1 days;
        price = value - value * t / 1 days / 2;
    }

    /*//////////////////////////////////////////////////////////////
            OVERRIDE TRANSFERS TO MAKE NON-TRANSFERRABLE
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // revert with error if not a burn or mint
        //require(from == address(0) || to == address(0), "TRAPEZE: NON TRANSFERRABLE");
        if(from != address(0) && to != address(0)) {
            revert nonTransferrable();
        }
    }


    constructor () ERC721('trapeze', unicode'🪤') {}

}