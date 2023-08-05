// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
//https://docs.uniswap.org/contracts/v3/reference/core/UniswapV3Factory
//factory includes IFactory, PoolDeployer, Pool
//Pool includes LowGasSafeMath
//factory includes IFactory, PoolDeployer, Pool
//Pool includes LowGasSafeMath, IUniswapV3FlashCallback, IUniswapV3MintCallback, IUniswapV3SwapCallback
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

//https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol"; //using older OpenZeppelin! Bad for our compilation. Also it assumes EOA initiate the txn, not good for our contract scenario, and not easy for a demo as it needs extra code and EOA approval

import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapClient is IUniswapV3FlashCallback, PeripheryImmutableState, PeripheryPayments {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    address payable owner;
    //https://docs.uniswap.org/contracts/v3/reference/deployments
    address public WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    // Goerli network

    address public routerAddr = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddr);
    address public factoryAddr = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    IUniswapV3Factory public immutable uniswapV3Factory = IUniswapV3Factory(factoryAddr);

    address quoterAddr = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    IQuoter public immutable quoter = IQuoter(quoterAddr);

    address public usdcAddr = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; //https://developers.circle.com/developer/docs/usdc-on-testnet
    address public usdtAddr;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public poolFee = 3000;

    // msg.sender must approve this contract
    constructor(address _factory, address _WETH9) PeripheryImmutableState(_factory, _WETH9) {
        owner = payable(msg.sender);
        // passing in the swap router for simplicity. More advanced contracts will show how to inherit the swap router safely.
    }

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip:
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address) {
        //Uniswap createPool UI, fee tier = 0.05%, 0.3%, 1% => 500, 3000, 10000 according to UniswapV3Factory.sol
        return uniswapV3Factory.getPool(tokenA, tokenB, fee);
    }

    //----------------------==
    function approveToken(address tokenAddr, uint256 _amount) external onlyOwner returns (bool) {
        return IERC20(tokenAddr).approve(routerAddr, _amount);
    }

    function allowanceToken(address tokenAddr) public view returns (uint256) {
        return IERC20(tokenAddr).allowance(address(this), routerAddr);
    }

    function getTokenBalc(address _tokenAddr) external view returns (uint256) {
        return IERC20(_tokenAddr).balanceOf(address(this));
    }

    function withdrawToken(address _tokenAddr) external onlyOwner {
        IERC20 tok = IERC20(_tokenAddr);
        tok.transfer(msg.sender, tok.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    //receive() external payable {} //already included in PeripheryPayments.sol
}
