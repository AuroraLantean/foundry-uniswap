// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;
/*deployed at Goerli 0x77b1b3cD6435B0f5a14eE49F2Cb3Af18a8189DF5
 */

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
//https://docs.uniswap.org/contracts/v3/reference/core/UniswapV3Factory
//factory includes IFactory, PoolDeployer, Pool
//Pool includes LowGasSafeMath, IUniswapV3FlashCallback, IUniswapV3MintCallback, IUniswapV3SwapCallback

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

//https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol"; //getPoolKey, computeAddress
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol"; // verifyCallback

import "src/TransferPayHelper.sol";
import "src/LowGasSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapClient is IUniswapV3FlashCallback, PeripheryPaymentsB {
    using LowGasSafeMathB for uint256;
    using LowGasSafeMathB for int256;

    address payable owner;
    //https://docs.uniswap.org/contracts/v3/reference/deployments
    address public factoryAddr = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    IUniswapV3Factory public immutable uniswapV3Factory = IUniswapV3Factory(factoryAddr);

    address quoterAddr = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    IQuoter public immutable quoter = IQuoter(quoterAddr);

    address public routerAddr = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddr);

    // msg.sender must approve this contract
    constructor(address _factory, address _WETH9) PeripheryPaymentsB(_factory, _WETH9) {
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

    function getFeeAmountTickSpacing(uint24 fee) external view returns (int24) {
        return uniswapV3Factory.feeAmountTickSpacing(fee);
    }

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address) {
        return uniswapV3Factory.createPool(tokenA, tokenB, fee);
    }

    function enableFeeAmount(uint24 fee, int24 tickSpacing) external {
        uniswapV3Factory.enableFeeAmount(fee, tickSpacing);
    }

    //------------------==
    function getPoolInfo(address poolAddr)
        external
        view
        returns (
            address poolFactoryAddr,
            address token0Addr,
            address token1Addr,
            uint24 fee,
            int24 tickSpacing,
            uint128 maxLiquidityPerTick
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        poolFactoryAddr = pool.factory();
        token0Addr = pool.token0();
        token1Addr = pool.token1();
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();
        maxLiquidityPerTick = pool.maxLiquidityPerTick();
    }

    function slot0(address poolAddr)
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        return pool.slot0();
    }

    function getPoolState(address poolAddr)
        external
        view
        returns (
            uint256 feeGrowthGlobal0X128,
            uint256 feeGrowthGlobal1X128,
            uint128 token0AmtOwed,
            uint128 token1AmtOwed,
            uint256 liquidity
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        (token0AmtOwed, token1AmtOwed) = pool.protocolFees();
        liquidity = pool.liquidity();
    }

    function ticks(address poolAddr, int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        return pool.ticks(tick);
    }

    function tickBitmap(address poolAddr, int16 wordPosition) external view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        return pool.tickBitmap(wordPosition);
    }

    function positions(address poolAddr, bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        return pool.positions(key);
    }

    function observations(address poolAddr, uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        return pool.observations(index);
    }

    //sqrtPriceLimitX96 = 0
    function getPrice(address poolAddr, bool isToken0input, uint256 amtInWei, uint160 sqrtPriceLimitX96)
        external
        returns (uint256 quotedAmt)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);

        if (isToken0input) {
            quotedAmt =
                quoter.quoteExactInputSingle(pool.token0(), pool.token1(), pool.fee(), amtInWei, sqrtPriceLimitX96);
        } else {
            quotedAmt =
                quoter.quoteExactInputSingle(pool.token1(), pool.token0(), pool.fee(), amtInWei, sqrtPriceLimitX96);
        }
    }

    function mintPool(
        address poolAddr,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (amount0, amount1) = pool.mint(recipient, tickLower, tickUpper, amount, data);
    }

    //see IUniswapV3MintCallback.sol
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external {
        //TODO must pay the pool tokens owed for the minted liquidity. The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    }

    function collectPool(
        address poolAddr,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (amount0, amount1) = pool.collect(recipient, tickLower, tickUpper, amount0Requested, amount1Requested);
    }

    function burnPool(address poolAddr, int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (amount0, amount1) = pool.burn(tickLower, tickUpper, amount);
    }

    function swapPool(
        address poolAddr,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (amount0, amount1) = pool.swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }

    //see IUniswapV3SwapCallback.sol
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        //TODO must pay the pool tokens owed for the swap.
        /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
        /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    }

    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
        uint24 fee2;
        uint24 fee3;
    }

    function flashPool(FlashParams memory params) external {
        // poolKey looks like {token0: token0, token1: token1, fee: fee}
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee1});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));

        // require(allowanceToken(params.token0) >= params.amount0, "not enough amount0");
        // require(allowanceToken(params.token1) >= params.amount1, "not enough amount1");

        pool.flash(
            address(this),
            params.amount0,
            params.amount1,
            abi.encode(
                FlashCallbackData({
                    amount0: params.amount0,
                    amount1: params.amount1,
                    payer: msg.sender,
                    poolKey: poolKey,
                    poolFee2: params.fee2,
                    poolFee3: params.fee3
                })
            )
        );
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
        uint24 poolFee2;
        uint24 poolFee3;
    }
    //required by IUniswapV3FlashCallback
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        //here we should have received tokens from the pool
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        CallbackValidation.verifyCallback(factory, decoded.poolKey);
        address token0 = decoded.poolKey.token0;
        address token1 = decoded.poolKey.token1;
        //for security reasons, use verifycallback instead of the following:
        //address pool = uniswapV3Factory.getPool(token0, token1, _fee);
        //require(msg.sender == address(pool), "Only Callback");

        //this client to approve
        TransferHelperB.safeApprove(token0, address(swapRouter), decoded.amount0);
        TransferHelperB.safeApprove(token1, address(swapRouter), decoded.amount1);

        uint256 amount1Owed = LowGasSafeMathB.add(decoded.amount1, fee1); //also minimum amount1 to borrow
        uint256 amount0Owed = LowGasSafeMathB.add(decoded.amount0, fee0); //also minimum amount0 to borrow

        uint256 amountOut0 = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token0,
                fee: decoded.poolFee2,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: decoded.amount1,
                amountOutMinimum: amount0Owed,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 amountOut1 = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: decoded.poolFee3,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: decoded.amount0,
                amountOutMinimum: amount1Owed,
                sqrtPriceLimitX96: 0
            })
        );

        //TransferHelperB.safeApprove(token0, address(this), amount0Owed);
        //TransferHelperB.safeApprove(token1, address(this), amount1Owed);

        if (amount0Owed > 0) pay(token0, address(this), msg.sender, amount0Owed);
        if (amount1Owed > 0) pay(token1, address(this), msg.sender, amount1Owed);

        if (amountOut0 > amount0Owed) {
            uint256 profit0 = LowGasSafeMathB.sub(amountOut0, amount0Owed);

            TransferHelperB.safeApprove(token0, address(this), profit0);
            pay(token0, address(this), decoded.payer, profit0);
        }
        if (amountOut1 > amount1Owed) {
            uint256 profit1 = LowGasSafeMathB.sub(amountOut1, amount1Owed);
            TransferHelperB.safeApprove(token0, address(this), profit1);
            pay(token1, address(this), decoded.payer, profit1);
        }
    }

    //----------------------==
    function approveToken(address tokenAddr, address spender, uint256 _amount) external onlyOwner returns (bool) {
        if (spender == address(0)) spender = routerAddr;
        return IERC20(tokenAddr).approve(spender, _amount);
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
