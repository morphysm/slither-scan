// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


import "./ILendingPool.sol";
import "./IWETHGateway.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract MyFinance is Ownable {
    using WadRayMath for uint256;

    ILendingPool lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);
    IWETHGateway wethGateway = IWETHGateway(0x8a47F74d1eE0e2edEB4F3A7e64EF3bD8e11D27C8);

    address avaToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //WETH Token
    address daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address usdtToken = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    address avWAVAX = 0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B;

    mapping(address=>Supply) public avaDeposits;
    mapping(address=>Supply) public daiDeposits;
    mapping(address=>Supply) public usdtDeposits;
    mapping(address=>Supply) public usdcDeposits;

    struct Supply {
        uint256 initialSupply;
        uint256 aaveInitialBalance;
    }

    mapping(address => bool) public charities;

    event Deposit(address indexed beneficiary, uint total, address asset);
    event DepositAVA(address indexed beneficiary, uint total);
    event Withdrawal(address indexed beneficiary, uint totalRequested, address asset, address charity, uint percentage, uint totalRecovered, uint donation);
    event WithdrawalAVA(address indexed beneficiary, uint totalRequested, address charity, uint percentage, uint totalRecovered, uint donation);

    constructor() {
        _approveWG(avWAVAX, 1e25);
        _approveLP(daiToken, 1e24);
        _approveLP(usdtToken, 1e12);
        _approveLP(usdcToken, 1e12);
    }

    function depositAVA() public payable {
        require(msg.value > 0, "Invalid value");

        wethGateway.depositETH{value:msg.value}(address(lendingPool), address(this), 0);

        avaDeposits[msg.sender].initialSupply += msg.value;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(avaToken);
        uint256 index = reserve.liquidityIndex;

        avaDeposits[msg.sender].aaveInitialBalance += msg.value.rayDiv(index);

        emit DepositAVA(msg.sender, msg.value);
    }
    
    function withdrawAVA(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(avaDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserAVABalance(msg.sender);
        uint256 initialSupply = avaDeposits[msg.sender].initialSupply;

        avaDeposits[msg.sender].initialSupply = 0;
        avaDeposits[msg.sender].aaveInitialBalance = 0;

        uint256 originalBalance = address(this).balance;
        wethGateway.withdrawETH(address(lendingPool), totalToRecover, address(this));
        uint256 recovered = address(this).balance - originalBalance;

        uint256 interests = recovered - initialSupply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = recovered - donation;

        if (donation > 0) {
            require(payable(_charity).send(donation), 'Could not transfer tokens');
        }

        if (earnings > 0) {
            require(payable(msg.sender).send(earnings), 'Could not transfer tokens');
        }

        emit WithdrawalAVA(msg.sender, totalToRecover, _charity, _percentage, recovered, donation);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);

        daiDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(daiToken);
        uint256 index = reserve.liquidityIndex;

        daiDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }
    
    function withdrawDAI(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(daiDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserDAIBalance(msg.sender);
        uint256 initialSupply = daiDeposits[msg.sender].initialSupply;

        daiDeposits[msg.sender].initialSupply = 0;
        daiDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, daiToken, _charity, _percentage);
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);

        usdtDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(usdtToken);
        uint256 index = reserve.liquidityIndex;

        usdtDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function withdrawUSDT(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(usdtDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserUSDTBalance(msg.sender);
        uint256 initialSupply = usdtDeposits[msg.sender].initialSupply;
        
        usdtDeposits[msg.sender].initialSupply = 0;
        usdtDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, usdtToken, _charity, _percentage);
    }

    function depositUSDC(uint256 _amount) public {
        _deposit(_amount, usdcToken);

        usdcDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(usdcToken);
        uint256 index = reserve.liquidityIndex;

        usdcDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function withdrawUSDC(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(usdcDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");
        
        uint256 totalToRecover = getUserUSDCBalance(msg.sender);
        uint256 initialSupply = usdcDeposits[msg.sender].initialSupply;

        usdcDeposits[msg.sender].initialSupply = 0;
        usdcDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, usdcToken, _charity, _percentage);
    }

    function getUserAVABalance(address _user) public view returns(uint256) {
        uint256 initial = avaDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, avaToken);
    }

    function getUserDAIBalance(address _user) public view returns(uint256) {
        uint256 initial = daiDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, daiToken);
    }

    function getUserUSDTBalance(address _user) public view returns(uint256) {
        uint256 initial = usdtDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, usdtToken);
    }

    function getUserUSDCBalance(address _user) public view returns(uint256) {
        uint256 initial = usdcDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, usdcToken);
    }

    function getAAVEBalance(uint256 _initial, address _asset) public view returns (uint256) {
        return _initial.rayMul(getPoolReserve(_asset));
    }

    function getPoolReserve(address _asset) public view returns (uint256) {
        return lendingPool.getReserveNormalizedIncome(_asset);
    }

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        lendingPool.deposit(_token, _amount, address(this), 0);

        emit Deposit(msg.sender, _amount, _token);
    }

    function _withdraw(uint256 _depositedPlusInterests, uint256 _initialSupply, address _token, address _charity, uint256 _percentage) internal {
        uint256 recovered = lendingPool.withdraw(_token, _depositedPlusInterests, address(this));
        uint256 interests = recovered - _initialSupply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = recovered - donation;

        if (donation > 0) {
            require(IERC20(_token).transfer(_charity, donation), 'Could not transfer tokens');
        }

        if (earnings > 0) {
            require(IERC20(_token).transfer(msg.sender, earnings), 'Could not transfer tokens');
        }

        emit Withdrawal(msg.sender, _depositedPlusInterests, _token, _charity, _percentage, recovered, donation);
    }

    function _approveLP(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }

    function _approveWG(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(wethGateway), _amount);
    }

    function _enableCharity(address _charity, bool _enabled) public onlyOwner {
        charities[_charity] = _enabled;
    }

    function _recoverTokens(uint256 _amount, address _asset) public onlyOwner {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Could not transfer tokens');
    }

    function _recoverAVAX(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}
}