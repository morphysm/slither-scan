// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

//            ██████╗░░█████╗░███╗░░██╗░█████╗░███╗░░██╗░█████╗░    ░█████╗░██████╗░███████╗
//            ██╔══██╗██╔══██╗████╗░██║██╔══██╗████╗░██║██╔══██╗    ██╔══██╗██╔══██╗██╔════╝
//            ██████╦╝███████║██╔██╗██║███████║██╔██╗██║███████║    ███████║██████╔╝█████╗░░
//            ██╔══██╗██╔══██║██║╚████║██╔══██║██║╚████║██╔══██║    ██╔══██║██╔═══╝░██╔══╝░░
//            ██████╦╝██║░░██║██║░╚███║██║░░██║██║░╚███║██║░░██║    ██║░░██║██║░░░░░███████╗
//            ╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝    ╚═╝░░╚═╝╚═╝░░░░░╚══════╝
//
//            ░██████╗░░█████╗░██████╗░██████╗░███████╗███╗░░██╗
//            ██╔════╝░██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗░██║
//            ██║░░██╗░███████║██████╔╝██║░░██║█████╗░░██╔██╗██║
//            ██║░░╚██╗██╔══██║██╔══██╗██║░░██║██╔══╝░░██║╚████║
//            ╚██████╔╝██║░░██║██║░░██║██████╔╝███████╗██║░╚███║
//            ░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚══╝

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApeGame {

    address tgc = 0xc8AE7ded8b33ea0Da0d7c7FC6FEd35e3C1822be0;
    uint256 public FISH_TO_CATCH_1=1440000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 public _refferal = 10;
    uint256 public devamount = 5;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress1;
    mapping (address => uint256) public catchFishes;
    mapping (address => uint256) public claimedMoneys;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketFishes;
    constructor(address _token, address _ceo1) public{
        ceoAddress=msg.sender;
        tgc = _token;
        ceoAddress1 = _ceo1;
    }

    function changeCeoAddress(address _ceo1) external  {
        require(msg.sender == ceoAddress, "only CEO address");
        ceoAddress1 = _ceo1;
    }

    function transferCEOAddress(address _newCeoAddress) external {
        require(msg.sender == ceoAddress, "only CEO address");
        require(_newCeoAddress != address(0), "!zero");
        ceoAddress = _newCeoAddress;
    }


    function harvestFishes(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 printerUsed=getMyFish();
        uint256 newPrinters=SafeMath.div(printerUsed,FISH_TO_CATCH_1);
        catchFishes[msg.sender]=SafeMath.add(catchFishes[msg.sender],newPrinters);
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;

        claimedMoneys[referrals[msg.sender]]=SafeMath.add(claimedMoneys[referrals[msg.sender]],SafeMath.div(printerUsed,_refferal));

        marketFishes=SafeMath.add(marketFishes,SafeMath.div(printerUsed,5));
    }
    function catchFishes() public {
        require(initialized);
        uint256 hasFish=getMyFish();
        uint256 fishValue=calculateMoneyClaim(hasFish);
        uint256 fee=devFee(fishValue, devamount);
        uint256 fee2=fee/3;
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=now;
        marketFishes=SafeMath.add(marketFishes,hasFish);
        ERC20(tgc).transfer(ceoAddress, fee2);
        ERC20(tgc).transfer(ceoAddress1, 2 * fee2);
        ERC20(tgc).transfer(address(msg.sender), SafeMath.sub(fishValue,fee));
    }
    function buyFisherman(address ref, uint256 amount) public {
        require(initialized);

        ERC20(tgc).transferFrom(address(msg.sender), address(this), amount);

        uint256 balance = ERC20(tgc).balanceOf(address(this));
        uint256 fishermanBought=calculatePrinterBuy(amount,SafeMath.sub(balance,amount));
        fishermanBought=SafeMath.sub(fishermanBought,devFee(fishermanBought, devamount));
        uint256 fee=devFee(amount, devamount);
        uint256 fee2=fee/5;
        ERC20(tgc).transfer(ceoAddress, fee2);
        ERC20(tgc).transfer(ceoAddress1, 2 * fee2);
        claimedMoneys[msg.sender]=SafeMath.add(claimedMoneys[msg.sender],fishermanBought);
        harvestFishes(ref);
    }

    function SET_REFFERAL(uint256 value) external {
        require(msg.sender == ceoAddress);
        _refferal = value;

    }

    function SET_DEVFEE(uint256 value) external {
        require(msg.sender == ceoAddress);
        devamount = value;

    }

    //magic happens here
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateMoneyClaim(uint256 printers) public view returns(uint256) {
        return calculateTrade(printers,marketFishes,ERC20(tgc).balanceOf(address(this)));
    }
    function calculatePrinterBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketFishes);
    }
    function calculatePrinterBuySimple(uint256 eth) public view returns(uint256){
        return calculatePrinterBuy(eth,ERC20(tgc).balanceOf(address(this)));
    }
    function devFee(uint256 amount, uint256 devamount2) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,devamount2),100);
    }
    function seedMarket(uint256 amount) public {
        require(msg.sender == ceoAddress);
        ERC20(tgc).transferFrom(address(msg.sender), address(this), amount);
        require(marketFishes==0);
        initialized=true;
        marketFishes=144000000000;
    }
    function getBalance() public view returns(uint256) {
        return ERC20(tgc).balanceOf(address(this));
    }
    function getMyFishes() public view returns(uint256) {
        return catchFishes[msg.sender];
    }
    function getMyFish() public view returns(uint256) {
        return SafeMath.add(claimedMoneys[msg.sender],getFishesSinceLastCatch(msg.sender));
    }
    function getFishesSinceLastCatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(FISH_TO_CATCH_1,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,catchFishes[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}