//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721} from 'solmate/tokens/ERC721.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';

contract trapeze is ERC721 {

    event BurnMessage(string message, address indexed addr);


    

    function tokenURI(uint256 id) public view override returns (string memory) {
        return 'x';
    }

    /*//////////////////////////////////////////////////////////////
            OVERRIDE ALL TRANSFERS TO MAKE NON-TRANSFERRABLE
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to == address(0), "NON_TRANSFERRABLE");

        emit BurnMessage('burned' , from);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to == address(0), "NON_TRANSFERRABLE");

        emit BurnMessage('burned' , from);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to == address(0), "NON_TRANSFERRABLE");

        emit BurnMessage(string(abi.encodePacked(data)), from);
    }

    constructor () ERC721('trapeze', unicode'🪤') {}

}