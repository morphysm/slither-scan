/**
 *Submitted for verification at snowtrace.io on 2022-02-16
*/

pragma solidity 0.8.3;

interface IAgg {
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract Under1CasinoAVAX {
    address public constant OPERATOR = 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2;
    address public constant LOADER = 0x3D90BfB95c399414254CA6F6159A45927f017895;
    address public constant FEED = 0x0A77230d17318075983913bC2145DB16C7366156;
    uint public BetMax = address(this).balance / 10;
    uint public CountWins;
    uint public CountLoss;
    mapping(address => uint) public addPlayer;
    mapping(address => uint) public ticketNum;
    mapping(address => uint) public betAmt;
    
    constructor() payable {}
    
    function safeDiv(uint a, uint b) public pure returns (uint c) {
	require(b > 0);
        c = a / b;
    }

    fallback() external payable {
        require(msg.value >= tx.gasprice);
        require(msg.value <= BetMax);
        if (msg.sender == OPERATOR) {
            // operator withdrawal
            (bool sent, ) = msg.sender.call{value: (msg.value * 10)}("");
            require(sent, "Failed to send Ether");
        } else if (msg.sender == LOADER) {
        // load contract
        } else {
        IAgg(FEED).latestRound;
        IAgg(FEED).getAnswer;
        IAgg(FEED).getTimestamp;
        if (addPlayer[msg.sender] > 0) {
            require((addPlayer[msg.sender] + 1) < IAgg(FEED).latestRound());
        if (uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(ticketNum[msg.sender], IAgg(FEED).getTimestamp(addPlayer[msg.sender] + 2), IAgg(FEED).getAnswer(addPlayer[msg.sender] + 2)))))) < uint256(57350000000000000000000000000000000000000000000000000000000000000000000000000)) {
        // max uint value = 115792089237316195423570985008687907853269984665640564039457584007913129639935
            uint WinAmt;
            WinAmt = betAmt[msg.sender];
            CountWins +=1;
            addPlayer[msg.sender] = IAgg(FEED).latestRound();
            ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
            betAmt[msg.sender] = msg.value;
            BetMax = safeDiv((address(this).balance - (WinAmt * 2)), 10);
            (bool sent, ) = msg.sender.call{value: (WinAmt * 2)}("");
            require(sent, "Failed to send Ether");
        } else {
            CountLoss +=1;
            addPlayer[msg.sender] = IAgg(FEED).latestRound();
            ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
            betAmt[msg.sender] = msg.value;
            BetMax = safeDiv(address(this).balance , 10);
        }
        } else {
        addPlayer[msg.sender] = IAgg(FEED).latestRound();
        ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
        betAmt[msg.sender] = msg.value;
        BetMax = safeDiv(address(this).balance , 10);
        }
    }
    }
}