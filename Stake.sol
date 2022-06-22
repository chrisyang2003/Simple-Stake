pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mytoken.sol";

contract bank {
    // 奖励代币发行地址
    mytoken public token;
    // 每个区块挖出来的token的数量
    uint256 public tokenPerBlock;

    // 用户信息mapping
    mapping(address => UserInfo) public userInfo;

    // 抵押池子信息
    PoolInfo public pool;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    // 抵押event
    event Deposit(address indexed user, uint256 amount);
    // 撤除抵押
    event Withdraw(address indexed user, uint256 amount);
    // 提取奖励event
    event Reward(address indexed user, uint256 amount);

    struct UserInfo {
        // 质押的LPToken数量
        uint256 amount;
        // 已经获取的奖励数
        uint256 rewardDebt;
    }

    struct PoolInfo {
        // lptoken质押lp合约地址
        IERC20 lpToken;
        // 分配点数
        uint256 allocPoint;
        // 上一次分配奖励的区块数
        uint256 lastRewardBlock;
        // 是质押一个LPToken的收益
        uint256 acctokenPerShare;
    }

    constructor(IERC20 lpaddress) public {
        // lp代币地址
        pool.lpToken = lpaddress;
        // 初始化比例
        pool.allocPoint = 100;
        totalAllocPoint = 100;
        // 初始化mytoken代币
        token = new mytoken();
        // 每个区块奖励100个代币
        tokenPerBlock = 100;

        // token.mint(msg.sender, 100);

        startBlock = block.timestamp;
    }

    // @notice 更新质押池中lp收益数据, 并向池子中铸造mytoken代币。
    function update() public {
        // 本池子占有的LP数量
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // 获取未计算奖励的区块数量
        uint256 multiplier = pool.lastRewardBlock - block.number;
        // 计算池子可获得的新的mytoken奖励
        uint256 Reward = (multiplier * tokenPerBlock * pool.allocPoint) /
            totalAllocPoint;
        // 铸造mytoken给此合约
        token.mint(address(this), Reward);
        // 计算每个lp可分到的mytoken数量
        pool.acctokenPerShare =
            pool.acctokenPerShare +
            (Reward * 1e12) /
            lpSupply;
        // 记录最新的计算过的区块高度
        pool.lastRewardBlock = block.number;
    }

    // @notice 用户将自己的LP转移到矿池中进行挖矿
    // @params _amount 质押lp token的数量
    function deposit(uint256 _amount) public {
        // 获取用户信息
        UserInfo storage user = userInfo[msg.sender];
        update();
        // 如果是已经质押的用户需要转出未提取的收益
        if (user.amount > 0) {
            // pending是用户到最新区块可提取的奖励数量
            uint256 pending = (user.amount * pool.acctokenPerShare) /
                1e12 -
                user.rewardDebt;
            tokenTransfer(msg.sender, pending);
        }
        // 将用户的lp转移到质押池中
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        // 更新用户lp数量
        user.amount = user.amount + _amount;
        // 更新获得奖励数
        user.rewardDebt = (user.amount * pool.acctokenPerShare) / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    // @notice 显示用户收益
    // @params _user 用户地址
    function showReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 acctokenPerShare = pool.acctokenPerShare;
        // 总质押数
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = pool.lastRewardBlock - block.number;
            uint256 Reward = (multiplier * tokenPerBlock * pool.allocPoint) /
                totalAllocPoint;
            acctokenPerShare = acctokenPerShare + (Reward * 1e12) / lpSupply;
        }
        return (user.amount * acctokenPerShare) / 1e12 - user.rewardDebt;
    }

    // @notice 提取收益
    // @params _amount数量
    function getReward(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount);
        update();
        uint256 pending = (user.amount * pool.acctokenPerShare) /
            1e12 -
            user.rewardDebt;
        // 转移质押奖励代币
        tokenTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * pool.acctokenPerShare) / 1e12;
        emit Reward(msg.sender, _amount);
    }

    // @notice 提取收益并转出抵押代币
    // @params _amount数量
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount);
        update();
        uint256 pending = (user.amount * pool.acctokenPerShare) /
            1e12 -
            user.rewardDebt;
        // 转移质押奖励代币
        tokenTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * pool.acctokenPerShare) / 1e12;
        // 退回lptoken
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // 奖励代币转账
    function tokenTransfer(address _to, uint256 _amount) internal {
        uint256 value = token.balanceOf(address(this));
        if (_amount > value) {
            token.transfer(_to, value);
        } else {
            token.transfer(_to, _amount);
        }
    }

    function userAmount(address _user) public view returns (uint256) {
        return token.balanceOf(_user);
    }

    function showBlockTime() public view returns (uint256, uint256) {
        // for (uint i = 0; i < 1024; i++){
        //     startBlock = i;
        // }
        return (block.timestamp, block.number);
    }
}
