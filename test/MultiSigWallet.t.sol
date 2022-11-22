// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet msw;

    function setUp() public {
        address[] memory add = new address[](5);
        add[0] = address(0x0000000000000000000000000000000000000001);
        add[1] = address(0x0000000000000000000000000000000000000002);
        add[2] = address(0x0000000000000000000000000000000000000003);
        add[3] = address(0x0000000000000000000000000000000000000004);
        add[4] = address(0x0000000000000000000000000000000000000005);

        msw = new MultiSigWallet(add, 3);
    }

    /* TEST PRIMIVITES */

    function primitiveSubmitTrasaction() private {}

    function primitiveConfirmTrasaction() private {}

    function primitiveRevokeTrasaction() private {}

    function primitiveExecuteTrasaction() private {}

    /* TEST FUNCTIONS */
    function testSubmitTransactionNotOwner() public {
        vm.startPrank(address(0x6));
        vm.expectRevert("Not owner.");
        msw.submitTransaction(
            payable(0x0000000000000000000000000000000000000001),
            1 ether,
            "0x00"
        );
        vm.stopPrank();
    }

    function testSubmitTransactionOk() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";

        vm.startPrank(sender);
        vm.deal(sender, 10 ether);
        assertEq(sender.balance, 10 ether);
        msw.submitTransaction(receiver, value, data);

        assertEq(msw.getTransactionsLength(), 1);
        assertEq(msw.getTxAddress(0), receiver);
        assertEq(msw.getTxVal(0), value);
        assertEq(msw.getTxBytes(0), "0x00");
        assertEq(msw.getTxExecuted(0), false);
        assertEq(msw.getTxNumConfirmations(0), 0);

        vm.stopPrank();
    }

    function testConfirmTransactionNotOwner() public {}

    function testConfirmTransactionNotExists() public {}

    function testConfirmTransactionOk() public {}

    function testConfirmTransactionAlreadyConfirmed() public {}

    function textConfirmTransactionAlreadyExecuted() public {}

    function testRevokeTransactionNotOwner() public {}

    function testRevokeTransactionNotExists() public {}

    function testRevokeTransactionAlreadyExecuted() public {}

    function testRevokeTransactionNotConfirmed() public {}

    function textRevokeTransactionOk() public {}

    function testExecuteTransactionNotOwner() public {}

    function testExecuteTransactionNotExists() public {}

    function testExecuteTransactionAlreadyExecuted() public {}

    function testExecuteTransactionNotEnoughConfirmations() public {}

    function textExecuteTransactionOk() public {}
}
