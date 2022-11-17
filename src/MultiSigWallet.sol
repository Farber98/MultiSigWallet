// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* 
    REQUIREMENT: Let's create an multi-sig wallet.
    The wallet owners can
        * submit a transaction
        * approve and revoke approval of pending transcations
        * anyone can execute a transcation after enough owners has approved it. 
*/

contract MultiSigWallet {
    /*** STATE ****/
    address[] public owners;
    uint256 public confirmationsRequired;
    mapping(address => bool) public isOwner;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint256 numConfirmations;
    }

    Transaction[] public transactions;

    /*** EVENTS ****/
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    // Event emmited when eth is sent to this contract.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /*** LOGIC ****/

    constructor(address[] memory _owners, uint8 _confirmationsRequired) {
        require(
            _owners.length > 0 && _confirmationsRequired > 0,
            "Params must be greater than zero."
        );
        require(
            _confirmationsRequired <= _owners.length,
            "Invalid confirmations required."
        );

        for (uint8 i = 0; i < _owners.length; ) {
            require(_owners[i] != address(0), "Invalid address.");
            require(!isOwner[_owners[i]], "Duplicate owner.");

            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
            confirmationsRequired = _confirmationsRequired;

            unchecked {
                ++i;
            }
        }
    }

    // Permits an owner propose a transaction.
    function submitTransaction() external {}

    // Permits an owner confirm a transaction.
    function confirmTransaction() external {}

    // Permits an owner to execute a transaction if enough owners confirmed it.
    function executeTransaction() external {}

    // Permits an owner to revoke his previous confirmation of a transaction.
    function revokeTransaction() external {}
}
