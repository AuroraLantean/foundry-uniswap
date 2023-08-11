// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "forge-std/console.sol";
import "src/ERC20Token.sol";
//import "src/ERC677Token.sol";
import "src/WETH.sol";
import "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/lens/Quoter.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/NonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

contract HelperFuncs {
    address zero = address(0);
    address alice = address(1);
    address bob = address(2);
    address wethAddr;
    address usdtAddr;
    address usdcAddr;
    //address wBTCAddr;
    address daiAddr;
    address uniAddr;
    address gldcAddr;
    //address linkAddr;
    address factoryAddr;
    address quoterAddr;
    address routerAddr;
    address nfPosMgrAddr;

    string tok0name;
    string tok1name;
    string str;
    WETH weth;
    ERC20DP6 usdt;
    ERC20DP6 usdc;
    //ERC20DP8 wBTC;
    ERC20Token dai;
    ERC20Token uni;
    ERC20Token gldc;
    ERC20Token token0;
    ERC20Token token1;
    //IERC677 erc677;
    UniswapV3Factory factory;
    Quoter quoter;
    SwapRouter router;
    NonfungiblePositionManager nfPosMgr;
    //NonfungibleTokenPositionDescriptor nftPosDescriptor;

    UniswapV3Pool poolWeth9Uni500;
    address poolAddr;
    address poolAddrXM;

    address tokenAddrM;
    address ownerM;
    address token0Addr;
    address token0AddrM;
    address token1Addr;
    address token1AddrM;
    address tokenA;
    address tokenB;
    address fox1;
    bool isToken0input;
    int24 tickspacingM;
    int24 tickM;
    int24 feeAmountTickSpacing;
    uint24 poolFee;
    uint24 poolFeeM;
    uint128 liquidityM;
    uint160 sqrtPriceLimitX96;
    uint160 sqrtPriceX96;
    uint160 sqrtPriceX96M;

    uint256 price;
    uint256 amtInWei;
    uint256 amt0ToMint;
    uint256 amt1ToMint;

    //uint256 onClientAmt;
    //uint256 amountOutM;
    //uint256 amountIn;
    //uint256 amtInMax;

    address poolUsdcWeth500Addr;
    address poolDaiUsdc100Addr;

    function deployPool(address token0r, address token1r, uint24 _poolFee, uint160 _sqrtPriceX96, string memory _str)
        internal
        returns (address poolAddr_)
    {
        console.log("--------== deployPool() of ", _str, poolFee);
        lg("token0:", token0r);
        lg("token1:", token1r);
        console.log("poolFee:", _poolFee, ", sqrtPriceX96:", _sqrtPriceX96);
        feeAmountTickSpacing = factory.feeAmountTickSpacing(poolFee);
        require(feeAmountTickSpacing != 0, "feeAmountTickSpacing == 0");
        require(_sqrtPriceX96 > 0, "_sqrtPriceX96 == 0");
        if (token0r == zero || token1r == zero) lg("token0r or token1r is zero");
        if (token0r > token1r) {
            (token0r, token1r) = (token1r, token0r);
        } //"token0 must be < token1!!!
        lg("token0r:", token0r);

        lg("nfPosMgr.createAndInitializePoolIfNecessary");
        //factory.createPool(wethAddr, uniAddr, _poolFee);
        //IUniswapV3Pool(poolAddr_).initialize(_sqrtPriceX96);
        nfPosMgr.createAndInitializePoolIfNecessary(token0r, token1r, _poolFee, _sqrtPriceX96); //gasLimit = 5000000
        poolAddr_ = factory.getPool(token0r, token1r, _poolFee);
        lg("poolAddr", poolAddr_);
        IUniswapV3Pool poolc = getPool(token0r, token1r, _poolFee);
        lg("poolAddrCalc", address(poolc));
    }

    function getPool(address _tokenA, address _tokenB, uint24 _fee) internal view returns (IUniswapV3Pool) {
        if (_tokenA == zero || _tokenB == zero) lg("_tokenA or _tokenB is zero");
        return IUniswapV3Pool(PoolAddress.computeAddress(factoryAddr, PoolAddress.getPoolKey(_tokenA, _tokenB, _fee)));
    }

    function showPool(address _poolAddr, string memory _str)
        internal
        returns (uint24 poolFee_, uint128 liquidity_, int24 tickSpacing_, uint128 maxLiquidityPerTick_)
    {
        lg("--------== showPool(): pool =", _poolAddr);
        lg(_str);
        UniswapV3Pool pl = UniswapV3Pool(_poolAddr);
        address factoryAddrM = pl.factory();
        token0AddrM = pl.token0();
        token1AddrM = pl.token1();
        poolFee_ = pl.fee();
        liquidity_ = pl.liquidity();
        tickSpacing_ = pl.tickSpacing();
        maxLiquidityPerTick_ = pl.maxLiquidityPerTick();

        lg("factoryAddrM:", factoryAddrM);
        lg("token0AddrM:", token0AddrM);
        lg("token1AddrM:", token1AddrM);
        console.log("poolFee_:", poolFee_);
        console.log("liquidity_:", liquidity_);
        console.log("tickSpacing_:", uint24(tickSpacing_), ", isPositive:", tickSpacing_ > 0);
        console.log("maxLiquidityPerTick_:", maxLiquidityPerTick_);
    }

    function showPoolSlot0(address _poolAddr, string memory _str)
        internal
        view
        returns (
            uint160 sqrtPriceX96_,
            int24 tick_,
            uint16 observationIndex_,
            uint16 observationCardinality_,
            uint16 observationCardinalityNext_,
            uint8 feeProtocol_,
            bool unlocked_
        )
    {
        lg("--------== showPoolSlot0(): pool =", _poolAddr);
        lg(_str);
        UniswapV3Pool pl = UniswapV3Pool(_poolAddr);
        (
            sqrtPriceX96_,
            tick_,
            observationIndex_,
            observationCardinality_,
            observationCardinalityNext_,
            feeProtocol_,
            unlocked_
        ) = pl.slot0();
        console.log("sqrtPriceX96_:", sqrtPriceX96_);
        console.log("tick_:", uint24(tick_), ", isPositive:", tick_ > 0);
        lg("observation... are related to price oracle");
        console.log("observationIndex_:", observationIndex_);
        console.log("observationCardinality_:", observationCardinality_);
        console.log("observationCardinalityNext_:", observationCardinalityNext_);
        console.log("feeProtocol_:", feeProtocol_);
        lg("reentrance unlocked_:", unlocked_);
    }

    //sqrtPriceLimitX96 = 0
    function getPrice(address _poolAddr, bool _isToken0input, uint256 _amtInWei, uint160 _sqrtPriceLimitX96)
        internal
        returns (uint256 quotedAmt)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(_poolAddr);
        if (_isToken0input) {
            quotedAmt =
                quoter.quoteExactInputSingle(pool.token0(), pool.token1(), pool.fee(), _amtInWei, _sqrtPriceLimitX96);
        } else {
            quotedAmt =
                quoter.quoteExactInputSingle(pool.token1(), pool.token0(), pool.fee(), _amtInWei, _sqrtPriceLimitX96);
        }
    }

    function showERC20WethBalc(
        address tokenA_r,
        WETH _weth,
        address addr,
        string memory nameTokA,
        string memory nameTokB,
        string memory nameAddr
    ) internal view {
        console.log("----== showERC20WethBalc on ", nameAddr);
        IERC20Meta tokA = IERC20Meta(tokenA_r);
        //IERC20Meta tokB = IERC20Meta(tokenB_r);
        uint256 balcA = tokA.balanceOf(addr);
        uint8 decA = tokA.decimals();
        console.log(nameTokA, balcA / (10 ** decA), balcA);
        //console.log("decA", decA);
        uint256 balcB = _weth.balanceOf(addr);
        uint8 decB = _weth.decimals();
        //console.log("decB", decB);
        console.log(nameTokB, balcB / (10 ** decB), balcB);
        lg("");
    }

    function showERC20Balc(
        address tokenA_r,
        address tokenB_r,
        address addr,
        string memory nameTokA,
        string memory nameTokB,
        string memory nameAddr
    ) internal view {
        console.log("----== showERC20Balc on ", nameAddr);
        IERC20Meta tokA = IERC20Meta(tokenA_r);
        IERC20Meta tokB = IERC20Meta(tokenB_r);
        uint256 balcA = tokA.balanceOf(addr);
        uint8 decA = tokA.decimals();
        console.log(nameTokA, balcA / (10 ** decA), balcA);
        //console.log("decA", decA);
        uint256 balcB = tokB.balanceOf(addr);
        uint8 decB = tokB.decimals();
        //console.log("decB", decB);
        console.log(nameTokB, balcB / (10 ** decB), balcB);
        lg("");
    }

    function lg(string memory _str) internal view {
        console.log(_str);
    }

    function lg(string memory _str, address addr) internal view {
        console.log(_str, addr);
    }

    function lg(string memory _str, bool b) internal view {
        console.log(_str, b);
    }

    function lg(string memory _str, uint8 u8) internal view {
        console.log(_str, u8);
    }

    function lg(string memory _str, uint256 u256) internal view {
        console.log(_str, u256);
    }

    receive() external payable {
        console.log("test ctrt to receive from", msg.sender, msg.value);
    }
}
