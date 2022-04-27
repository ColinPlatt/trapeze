// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import 'forge-std/Test.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';


import '../trapeze.sol';


contract trapezeTest is Test {
    using Strings for uint256;

    trapeze nft;

    function setUp() public {
        nft = new trapeze();
    }

    function testInvariantMetaData() public {
        assertEq(nft.name(), 'trapeze');
        assertEq(nft.symbol(), unicode'🪤');
    }

    function testClaiming() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();
        assertEq(nft.balanceOf(beef), 1);
        assertEq(nft.ownerOf(nft.getTokenId(beef)), beef);
    }

    function testFailClaimMultiple() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();

        nft.claim();

        assertEq(nft.balanceOf(beef), 1);
        assertEq(nft.ownerOf(nft.getTokenId(beef)), beef);
    }

    function testDismissing() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();

        nft.dismiss();
        assertEq(nft.balanceOf(beef), 0);

    }

    function testReclaim() public {
        
        uint256 sequence;

        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();
        sequence = nft.getSequence(beef);
        vm.stopPrank();

        vm.startPrank(address(0xABC));
        nft.claim();
        vm.stopPrank();

        vm.startPrank(address(0xABC));
        nft.dismiss();
        assertEq(nft.getSequence(beef), sequence);
 
    }

    function testFailTransfer() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();

        nft.transferFrom(beef, address(0xDAD), nft.getTokenId(beef));
    }

    function testFailSafeTransferData() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();

        nft.safeTransferFrom(beef, address(0xDAD), nft.getTokenId(beef), abi.encodePacked('test'));
    }

    function testFailSafeTransfer() public {
        
        address beef = address(0xBEEF);

        vm.startPrank(beef);
        nft.claim();

        nft.safeTransferFrom(beef, address(0xDAD), nft.getTokenId(beef));
    }

    function _testCoordinates() public{

        uint256 group;
        uint256 x;
        uint256 y;

        for (uint256 i = 1; i<200; i++) {
            (group, x, y) = nft.getCoordinates(i);

            emit log_string(string.concat('i: ', i.toString(),' x: ', group.toString(),' y: ', x.toString(), ' column: ', y.toString()));
        }

    }

    function testPricing() public{

        for (uint256 i = 1; i<3 days; i+=3600) {
            emit log_uint(nft.getUpdatePrice(10 ether, i));
        }

    }





}