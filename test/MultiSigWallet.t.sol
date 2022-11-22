// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    /* COMMON VARIABLES */

    MultiSigWallet msw;
    address sender = address(0x5);
    address confirmer4 = address(0x4);
    address confirmer3 = address(0x3);
    address payable receiver1 = payable(address(0x1));
    uint256 value = 1 ether;
    bytes data = "0x00";
    bool executed = false;
    uint8 numConfirmations = 0;

    function setUp() public {
        //Define owners array
        address[] memory add = new address[](6);
        add[0] = address(0x0000000000000000000000000000000000000001);
        add[1] = address(0x0000000000000000000000000000000000000002);
        add[2] = address(0x0000000000000000000000000000000000000003);
        add[3] = address(0x0000000000000000000000000000000000000004);
        add[4] = address(0x0000000000000000000000000000000000000005);
        add[5] = address(0x0000000000000000000000000000000000000009);

        //Contract instance
        msw = new MultiSigWallet(add, 3);

        //Fund wallet and transfer funds to the smart contract
        vm.startPrank(add[5]);
        vm.deal(add[5], 20 ether);
        (bool success, ) = address(msw).call{value: 20 ether}("");
        assertEq(success, true);
        vm.stopPrank();
    }

    /* PRIMITIVES FUNCTIONS FOR REPETEAD OPERATIONS */

    function primitiveSubmitTrasaction(
        address _sender,
        address payable _receiver,
        uint256 _value,
        bytes memory _data
    ) private returns (uint256 txIndex) {
        vm.startPrank(_sender);
        vm.deal(_sender, 10 ether);
        assertEq(_sender.balance, 10 ether);
        msw.submitTransaction(_receiver, _value, _data);
        vm.stopPrank();
        return msw.getTransactionsLength() - 1;
    }

    function primitiveConfirmTrasaction(uint256 _txIndex) private {
        msw.confirmTransaction(_txIndex);
    }

    function primitiveRevokeTrasaction(uint256 _txIndex) private {
        msw.revokeTransaction(_txIndex);
    }

    function primitiveExecuteTrasaction(uint256 _txIndex) private {
        msw.executeTransaction(_txIndex);
    }

    function primitiveCheckTransaction(
        uint256 _txIndex,
        address _receiver,
        uint256 _value,
        bytes memory _data,
        bool _executed,
        uint8 _confirmations
    ) private {
        assertEq(msw.getTxAddress(_txIndex), _receiver);
        assertEq(msw.getTxVal(_txIndex), _value);
        assertEq(msw.getTxBytes(_txIndex), _data);
        assertEq(msw.getTxExecuted(_txIndex), _executed);
        assertEq(msw.getTxNumConfirmations(_txIndex), _confirmations);
    }

    function primitiveCheckTransactionIsConfirmed(
        uint256 _txIndex,
        address _add
    ) private view returns (bool confirmation) {
        return msw.getTransactionConfirmation(_txIndex, _add);
    }

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

    function testSubmitTransactionOk() public returns (uint256 txIndex) {
        txIndex = primitiveSubmitTrasaction(sender, receiver1, value, data);

        primitiveCheckTransaction(
            txIndex,
            receiver1,
            value,
            data,
            executed,
            numConfirmations
        );
        return txIndex;
    }

    function testConfirmTransactionNotOwner() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.expectRevert("Not owner.");
        primitiveConfirmTrasaction(txIndex);
    }

    function testConfirmTransactionNotExists() public {
        vm.startPrank(sender);
        vm.expectRevert("Invalid transaction id.");
        primitiveConfirmTrasaction(999999);
        vm.stopPrank();
    }

    function testConfirmTransactionOk() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        primitiveCheckTransaction(
            txIndex,
            receiver1,
            value,
            data,
            executed,
            numConfirmations + 1
        );
        vm.stopPrank();
    }

    function testConfirmTransactionAlreadyConfirmed() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        primitiveCheckTransaction(
            txIndex,
            receiver1,
            value,
            data,
            executed,
            numConfirmations + 1
        );
        vm.expectRevert("Transaction already confirmed by sender.");
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();
    }

    function testRevokeTransactionNotOwner() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.expectRevert("Not owner.");
        primitiveRevokeTrasaction(txIndex);
    }

    function testRevokeTransactionNotExists() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.expectRevert("Invalid transaction id.");
        primitiveRevokeTrasaction(999999);
        vm.stopPrank();
    }

    function testRevokeTransactionNotConfirmed() public {
        address notConfirmer = address(0x4);

        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(notConfirmer);
        vm.expectRevert("Transaction not confirmed by sender.");
        primitiveRevokeTrasaction(txIndex);
        vm.stopPrank();
    }

    function textRevokeTransactionOk() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        primitiveRevokeTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), false);
        vm.stopPrank();
    }

    function testExecuteTransactionNotOwner() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        vm.stopPrank();

        vm.expectRevert("Not owner.");
        primitiveExecuteTrasaction(txIndex);
    }

    function testExecuteTransactionNotExists() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        vm.expectRevert("Invalid transaction id.");
        primitiveExecuteTrasaction(999999);
        vm.stopPrank();
    }

    function testExecuteTransactionNotEnoughConfirmations() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.expectRevert("Not enough confirmations.");
        primitiveExecuteTrasaction(txIndex);
        vm.stopPrank();
    }

    function textExecuteTransactionOk() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        primitiveExecuteTrasaction(txIndex);
        primitiveCheckTransaction(txIndex, receiver1, value, data, true, 3);
        vm.stopPrank();
    }

    function testExecuteTransactionAlreadyExecuted() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveExecuteTrasaction(txIndex);
        vm.stopPrank();
    }

    function testConfirmTransactionAlreadyExecuted() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();
    }

    function testRevokeTransactionAlreadyExecuted() public {
        uint256 txIndex = testSubmitTransactionOk();

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        assertEq(primitiveCheckTransactionIsConfirmed(txIndex, sender), true);
        vm.stopPrank();

        vm.startPrank(confirmer4);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer4),
            true
        );

        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        assertEq(
            primitiveCheckTransactionIsConfirmed(txIndex, confirmer3),
            true
        );
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveRevokeTrasaction(txIndex);
        vm.stopPrank();
    }
}
