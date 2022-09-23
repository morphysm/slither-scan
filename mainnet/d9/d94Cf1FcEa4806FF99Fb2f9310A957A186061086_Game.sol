// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";


contract GameDirectory {
  
  // directory of user wallets => owned game contracts
  mapping ( address => address ) public hostedGames;

  // ERC20 contract address for $CHIP tokens to be used in games
  ERC20 public immutable chips;

  // error for when host address is already hosting a game
  error AlreadyHostingAGame();

  // event for tracking game creation and host address
  event GameCreated(address indexed game, address indexed host);


  constructor( ERC20 chips_ ) {

    // set chips in the constructor. This cannot be changed once launched
    chips = chips_;
  }


  // create and assign a Game contract to a host address if one doesn't exist
  function createGame() external {

    // if the host address is already hosting a game, throw an error
    if ( hostedGames[msg.sender] != address(0) ) { revert AlreadyHostingAGame(); }

    // create a game
    address game = address( new Game( msg.sender, chips) );

    // save the game address to the host address
    hostedGames[ msg.sender ] = game;

    // game has been created
    emit GameCreated(game, msg.sender);
  }
}  


contract Game {

  /////////////////////////////////////////////////////////////////////////////////
  //                             CONTRACT VARIABLES                              //
  /////////////////////////////////////////////////////////////////////////////////


  // internal credits for each player in the game
  mapping(address => uint256) public gameCredits;

  // total internal credits assigned in the game
  uint256 public totalGameCredits;

  // ERC20 token contract for the $CHIP tokens used in the game
  ERC20 public immutable pokerDaoChips;

  // mapping of addresses that can change internal credits
  mapping(address => bool) public isAdmin;

  // error for when the internal credits don't match the contract's $CHIP balance
  error NotEnoughCredits();

  // event for tracking player credit balances
  event CreditsUpdated(address indexed player, uint256 amount, bool isAdded);

  // event for tracking admins
  event AdminUpdated(address indexed admin, address indexed caller, bool isAdded);

  // modifier to control access of protected functions
  modifier onlyAdmin() {
    require(isAdmin[msg.sender], "UNAUTHORIZED");
    _;
  }

  constructor(address host_, ERC20 pokerDaoChips_) {
    // set the ERC20 token contract
    pokerDaoChips = pokerDaoChips_;

    // add the host as an admin
    isAdmin[host_] = true;
  }


  /////////////////////////////////////////////////////////////////////////////////
  //                                USER INTERFACE                               //
  /////////////////////////////////////////////////////////////////////////////////


  // player post CHIPS for credit
  function postChips(uint256 amount_) external {

    // increase the player credit by the posted amount
    gameCredits[msg.sender] += amount_;

    // increase the total game credits in the game by the amount the player buys in for
    totalGameCredits += amount_;

    // transfer the $CHIP token from the user's wallet to the game contract by the buy in amount
    pokerDaoChips.transferFrom(msg.sender, address(this), amount_);

    // credits have been added to player
    emit CreditsUpdated(msg.sender, amount_, true);
  }


  // player removing credits from the game
  function withdrawChips(uint256 amount_) external {

    // if the amount of chips returned to the player exceeds their internal credit balance, throw an error
    if ( amount_ > gameCredits[msg.sender] )  { revert NotEnoughCredits(); }
    
    // decrease the amount of internal credits of the player by the cash out amount
    gameCredits[msg.sender] -= amount_;

    // decrease the total amount of internal credits in the game
    totalGameCredits -= amount_;

    // transfer $CHIP from the player 
    pokerDaoChips.transfer(msg.sender, amount_);

    // credits have been deducted from player
    emit CreditsUpdated(msg.sender, amount_, false);
  }

   // player tipping credits to the game
  function tip(uint256 amount_) external {

    // if the amount of chips returned to the player exceeds their internal credit balance, throw an error
    if ( amount_ > gameCredits[msg.sender] )  { revert NotEnoughCredits(); }
    
    // decrease the amount of internal credits of the player by the cash out amount
    gameCredits[msg.sender] -= amount_;

    // reduce the total amount of internal credits in the game
    totalGameCredits -= amount_;

    // credits have been deducted from player
    emit CreditsUpdated(msg.sender, amount_, false);
  }


  // HOST ONLY: increase credits from a player. This is to track when a player keeps their winnings as in game credits.
  function addCredits(address player_, uint256 amount_) external onlyAdmin {

    // if the total game credits after adding the amount exceeds the number of $CHIP tokens stored in the contract, throw an error
    if ( totalGameCredits + amount_ > pokerDaoChips.balanceOf(address(this)) )  { revert NotEnoughCredits(); }

    // increase the internal credits for a player in the game by the amount
    gameCredits[player_] += amount_;

    // increase the internal credits in the game by the amount
    totalGameCredits += amount_;

    // credits have been added to player
    emit CreditsUpdated(player_, amount_, true);
  }


  // HOST ONLY: deduct internal credits from a player. This is to track when a player "adds on".
  // NOTE: This does not transfer any $CHIP balances. 
  function deductCredits(address player_, uint256 amount_) external onlyAdmin {

    // reduce the total amount of internal credits in the game
    totalGameCredits -= amount_;

    // reduce the amount of a player's internal credits in the game
    gameCredits[player_] -= amount_;

    // credits have been deducted from player
    emit CreditsUpdated(player_, amount_, false);
  }


  // called by an admin to add another admin
  function addAdmin(address newAdmin_) external onlyAdmin {

    // add address to whitelist
    isAdmin[newAdmin_] = true;

    // admin has been added
    emit AdminUpdated(newAdmin_, msg.sender, true);
  }


  // called by an admin to remove another admin
  function removeAdmin(address oldAdmin_) external onlyAdmin {

    // remove address from admin whitelist
    isAdmin[oldAdmin_] = false;

    // admin has been removed
    emit AdminUpdated(oldAdmin_, msg.sender, false);
  }
}