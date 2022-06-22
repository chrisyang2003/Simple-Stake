# Simple Stake

一个简单的质押挖矿合约，通过转入lp（流动性代币）合约进行质押挖矿，并赚取mytoken代币奖励

主要包含功能

- deposit(uint256 _amount) 质押lp代币
- withdraw(uint256 _amount) 提取收益并转出抵押代币
- update() 更新质押池中lp收益数据, 并向池子中铸造mytoken代币。
-  showReward(address _user) 显示用户收益

部署时，设置参数tokenPerBlock控制每一个区块的奖励数。每一次改变池中状态时都会调用update函数，从而更新区块奖励数和acctokenPerShare质押每一个lp的奖励份额。
$$
可以获得的token数= tokenPerBlock \times \frac{allocPoint}{totalAllocPoint}
$$
代币均遵守erc20规范
