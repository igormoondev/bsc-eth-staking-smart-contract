// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract ERC20_Fountain {
    using SafeMath for uint256;
    //ERC 20 standard for the number of decimals the token uses.
    uint8 public decimals;
    //tracks total existing number of tokens. named to match ERC-20 standard (see https://eips.ethereum.org/EIPS/eip-20)
    uint256 public totalSupply;
    //token name
    string public name;
    //token symbol
    string public symbol;
    // track token balances
    mapping(address => uint256) public tokenBalanceLedger_;
    //track approved addresses to allow transferFrom functionality - stored as allowance[from][spender] = allowance that [spender] is approved to send from [from]
    //named to match ERC-20 standard
    mapping(address => mapping(address => uint256)) public allowance;
    //EVENTS
    //when a transfer is completed
    //also emitted for token mint/burn events, in which cases, respectively, from/to is set to the 0 address (matches ERC20 standard)
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokensTransferred
    );
    // ERC20 compliance
    //when the tokenOwner address adjusts the allowance that the approvedAddress is allowed to transfer from the holdings of tokenOwner
    //relevant to transferFrom functionality
    event Approval(
        address indexed tokenOwner,
        address indexed approvedAddress,
        uint256 newAllowance
    );

    constructor(
        uint8 _decimals,
        string memory _name,
        string memory _symbol
    ) {
        decimals = _decimals;
        name = _name;
        symbol = _symbol;
    }

    /// @notice transfers tokens from message sender to another address
    function transfer(address toAddress, uint256 amountTokens)
        external
        returns (bool)
    {
        require(
            (amountTokens <= tokenBalanceLedger_[msg.sender]),
            "ERC20: Token balance is insufficient for transfer action."
        );
        transferInternal(msg.sender, toAddress, amountTokens);
        return true;
    }

    /// @notice sets approved amount of tokens that an external address can transfer on behalf of the user
    function approve(address approvedAddress, uint256 amountTokens)
        external
        returns (bool)
    {
        allowance[msg.sender][approvedAddress] = amountTokens;
        emit Approval(msg.sender, approvedAddress, amountTokens);
        return true;
    }

    /// @notice increases approved amount of tokens that an external address can transfer on behalf of the user
    function increaseAllowance(address approvedAddress, uint256 amountTokens)
        external
        returns (bool)
    {
        uint256 pastAllowance = allowance[msg.sender][approvedAddress];
        uint256 newAllowance = pastAllowance.add(amountTokens);
        allowance[msg.sender][approvedAddress] = newAllowance;
        emit Approval(msg.sender, approvedAddress, newAllowance);
        return true;
    }

    /// @notice decreases approved amount of tokens that an external address can transfer on behalf of the user
    function decreaseAllowance(address approvedAddress, uint256 amountTokens)
        external
        returns (bool)
    {
        uint256 pastAllowance = allowance[msg.sender][approvedAddress];
        uint256 newAllowance = pastAllowance.sub(amountTokens);
        allowance[msg.sender][approvedAddress] = newAllowance;
        emit Approval(msg.sender, approvedAddress, newAllowance);
        return true;
    }

    modifier checkTransferApproved(address fromAddress, uint256 amountTokens) {
        if (fromAddress != msg.sender) {
            require(
                allowance[fromAddress][msg.sender] <= amountTokens,
                "ERC20: Transfer not authorized -- allowance insufficient."
            );
        }
        _;
    }

    /// @notice transfers tokens from one address to another
    function transferFrom(
        address payable fromAddress,
        address payable toAddress,
        uint256 amountTokens
    ) external checkTransferApproved(fromAddress, amountTokens) returns (bool) {
        // make sure sending address has requested tokens
        require(
            (amountTokens <= tokenBalanceLedger_[fromAddress]),
            "ERC20: Transfer not allowed - insufficient funds available."
        );
        //update allowance (reduce it by tokens to be sent)
        uint256 pastAllowance = allowance[fromAddress][msg.sender];
        uint256 newAllowance = pastAllowance.sub(amountTokens);
        allowance[fromAddress][msg.sender] = newAllowance;
        //make the transfer internally
        transferInternal(msg.sender, toAddress, amountTokens);
        return true;
    }

    /// @notice returns token balance of desired address
    /// @dev conforms to ERC-20 standard
    function balanceOf(address userAddress)
        external
        view
        returns (uint256 balance)
    {
        return (tokenBalanceLedger_[userAddress]);
    }

    //adds new tokens to total token supply and gives them to the user
    function mint(address userAddress, uint256 amountTokens) internal {
        require(
            userAddress != address(0),
            "ERC20: cannot mint tokens for zero address."
        );
        totalSupply = totalSupply.add(amountTokens);
        tokenBalanceLedger_[userAddress] = tokenBalanceLedger_[userAddress].add(
            amountTokens
        );
        emit Transfer(address(0), userAddress, amountTokens);
    }

    //destroys tokens, i.e. removes them from total token supply and subtracts them from user balance
    function burn(address userAddress, uint256 amountTokens) internal {
        require(
            userAddress != address(0),
            "ERC20: cannot burn tokens for zero address."
        );
        require(
            amountTokens <= tokenBalanceLedger_[userAddress],
            "Insufficient funds available."
        );
        tokenBalanceLedger_[userAddress] = tokenBalanceLedger_[userAddress].sub(
            amountTokens
        );
        totalSupply = totalSupply.sub(amountTokens);
        emit Transfer(userAddress, address(0), amountTokens);
    }

    //manages transfers of tokens in both transfer and transferFrom functions
    function transferInternal(
        address fromAddress,
        address toAddress,
        uint256 amountTokens
    ) internal {
        require(
            fromAddress != address(0),
            "ERC20: cannot transfer from zero address"
        );
        require(
            toAddress != address(0),
            "ERC20: cannot transfer to zero address"
        );
        tokenBalanceLedger_[fromAddress] = tokenBalanceLedger_[fromAddress].sub(
            amountTokens
        );
        tokenBalanceLedger_[toAddress] = tokenBalanceLedger_[toAddress].add(
            amountTokens
        );
        emit Transfer(fromAddress, toAddress, amountTokens);
    }

    function createTokens(uint256 amountToMint) public {
        mint(msg.sender, amountToMint);
    }
}
