// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet msw;

    function setUp() public {
        address[] memory add = new address[](6);
        add[0] = address(0x0000000000000000000000000000000000000001);
        add[1] = address(0x0000000000000000000000000000000000000002);
        add[2] = address(0x0000000000000000000000000000000000000003);
        add[3] = address(0x0000000000000000000000000000000000000004);
        add[4] = address(0x0000000000000000000000000000000000000005);
        add[5] = address(0x0000000000000000000000000000000000000009);

        msw = new MultiSigWallet(add, 3);

        vm.startPrank(add[5]);
        vm.deal(add[5], 20 ether);
        (bool success, ) = address(msw).call{value: 20 ether}("");
        assertEq(success, true);
        vm.stopPrank();
    }

    /* TEST PRIMITIVES */

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
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );
    }

    function testConfirmTransactionNotOwner() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.expectRevert("Not owner.");
        primitiveConfirmTrasaction(txIndex);
    }

    function testConfirmTransactionNotExists() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        vm.expectRevert("Invalid transaction id.");
        primitiveConfirmTrasaction(999999);
        vm.stopPrank();
    }

    function testConfirmTransactionOk() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations + 1
        );
        vm.stopPrank();
    }

    function testConfirmTransactionAlreadyConfirmed() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        primitiveCheckTransaction(
            txIndex,
            receiver,
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
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.expectRevert("Not owner.");
        primitiveRevokeTrasaction(txIndex);
    }

    function testRevokeTransactionNotExists() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.expectRevert("Invalid transaction id.");
        primitiveRevokeTrasaction(999999);
        vm.stopPrank();
    }

    function testRevokeTransactionNotConfirmed() public {
        address sender = address(0x5);
        address notConfirmer = address(0x4);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(notConfirmer);
        vm.expectRevert("Transaction not confirmed by sender.");
        primitiveRevokeTrasaction(txIndex);
        vm.stopPrank();
    }

    function textRevokeTransactionOk() public {
        address sender = address(0x5);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        primitiveRevokeTrasaction(txIndex);
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );
        vm.stopPrank();
    }

    function testExecuteTransactionNotOwner() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.expectRevert("Not owner.");
        primitiveExecuteTrasaction(txIndex);
    }

    function testExecuteTransactionNotExists() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        vm.expectRevert("Invalid transaction id.");
        primitiveExecuteTrasaction(999999);
        vm.stopPrank();
    }

    function testExecuteTransactionNotEnoughConfirmations() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.expectRevert("Not enough confirmations.");
        primitiveExecuteTrasaction(txIndex);
        vm.stopPrank();
    }

    function textExecuteTransactionOk() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        primitiveExecuteTrasaction(txIndex);
        primitiveCheckTransaction(txIndex, receiver, value, data, true, 3);
        vm.stopPrank();
    }

    function testExecuteTransactionAlreadyExecuted() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveExecuteTrasaction(txIndex);
        vm.stopPrank();
    }

    function testConfirmTransactionAlreadyExecuted() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();
    }

    function testRevokeTransactionAlreadyExecuted() public {
        address sender = address(0x5);
        address confirmer2 = address(0x4);
        address confirmer3 = address(0x3);
        address payable receiver = payable(address(0x1));
        uint256 value = 1 ether;
        bytes memory data = "0x00";
        bool executed = false;
        uint8 numConfirmations = 0;

        uint256 txIndex = primitiveSubmitTrasaction(
            sender,
            receiver,
            value,
            data
        );
        primitiveCheckTransaction(
            txIndex,
            receiver,
            value,
            data,
            executed,
            numConfirmations
        );

        vm.startPrank(sender);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer2);
        primitiveConfirmTrasaction(txIndex);
        vm.stopPrank();

        vm.startPrank(confirmer3);
        primitiveConfirmTrasaction(txIndex);
        primitiveExecuteTrasaction(txIndex);
        vm.expectRevert("Transaction already executed.");
        primitiveRevokeTrasaction(txIndex);
        vm.stopPrank();
    }
}
