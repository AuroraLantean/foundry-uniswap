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
//import "@uniswap/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";
//import "@uniswap/v3-periphery/contracts/libraries/NFTDescriptor.sol";

import "src/UniswapClient.sol";
import "src/DeployedCtrtAddrs.sol";
import "src/HelperFuncs.sol";

contract UniswapClientTest is Test, HelperFuncs {
    address payable clientAddr;
    UniswapClient client;

    uint8 network = 1;

    function setUp() external {
        lg("------------== Setup()");
        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address signer = vm.envAddress("SIGNER");
        lg("fox1:", fox1);
        assertEq(fox1, signer, "fox1 not signer");
        deal(alice, 1000 ether);
        deal(bob, 1000 ether);
        vm.warp(1689392786); //in JS: new Date().getTime()/1000
            //0 to deploy all UniswapV3 locally, 1 Goerli, 2 Sepolia, 5 Main
        console.log("network:", network);

        getDeployedContractAddrs(network);

        lg("--------== After getDeployedContractAddrs()");
        vm.startPrank(bob);
        //usdt.approve(nfPosMgrAddr, 1000e6);
        usdc.approve(nfPosMgrAddr, 1000e6);
        vm.stopPrank();

        lg("clientAddr:", clientAddr);
        poolWeth9Uni500 = UniswapV3Pool(poolDaiUsdc100Addr);
    }

    function getDeployedContractAddrs(uint8 _network) private {
        console.log("--------== getDeployedContractAddrs");
        DeployedCtrtAddrs deployedCtrtAddrs = new DeployedCtrtAddrs();
        address[] memory arr = deployedCtrtAddrs.getAddrs(_network);

        wethAddr = arr[0];
        lg("wethAddr:", wethAddr);
        usdtAddr = arr[1];
        lg("usdtAddr:", usdtAddr);
        usdcAddr = arr[2];
        lg("usdcAddr:", usdcAddr);
        //wBTCAddr = arr[3];
        daiAddr = arr[4];
        lg("daiAddr:", daiAddr);
        uniAddr = arr[5];
        lg("uniAddr:", uniAddr);
        //linkAddr = arr[6];
        factoryAddr = arr[7];
        lg("factoryAddr:", factoryAddr);
        quoterAddr = arr[8];
        lg("quoterAddr:", quoterAddr);
        routerAddr = arr[9];
        lg("routerAddr:", routerAddr);
        nfPosMgrAddr = arr[10];
        lg("nfPosMgrAddr:", nfPosMgrAddr);
        clientAddr = payable(arr[11]);
        lg("clientAddr:", clientAddr);
        gldcAddr = arr[12];

        weth = WETH(payable(wethAddr));
        usdt = ERC20DP6(usdtAddr); //USDT use 6 dp !!!
        usdc = ERC20DP6(usdcAddr); //USDC use 6 dp !!!
        dai = ERC20Token(daiAddr);
        uni = ERC20Token(uniAddr);
        gldc = ERC20Token(gldcAddr);
        //link = IERC677(linkTokenAddr);
        client = UniswapClient(clientAddr);

        factory = UniswapV3Factory(factoryAddr);
        quoter = Quoter(quoterAddr);
        router = SwapRouter(payable(routerAddr));

        nfPosMgr = NonfungiblePositionManager(payable(nfPosMgrAddr));

        client = UniswapClient(clientAddr);

        //------------== USDC/WETH
        //0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640 Main
        tokenA = usdcAddr;
        tokenB = wethAddr;
        poolFee = 500; //3000 for 0.3%, 500 for 0.05%, 100 for 0.01%, At Uniswap createPool UI

        poolUsdcWeth500Addr = factory.getPool(tokenA, tokenB, poolFee);
        lg("poolUsdcWeth500Addr:", poolUsdcWeth500Addr);
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolUsdcWeth500Addr, "USDC/WETH 500");
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolUsdcWeth500Addr, "USDC/WETH 500");

        amtInWei = 1e18;
        isToken0input = true;
        sqrtPriceLimitX96 = 0;
        poolAddr = poolUsdcWeth500Addr;
        //poolAddr = poolDaiUsdc100Addr;
        price = getPrice(poolAddr, isToken0input, amtInWei, sqrtPriceLimitX96);
        lg("price:", price);

        //0x07A4f63f643fE39261140DF5E613b9469eccEC86 uni/weth
        //0x6c2e77A3D29e5f4DfBE72c29c8957570fE3BaC0E weth/usdt
    }

    //Error: Do not know how to initialize a pool first...
    function test_1_deployPool() external {
        lg("------------== test_1_deployPool");
        token0Addr = gldcAddr; //Goerli
        token1Addr = wethAddr; //Goerli
        poolFee = 500;
        sqrtPriceX96 = 79228162514264337593543950336; //7.922816251e28; // calculated by running "pnpm run encodePriceSqrt.js"
        address poolGldcWeth500Addr = deployPool(token0Addr, token1Addr, poolFee, sqrtPriceX96, "GLDC/WETH");
        lg("poolGldcWeth500Addr:", poolGldcWeth500Addr);
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolGldcWeth500Addr, "GLDC/WETH 500");
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolGldcWeth500Addr, "GLDC/WETH 500");
    }

    function test_2_mintLiquidity() private {
        lg("------------== test_2_mintLiquidity");
        if (network == 1) {
            token0Addr = gldcAddr; //Goerli
            token1Addr = wethAddr; //Goerli
            token0 = gldc;
            tok0name = "GLDC";
            tok1name = "WETH";
            amt0ToMint = 1000e18; // GLDC
            amt1ToMint = 1000e18; // WETH
            poolFee = 500;
        } else if (network == 2) {} else {
            revert("invalid network");
        }
        console.log("checkpoint 1");
        deal(address(token0Addr), fox1, amt0ToMint);
        assertEq(token0.balanceOf(fox1), amt0ToMint, "e001");

        IUniswapV3Pool poolc = getPool(token0Addr, token1Addr, poolFee);
        lg("poolAddrCalc", address(poolc));
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(address(poolc), "GLDC/WETH 500");
        lg("sqrtPriceX96M:", sqrtPriceX96M);

        lg("balcWeth(fox1):", weth.balanceOf(fox1));
        deal(fox1, 10000 ether); //does not work!
        //weth.deposit{value: amt1ToMint}();//doesn not work
        deal(address(wethAddr), fox1, amt1ToMint);
        lg("balcWeth(fox1):", weth.balanceOf(fox1));

        showERC20WethBalc(token0, weth, fox1, tok0name, tok1name, "fox1");

        showERC20WethBalc(token0, weth, clientAddr, tok0name, tok1name, "client");
        console.log("checkpoint 2");

        vm.startPrank(fox1);
        IERC20(token0Addr).approve(clientAddr, amt0ToMint); //DO THIS BEFORE SWAPPING TOKEN ADDRESSES BELOW!!!
        weth.approve(clientAddr, amt1ToMint);

        if (token0Addr == address(0) || token1Addr == address(0)) console.log("token0Addr or token1Addr is zero");
        if (token0Addr >= token1Addr) {
            (token0Addr, token1Addr) = (token1Addr, token0Addr);
        } //"token0Addr must be < token1Addr!!!
        console.log("token0Addr:", token0Addr);
        console.log("token1Addr:", token1Addr);
        console.log("checkpoint 3");

        console.log("checkpoint 4");

        client.mintNewPosition(token0Addr, token1Addr, poolFee, amt0ToMint, amt1ToMint);
        vm.stopPrank();

        console.log("checkpoint 5: after mintNewPosition");
        uint256 lastNftDepositId = client.lastNftDepositId();
        lg("lastNftDepositId:", lastNftDepositId);

        (ownerM, liquidityM, token0AddrM, token1AddrM) = client.nftDeposits(lastNftDepositId);
        lg("DepositNFT owner:", ownerM);
        console.log("liquidity:", liquidityM);
        lg("token0Addr:", token0AddrM);
        lg("token1Addr:", token1Addr);
        showERC20WethBalc(token0, weth, clientAddr, tok0name, tok1name, "client");

        //MintParams, mint,increaseLiquidity, decreaseLiquidity, IncreaseLiquidityParams, DecreaseLiquidityParams, CollectParams, collect

        // nfPosMgr.mint(mintParams);

        //check added liquidity in the pool
        lg(
            "Go to Uniswap UI and paste above token addresses to confirm they appear! https://app.uniswap.org/#/swap?chain=goerli"
        );
    }
    // pool MUST only be initialized once by setting sqrtPrice to a non zero value ... see UniswapV3Pool.sol

    function test_3_DuelSwap() private {
        lg("------------== test_3_DuelSwap");
        if (network != 1) revert("invalid network");

        token0Addr = usdcAddr;
        token1Addr = wethAddr;
        poolFee = 500;
        uint256 amount0 = 1e18; // USDC
        uint256 amount1 = 1e18; // WETH
        uint24 fee10 = 3000;
        uint24 fee01 = 10000;
        token0 = ERC20Token(token0Addr);
        token1 = ERC20Token(address(token1Addr));
        deal(address(token0Addr), clientAddr, 1000e6);
        deal(address(token1Addr), clientAddr, 1000e18);
        showERC20Balc(token0, token1, clientAddr, "USDC", "WETH", "Client");

        console.log("checkpoint 1");
        UniswapClient.FlashParams memory params = UniswapClient.FlashParams({
            token0: token0Addr,
            token1: token1Addr,
            poolFee: poolFee,
            amount0: amount0,
            amount1: amount1,
            fee10: fee10,
            fee01: fee01
        });
        vm.prank(bob);
        client.flashPool(params);
        console.log("checkpoint 2");

        showERC20Balc(token0, token1, clientAddr, "USDC", "WETH", "Client");
        showERC20Balc(token0, token1, bob, "USDC", "WETH", "Client");
    }
}
