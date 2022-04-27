//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import {utils} from './Utils.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';


// exponential decay on cost to change (target 0.1 MATIC after 24 hours)
// owner pays if updating more than once per day
// burned NFT metadata still lives, all fees go to the contract
// remint after burn reaquire original sequence


error nonTransferrable();

contract trapeze is ERC721 {
    using utils for uint256;

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

    mapping(uint256 => PICTURE) private pictures; //pictures[tokenId][PICTURE]


    /*//////////////////////////////////////////////////////////////
                            VIEW-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function returnPicture(uint256 tokenId) public view returns (string memory) {
        string memory _returnedElements;
        PICTURE storage picture = pictures[tokenId];

        if(picture.elements[0].functionSig == bytes4(0)){
            return ' ';
        }

        bool success;
        bytes memory data;

        for (uint256 i = 0; i < 20; i++) {
            if(picture.elements[i].functionSig != bytes4(0)) {
                (success, data) = address(this).staticcall(
                    abi.encodeWithSelector(
                        picture.elements[i].functionSig, 
                        picture.elements[i].props, 
                        picture.elements[i].children
                    )
                );
                _returnedElements = string.concat(_returnedElements, abi.decode(data, (string)));
            }
        }

        return _returnedElements;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //we return a URI for tokens which have been claimed and dismissed, but not for ones that have not been claimed
        require(getSequence(address(uint160(tokenId))) <= sequence, 'ERC721Metadata: URI query for nonexistent token');

        string memory returnedElements = returnPicture(tokenId);

        return svg._svg(
                string.concat(
                    viewBox(tokenId),
                    svg.prop('preserveAspectRatio', 'xMinYMin meet'),
                    svg.prop('style', 'background:#000', true)
                ),
                returnedElements
        );
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
        uint256 _sequence = mintSequence[getTokenId(tokenAddr)];
        require(_sequence >= 1, "Invalid sequence");
        group = _sequence / 100;
        uint256 order = (_sequence-1) % 100;
        
        x = order % 10 * TILE_SIZE;
        y = order / 10 * TILE_SIZE;

        return (group, x, y);
    }

    function getCoordinates(uint256 _sequence) public view returns (uint256 group, uint256 x, uint256 y) {
        require(_sequence >= 1, "Invalid sequence");
        group = _sequence / 100;
        uint256 order = (_sequence-1) % 100;
        
        x = order % 10 * TILE_SIZE;
        y = order / 10 * TILE_SIZE;

        return (group, x, y);
    }

    /*//////////////////////////////////////////////////////////////
                        SVG ELEMENT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function viewBox(uint256 tokenId) public view returns (string memory) {
        (,uint256 x, uint256 y) = getCoordinates(mintSequence[tokenId]);

        return svg.prop(
            'viewBox', 
            string.concat(
                utils.toString(x),
                ' ',
                utils.toString(y),
                ' 300 300'
            )
        );

    }

    function Circle(string memory props, string memory children) public pure returns (string memory) {
        return svg.circle(props, children);
    }

    function Ellipse(string memory props, string memory children) public pure returns (string memory) {
        return svg.ellipse(props, children);
    }

    function Line(string memory props, string memory children) public pure returns (string memory) {
        return svg.line(props, children);
    }

    function Polygon(string memory props, string memory children) public pure returns (string memory) {
        return svg.polygon(props, children);
    }

    function Polyline(string memory props, string memory children) public pure returns (string memory) {
        return svg.polyline(props, children);
    }

    function Rect(string memory props, string memory children) public pure returns (string memory) {
        return svg.rect(props, children);
    }

    function Text(string memory props, string memory children) public pure returns (string memory) {
        return svg.text(props, children);
    }

    function Animate(string memory props, string memory children) public pure returns (string memory) {
        return svg.animate(props);
    }

    function Filter(string memory props, string memory children) public pure returns (string memory) {
        return svg.filter(props, children);
    }

    function LinearGradient(string memory props, string memory children) public pure returns (string memory) {
        return svg.linearGradient(props, children);
    }

    function RadialGradient(string memory props, string memory children) public pure returns (string memory) {
        return svg.radialGradient(props, children);
    }

    /*//////////////////////////////////////////////////////////////
                    METADATA MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function updateElement(uint256 _tokenId, uint256 _slot, ELEMENT memory _el) public {
        require(_slot < 20, "TRAPEZE: SLOT INVALID");

        _el.lastUpdate = block.timestamp;

        pictures[_tokenId].elements[_slot] = _el;

    }

    function updateElement(address _tokenAddr, uint256 _slot, ELEMENT memory _el) public {
        require(_slot < 20, "TRAPEZE: SLOT INVALID");
        uint256 _tokenId = getTokenId(_tokenAddr);

        _el.lastUpdate = block.timestamp;

        pictures[_tokenId].elements[_slot] = _el;

    }

    function addBasicCircle(address tokenAddr, uint256 slot, uint256 cx, uint256 cy, uint256 r, string memory color) public {
        ELEMENT memory circle = ELEMENT({
            functionSig : this.Circle.selector,
            props : string.concat(
                    svg.prop('cx', cx.toString()),
                    svg.prop('cy', cy.toString()),
                    svg.prop('r', r.toString()),
                    svg.prop('fill', color)
                ),
            children : '',
            lastUpdate : 0
        });

        updateElement(tokenAddr, slot, circle);
    }


    /*//////////////////////////////////////////////////////////////
                        MINT AND BURN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initializePicture(uint256 tokenId) internal {
        ELEMENT memory blankEl = ELEMENT({
            functionSig : bytes4(0),
            props: '',
            children: '',
            lastUpdate: 1
        });        

        pictures[tokenId].elements[0] = blankEl; 
    }

    // NFT IDs are assigned to an address (and are thus not sequential), at claiming sequence kept and matched to the index
    function claim() public {
        
        //check that a wallet has not been assigned an ID before, if not increment the sequence counter
        if (mintSequence[getTokenId(msg.sender)] == 0) {
            sequence++;
            mintSequence[getTokenId(msg.sender)] = sequence;
            initializePicture(getTokenId(msg.sender)); 
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