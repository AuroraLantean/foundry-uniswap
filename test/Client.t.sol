// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
//import "forge-std/console.sol";
import "src/ERC20Token.sol";
//import "src/ERC677Token.sol";
import "src/WETH.sol";
import "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";
//import "@uniswap/v3-core/contracts/UniswapV3PoolDeployer.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/NFTDescriptor.sol";
import "@uniswap/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";
import "@uniswap/v3-periphery/contracts/NonfungiblePositionManager.sol";
import "src/UniswapClient.sol";
import "src/DeployedCtrtAddrs.sol";

contract UniswapClientTest is Test {
    address zero = address(0);
    address alice = address(1);
    address bob = address(2);
    address weth9Addr;
    address usdtAddr;
    address usdcAddr;
    //address wBTCAddr;
    //address daiAddr;
    address uniAddr;
    //address linkAddr;
    address factoryAddr;
    address quoterAddr;
    address routerAddr;
    address nfPosMgrAddr;
    address payable clientAddr;

    address nftDescriptorAddr;
    address nftPosDescriptorAddr;

    WETH weth;
    //ERC20DP6 usdt;
    ERC20DP6 usdc;
    //ERC20DP8 wBTC;
    //ERC20Token dai;
    ERC20Token uni;
    //IERC677 erc677;
    UniswapV3Factory factory;
    //IUniswapV3Quoter quoter;
    SwapRouter router;
    NonfungiblePositionManager nfPosMgr;
    //NonfungibleTokenPositionDescriptor nftPosDescriptor;
    UniswapClient client;

    UniswapV3Pool poolWeth9Uni500;
    UniswapV3Pool pool;
    address poolAddr;
    address poolAddrXM;

    address tokenAddrM;
    address ownerM;
    address token0Addr;
    address token1Addr;
    address tokenA;
    address tokenB;
    address fox1;
    bool isToken0input;
    int24 tickspacingM;
    int24 tickM;
    uint24 fee;
    uint24 feeM;
    uint128 liquidityM;
    //uint160 sqrtPriceLimitX96;
    uint160 sqrtPriceX96;
    uint160 sqrtPriceX96M;

    uint256 price;
    uint256 amtInWei;
    //uint256 onClientAmt;
    //uint256 amountOutM;
    //uint256 amountIn;
    //uint256 amtInMax;

    address poolWeth9Uni500Addr;
    address poolUsdtUsdc500Addr;

    receive() external payable {
        console.log("receive", msg.sender, msg.value);
    }

    function setUp() external {
        console.log("------------== Setup()");
        deal(alice, 1000 ether);
        deal(bob, 1000 ether);
        vm.warp(1689392786); //in JS: new Date().getTime()/1000

        uint8 network = 0; //0 to deploy all UniswapV3, 1 Goerli, 2 Sepolia, 5 Main
        if (network > 0) {
            //getDeployedContractAddrs(network);
        } else {
            //deployAllContracts();
        }

        vm.startPrank(bob);
        //usdt.approve(nfPosMgrAddr, 1000e6);
        usdc.approve(nfPosMgrAddr, 1000e6);
        vm.stopPrank();

        console.log("clientAddr:", clientAddr);
        poolWeth9Uni500 = UniswapV3Pool(poolWeth9Uni500Addr);

        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY_ANVIL"));
        console.log("fox1:", fox1);

        //onClientAmt = 10 ether;
        //approvalAmount = onClientAmt;
        //console.log("approvalAmount: ", approvalAmount / 1e18, approvalAmount);

        //vm.startPrank(fox1);
        //uni.transfer(clientAddr, onClientAmt);
        //usdc.approve(routerAddr, onClientAmt);
        //uni.approve(routerAddr, onClientAmt);
        //vm.stopPrank();
    }

    function getDeployedContractAddrs(uint8 network) private {
        DeployedCtrtAddrs deployedCtrtAddrs = new DeployedCtrtAddrs();
        address[] memory arr = deployedCtrtAddrs.getAddrs(network);

        weth9Addr = arr[0];
        usdcAddr = arr[2];
        uniAddr = arr[5];
        factoryAddr = arr[7];
        quoterAddr = arr[8];
        routerAddr = arr[9];
        nfPosMgrAddr = arr[10];
        clientAddr = payable(arr[11]);

        weth = WETH(payable(weth9Addr));
        usdc = ERC20DP6(usdcAddr); //USDC use 6 dp !!!
        //usdt = ERC20DP6(usdtAddrMain); //USDT use 6 dp !!!
        //link = IERC677(linkTokenAddr);
        uni = ERC20Token(uniAddr);
        client = UniswapClient(clientAddr);

        fee = 500; // 500, 3000, 10000
        poolAddr = client.getPool(token0Addr, token1Addr, fee);
        console.log("poolAddr:", poolAddr);
        //0x07A4f63f643fE39261140DF5E613b9469eccEC86 uni/weth
        //0x6c2e77A3D29e5f4DfBE72c29c8957570fE3BaC0E weth/usdt
    }

    function deployAllContracts() private {
        console.log("To deploy all UniswapV3");
        vm.startPrank(alice);
        weth = new WETH();
        weth9Addr = address(weth);
        console.log("weth9Addr:", weth9Addr);

        usdc = new ERC20DP6("USDC","USDC"); //USDC use 6 dp !!!
        usdcAddr = address(usdc);
        console.log("usdcAddr:", usdcAddr);

        // usdt = new ERC20DP6("USDT","USDT"); //USDT use 6 dp
        // usdtAddr = address(usdt);
        // console.log("usdtAddr:", usdtAddr);

        uni = new ERC20Token("UniToken","UniToken");
        uniAddr = address(uni);
        console.log("uniAddr:", uniAddr);
        console.log("");

        factory = new UniswapV3Factory();
        factoryAddr = address(factory);
        console.log("factoryAddr:", factoryAddr);

        router = new SwapRouter(factoryAddr, weth9Addr);
        routerAddr = address(router);
        console.log("routerAddr:", routerAddr);

        //nftDescriptorAddr = new NFTDescriptor();
        //nftDescriptorAddr = address(nftDescriptor);

        bytes32 nativeCurrencyLabelBytes = "nativeCurrencyLabelBytes";
        NonfungibleTokenPositionDescriptor nftPosDescriptor =
            new NonfungibleTokenPositionDescriptor(weth9Addr, nativeCurrencyLabelBytes);
        nftPosDescriptorAddr = address(nftPosDescriptor);
        console.log("nftPosDescriptorAddr:", nftPosDescriptorAddr);

        nfPosMgr = new NonfungiblePositionManager(factoryAddr, weth9Addr, nftPosDescriptorAddr);
        nfPosMgrAddr = address(nfPosMgr);
        console.log("nfPosMgrAddr:", nfPosMgrAddr);
        /**
         * Locally Deploy Uniswap V3 video @21:45
         * See encodePriceSqrt at root, which is copied from @uniswap/v3-periphery/test/shared/encodePriceSqrt.ts
         * function encodePriceSqrt(reserve1, reserve2)
         *
         * uint256 sqrtPriceX96 = reserve1.div(reserve0).sqrt() *(2^96);//2^96 = 7.922816251*10e28
         */
        poolWeth9Uni500Addr = factory.getPool(address(weth9Addr), uniAddr, fee);
        console.log("poolWeth9Uni500Addr:", poolWeth9Uni500Addr);
        /*https://info.uniswap.org/#/
    USDC/ETH  0.05%  TVL $269.03m ... set poolFee to 100
    WBTC/ETH  0.3%   TVL $213.19m
        */
        fee = 500;
        sqrtPriceX96 = 79228162514264337593543950336; //7.922816251e28; // calculated by running "pnpm run encodePriceSqrt.js"
        poolUsdtUsdc500Addr = deployPool(usdtAddr, usdcAddr, fee, sqrtPriceX96);
        console.log("poolUsdtUsdc500Addr:", poolUsdtUsdc500Addr);

        fee = 500;
        sqrtPriceX96 = 79228162514264337593543950336;
        poolWeth9Uni500Addr = deployPool(weth9Addr, uniAddr, fee, sqrtPriceX96);
        (feeM, liquidityM, tickspacingM,) = showPool(poolWeth9Uni500Addr);
        assertEq(uint256(feeM), uint256(fee), "e001");
        assertEq(uint256(liquidityM), 0, "e002");

        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0();
        assertEq(uint256(sqrtPriceX96M), uint256(sqrtPriceX96), "e003");
        //assertEq(uint256(tickM), uint256(), "e004");

        console.log("------------==");
        client = new UniswapClient(factoryAddr, weth9Addr, routerAddr, quoterAddr);
        clientAddr = address(client);
        //client.approveToken(approvalAmount, routerAddr);
        vm.stopPrank();
    }

    function test_1_init() external {
        console.log("------------== test_1_init");
    }

    function test_2_mintLiquidity() external {
        console.log("------------== test_2_mintLiquidity");
        /*struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    } //import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";//MintParams, mint,increaseLiquidity, decreaseLiquidity, IncreaseLiquidityParams, DecreaseLiquidityParams, CollectParams, collect
        */
        //vm.prank(bob);
        // mintParams = MintParams{
        //  token0: usdtAddr,
        //  token1: usdcAddr,
        //  fee: feeM,
        // int24 tickLower;
        // int24 tickUpper;
        // uint256 amount0Desired;
        // uint256 amount1Desired;
        // uint256 amount0Min;
        // uint256 amount1Min;
        // address recipient;
        // uint256 deadline;
        // }
        // nfPosMgr.mint(mintParams);

        //check added liquidity in the pool
    }

    function deployPool(address token0r, address token1r, uint24 _fee, uint160 _sqrtPriceX96)
        private
        returns (address poolAddr_)
    {
        console.log("------------== deployPool()");
        console.log("token0:", token0r);
        console.log("token1:", token1r);
        console.log("fee:", _fee, ", sqrtPriceX96:", _sqrtPriceX96);
        if (token0r >= token1r) {
            (token0r, token1r) = (token1r, token0r);
        } //"token0 must be < token1!!!
        console.log("token0r:", token0r);

        //poolAddr_ = factory.createPool(weth9Addr, uniAddr, _fee); console.log("after createPool()... poolAddr_:", poolAddr_);
        //IUniswapV3Pool(poolAddr_).initialize(_sqrtPriceX96);
        nfPosMgr.createAndInitializePoolIfNecessary(token0r, token1r, _fee, _sqrtPriceX96); //gasLimit = 5000000
        poolAddr_ = factory.getPool(token0r, token1r, _fee);
        console.log("poolAddr", poolAddr_);
    }

    function showPool(address _poolAddr)
        private
        returns (uint24 fee_, uint128 liquidity_, int24 tickSpacing_, uint128 maxLiquidityPerTick_)
    {
        console.log("-------== from pool:", _poolAddr);
        pool = UniswapV3Pool(_poolAddr);
        address factoryAddrM = pool.factory();
        address token0AddrM = pool.token0();
        address token1AddrM = pool.token1();
        fee_ = pool.fee();
        liquidity_ = pool.liquidity();
        tickSpacing_ = pool.tickSpacing();
        maxLiquidityPerTick_ = pool.maxLiquidityPerTick();

        assertEq(factoryAddrM, factoryAddr);
        console.log("factoryAddrM:", factoryAddrM);
        console.log("token0AddrM:", token0AddrM);
        console.log("token1AddrM:", token1AddrM);
        console.log("fee_:", fee_);
        console.log("liquidity_:", liquidity_);
        console.log("tickSpacing_:", uint24(tickSpacing_), ", isPositive:", tickSpacing_ > 0);
        console.log("maxLiquidityPerTick_:", maxLiquidityPerTick_);
    }

    function showPoolSlot0()
        private
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
        (
            sqrtPriceX96_,
            tick_,
            observationIndex_,
            observationCardinality_,
            observationCardinalityNext_,
            feeProtocol_,
            unlocked_
        ) = pool.slot0();
        console.log("sqrtPriceX96_:", sqrtPriceX96_);
        console.log("tick_:", uint24(tick_), ", isPositive:", tick_ > 0);
        console.log("observationIndex_:", observationIndex_);
        console.log("observationCardinality_:", observationCardinality_);
        console.log("observationCardinalityNext_:", observationCardinalityNext_);
        console.log("feeProtocol_:", feeProtocol_);
        console.log("unlocked_:", unlocked_);
    }
    /*
    function test_2_() private {
        console.log("--------== test_2_getPrice");
        amtInWei = 1e18;
        isToken0input = true;
        price = client.getPrice(poolAddr, isToken0input, amtInWei, 0); //sqrtPriceLimitX96 = 0;
        console.log("price:", price);

        console.log("--------== test_2_createPool");
        tokenA = uniAddr;
        tokenB = weth9Addr;
        fee = 500; //or 1000
        console.log("tokenA = ", tokenA);
        console.log("tokenB = ", tokenB);
        poolAddr = client.createPool(tokenA, tokenB, fee);
        console.log("poolAddr:", poolAddr);

        poolAddrXM = client.getPool(tokenA, tokenB, fee);
        console.log("poolAddrXM:", poolAddrXM);
        assertEq(poolAddrXM, poolAddr);
        console.log(
            "Go to Uniswap UI and paste above token addresses to confirm they appear! https://app.uniswap.org/#/swap?chain=goerli"
        );
    }
    /*
        // tokenAddrM = address(client.uni());
        // console.log("tokenAddrM:", tokenAddrM);
        // assertEq(tokenAddrM, tokenAddr);

        //token0Addr = weth9AddrMain;
        //token1Addr = usdtAddrMain;
        token0Addr = uniAddr;
        token1Addr = weth9Addr;
        fee = 500; // 500, 3000, 10000
        poolWeth9Uni500Addr = client.getPool(token0Addr, token1Addr, fee);
        console.log("poolWeth9Uni500Addr:", poolWeth9Uni500Addr);
        //0x07A4f63f643fE39261140DF5E613b9469eccEC86 uni/weth
        //0x6c2e77A3D29e5f4DfBE72c29c8957570fE3BaC0E weth/usdt


        //assertEq(token0AddrM, token0Addr);//order may change
        assertEq(uint256(feeM), uint256(fee));

        amtInWei = 1e18;
        isToken0input = true;
        sqrtPriceLimitX96 = 0;
        price = client.getPrice(poolWeth9Uni500Addr, isToken0input, amtInWei, sqrtPriceLimitX96);
        console.log("price:", price);

    function showBalc() private {
        balcERC677 = uni.balanceOf(clientAddr);
        console.log("balcERC677:", balcERC677 / 1e18, balcERC677);
        balcWeth = weth.balanceOf(clientAddr);
        console.log("balcWeth:", balcWeth / 1e18, balcWeth);
        console.log("");
    }

    /*function test_2_createPool() external {
        console.log("--------== test_2_createPool");
        tokenA = uniAddr;
        tokenB = weth9Addr;
        fee = 500;//or 1000
        console.log("tokenA = ", tokenA);
        console.log("tokenB = ", tokenB);
        poolWeth9Uni500Addr = client.createPool(tokenA, tokenB, fee);
        console.log("poolWeth9Uni500Addr:", poolWeth9Uni500Addr);

        poolWeth9Uni500AddrM = client.getPool(tokenA, tokenB, fee);
        console.log("poolWeth9Uni500AddrM:", poolWeth9Uni500AddrM);
        assertEq(poolWeth9Uni500AddrM, poolWeth9Uni500Addr);
        console.log("Go to Uniswap UI and paste above token addresses to confirm they appear!");
        
        
    }
    
        amountIn = 2 ether;
        console.log("amountIn:", amountIn / 1e18, amountIn);
        vm.prank(fox1);
        //amountOutM = client.swapExactInputSingle(amountIn);
        console.log("amountOutM:", amountOutM / 1e18, amountOutM);
        _showBalc();
        assertEq(balcERC677, onClientAmt - amountIn);
        balcWethbf = balcWeth;

        amountOut = 3e6 gwei; //0.003
        amtInMax = 7 ether;
        console.log("amountOut:", amountOut / 1e18, amountOut);
        vm.prank(fox1);
        //amountInM = client.swapExactOutputSingle(amountOut, amtInMax);
        console.log("amountInM:", amountInM / 1e18, amountInM);
        _showBalc();
        assertEq(balcWeth, balcWethbf + amountOut);
    }
    */
    // function test_3_others() external {
    //     console.log("----== test_3_others");
    //     vm.prank(fox1);
    // }
}
/**
 * //uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
 *         //uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
 *         //(uint128 token0AmtOwed, uint128 token1AmtOwed) = pool.protocolFees();
 *         (
 *             uint128 liquidityGross,
 *             int128 liquidityNet,
 *             uint256 feeGrowthOutside0X128,
 *             uint256 feeGrowthOutside1X128,
 *             int56 tickCumulativeOutside,
 *             uint160 secondsPerLiquidityOutsideX128,
 *             uint32 secondsOutside,
 *             bool initialized
 *         ) = pool.ticks(tick);
 *
 * function tickBitmap(address poolAddr, int16 wordPosition) external view returns (uint256) {
 *         IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
 *         return pool.tickBitmap(wordPosition);
 *     }
 *
 *     function positions(address poolAddr, bytes32 key)
 *         external
 *         view
 *         returns (
 *             uint128 _liquidity,
 *             uint256 feeGrowthInside0LastX128,
 *             uint256 feeGrowthInside1LastX128,
 *             uint128 tokensOwed0,
 *             uint128 tokensOwed1
 *         )
 *     {
 *         IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
 *         return pool.positions(key);
 *     }
 *
 *     function observations(address poolAddr, uint256 index)
 *         external
 *         view
 *         returns (
 *             uint32 blockTimestamp,
 *             int56 tickCumulative,
 *             uint160 secondsPerLiquidityCumulativeX128,
 *             bool initialized
 *         )
 *     {
 *         IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
 *         return pool.observations(index);
 *     }
 */
