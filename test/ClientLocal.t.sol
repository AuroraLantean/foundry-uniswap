// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
//import "forge-std/console.sol";

import "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/lens/Quoter.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/NonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";
import "@uniswap/v3-periphery/contracts/libraries/NFTDescriptor.sol";

import "src/UniswapClient.sol";
import "src/DeployedCtrtAddrs.sol";
import "src/HelperFuncs.sol";

contract UniswapClientTest is Test, HelperFuncs {
    address nftDescriptorAddr;
    address nftPosDescriptorAddr;

    address payable clientAddr;
    UniswapClient client;
    uint8 network = 0; //1 Main, 5 Goerli, 111 Sepolia

    function setUp() external {
        lg("------------== Setup()");
        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address signer = vm.envAddress("SIGNER");
        lg("fox1:", fox1);
        assertEq(fox1, signer, "fox1 not signer");
        lg("balcETH(this)", address(this).balance);
        deal(alice, 1000 ether);
        deal(bob, 1000 ether);
        vm.warp(1689392786); //in JS: new Date().getTime()/1000
            //0 to deploy all UniswapV3 locally, 1 Goerli, 2 Sepolia, 5 Main
        console.log("network:", network);
        deployAllContractsLocally();

        lg("--------== After deployAllContractsLocally()");
        vm.startPrank(bob);
        //usdt.approve(nfPosMgrAddr, 1000e6);
        usdc.approve(nfPosMgrAddr, 1000e6);
        vm.stopPrank();

        lg("clientAddr:", clientAddr);
        poolWeth9Uni500 = UniswapV3Pool(poolDaiUsdc100Addr);
    }

    function deployAllContractsLocally() private {
        lg("--------== deployAllContractsLocally");
        vm.startPrank(alice);
        weth = new WETH();
        wethAddr = address(weth);
        lg("wethAddr:", wethAddr);

        usdt = new ERC20DP6("USDT","USDT"); //USDT use 6 dp
        usdtAddr = address(usdt);
        lg("usdtAddr:", usdtAddr);

        usdc = new ERC20DP6("USDC","USDC"); //USDC use 6 dp !!!
        usdcAddr = address(usdc);
        lg("usdcAddr:", usdcAddr);

        dai = new ERC20Token("DAI","DAI");
        daiAddr = address(dai);
        lg("daiAddr:", daiAddr);

        uni = new ERC20Token("UniToken","UniToken");
        uniAddr = address(uni);
        lg("uniAddr:", uniAddr);
        lg("");

        factory = new UniswapV3Factory();
        factoryAddr = address(factory);
        lg("factoryAddr:", factoryAddr);

        router = new SwapRouter(factoryAddr, wethAddr);
        routerAddr = address(router);
        lg("routerAddr:", routerAddr);

        quoter = new Quoter(factoryAddr, wethAddr);
        quoterAddr = address(quoter);
        lg("quoterAddr:", quoterAddr);

        bytes32 nativeCurrencyLabelBytes = "nativeCurrencyLabelBytes";
        NonfungibleTokenPositionDescriptor nftPosDescriptor =
            new NonfungibleTokenPositionDescriptor(wethAddr, nativeCurrencyLabelBytes);
        nftPosDescriptorAddr = address(nftPosDescriptor);
        lg("nftPosDescriptorAddr:", nftPosDescriptorAddr);

        nfPosMgr = new NonfungiblePositionManager(factoryAddr, wethAddr, nftPosDescriptorAddr);
        nfPosMgrAddr = address(nfPosMgr);
        lg("nfPosMgrAddr:", nfPosMgrAddr);

        //----------== DeployPool
        // pool MUST only be initialized once by setting sqrtPrice to a non zero value ... see UniswapV3Pool.sol

        /**
         * Locally Deploy Uniswap V3 video @21:45
         * See encodePriceSqrt at root, which is copied from @uniswap/v3-periphery/test/shared/encodePriceSqrt.ts
         * function encodePriceSqrt(reserve1, reserve2)
         *
         * uint256 sqrtPriceX96 = reserve1.div(reserve0).sqrt() *(2^96);//2^96 = 7.922816251*10e28
         */

        /*See pool rates at https://info.uniswap.org/#/
          USDC/ETH  0.05%  TVL $269.03m
          WBTC/ETH  0.3%   TVL $213.19m
        */
        //------------== USDC/WETH
        poolFee = 500; //3000 for 0.3%, 500 for 0.05%, 100 for 0.01%
        sqrtPriceX96 = 79228162514264337593543950336; //7.922816251e28; // calculated by running "pnpm run encodePriceSqrt.js"
        poolUsdcWeth500Addr = deployPool(usdcAddr, wethAddr, poolFee, sqrtPriceX96, "USDC/WETH");
        lg("poolUsdcWeth500Addr:", poolUsdcWeth500Addr);
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolUsdcWeth500Addr, "USDC/WETH 500");
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolUsdcWeth500Addr, "USDC/WETH 500");

        //------------== DAI/USDC
        poolFee = 100;
        sqrtPriceX96 = 79228162514264337593543950336;
        factory.enableFeeAmount(poolFee, 2);
        poolDaiUsdc100Addr = deployPool(daiAddr, usdcAddr, poolFee, sqrtPriceX96, "DAI/USDC");
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolDaiUsdc100Addr, "DAI/USDC 100");
        assertEq(uint256(poolFeeM), uint256(poolFee), "e001");
        assertEq(uint256(liquidityM), 0, "e002");

        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolDaiUsdc100Addr, "DAI/USDC 100");
        assertEq(uint256(sqrtPriceX96M), uint256(sqrtPriceX96), "e003");
        //assertEq(uint256(tickM), uint256(), "e004");

        lg("--------== deploy UniswapClient");
        client = new UniswapClient(factoryAddr, wethAddr, routerAddr, nfPosMgrAddr);
        clientAddr = address(client);
        //client.approveToken(approvalAmount, routerAddr);

        lg("--------== send tokens to UniswapClient");
        vm.stopPrank();
    } //deployAllContractsLocally

    function test_1_mintLiquidity() external {
        lg("------------== test_1_mintLiquidity");
        token0Addr = usdcAddr; //Goerli
        token1Addr = wethAddr; //Goerli
        token0 = usdc;
        //token1 = ERC20Token(address(weth));
        tok0name = "USDC";
        tok1name = "WETH";
        amt0ToMint = 1000e18; // USDC
        amt1ToMint = 1000e18; // WETH
        poolFee = 500;

        showERC20Balc(token0Addr, token1Addr, clientAddr, tok0name, tok1name, "client");

        if (token0Addr == address(0) || token1Addr == address(0)) console.log("token0Addr or token1Addr is zero");
        if (token0Addr >= token1Addr) {
            (token0Addr, token1Addr) = (token1Addr, token0Addr);
        } //"token0Addr must be < token1Addr!!!
        console.log("token0Addr:", token0Addr);
        console.log("token1Addr:", token1Addr);

        vm.startPrank(alice);
        IERC20(token0Addr).approve(clientAddr, amt0ToMint);
        IERC20(token1Addr).approve(clientAddr, amt1ToMint);

        lg("before mintNewPosition");
        client.mintNewPosition(token0Addr, token1Addr, poolFee, amt0ToMint, amt1ToMint);
        vm.stopPrank();
        lg("after mintNewPosition");
        uint256 lastNftDepositId = client.lastNftDepositId();
        lg("lastNftDepositId:", lastNftDepositId);

        (ownerM, liquidityM, token0AddrM, token1AddrM) = client.nftDeposits(lastNftDepositId);
        lg("DepositNFT owner:", ownerM);
        console.log("liquidity:", liquidityM);
        lg("token0Addr:", token0AddrM);
        lg("token1Addr:", token1Addr);
        showERC20Balc(token0Addr, token1Addr, clientAddr, tok0name, tok1name, "client");

        //MintParams, mint,increaseLiquidity, decreaseLiquidity, IncreaseLiquidityParams, DecreaseLiquidityParams, CollectParams, collect

        // nfPosMgr.mint(mintParams);

        //check added liquidity in the pool
    }
}
