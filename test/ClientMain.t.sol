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
import "src/ERC20Token.sol";
import "src/DeployedCtrtAddrs.sol";
import "src/HelperFuncs.sol";

contract UniswapClientTest is Test, HelperFuncs {
    address payable clientAddr;
    UniswapClient client;
    address DAI_WHALE;

    uint8 network = 1; //1 Main, 5 Goerli, 111 Sepolia

    function setUp() external {
        lg("------------== Setup()");
        lg("this address:", address(this));
        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        DAI_WHALE = vm.envAddress("DAI_WHALE");
        lg("DAI_WHALE:", DAI_WHALE);
        //vm.warp(1689392786); //in JS: new Date().getTime()/1000
        //0 to deploy all UniswapV3 locally, 1 Goerli, 2 Sepolia, 5 Main
        console.log("network:", network);

        getDeployedContractAddrs(network);

        lg("--------== deploy UniswapClient");
        vm.prank(fox1);
        client = new UniswapClient(factoryAddr, wethAddr, routerAddr, nfPosMgrAddr);
        clientAddr = address(client);
        lg("clientAddr:", clientAddr);
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

        factory = UniswapV3Factory(factoryAddr);
        quoter = Quoter(quoterAddr);
        router = SwapRouter(payable(routerAddr));

        nfPosMgr = NonfungiblePositionManager(payable(nfPosMgrAddr));

        //0x07A4f63f643fE39261140DF5E613b9469eccEC86 uni/weth
        //0x6c2e77A3D29e5f4DfBE72c29c8957570fE3BaC0E weth/usdt

        //3000 for 0.3%, 500 for 0.05%, 100 for 0.01%,
        //------------== DAI/WETH
        //https://info.uniswap.org/#/pools/0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8
        tokenA = daiAddr;
        tokenB = wethAddr;
        poolFee = 3000;
        str = "DAI/WETH 3000";

        poolAddr = factory.getPool(tokenA, tokenB, poolFee);
        lg("poolAddr:", poolAddr);
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolAddr, str);
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolAddr, str);

        amtInWei = 1e18;
        isToken0input = true;
        sqrtPriceLimitX96 = 0;
        price = getPrice(poolAddr, isToken0input, amtInWei, sqrtPriceLimitX96);
        lg("price:", price);
    }

    function test_2_mintLiquidity() public {
        lg("------------== test_2_mintLiquidity");
        uint128 liquidity;
        token0Addr = daiAddr;
        token1Addr = wethAddr;
        amt0ToMint = 20 * 1e18; //dai
        amt1ToMint = 2e18; //weth
        poolFee = 3000;
        console.log("checkpoint 1");

        deal(daiAddr, address(this), amt0ToMint);
        deal(address(wethAddr), address(this), amt1ToMint);
        lg("balcDai(this):", dai.balanceOf(address(this)));
        lg("balcWeth(this):", weth.balanceOf(address(this)));

        IERC20(token0Addr).approve(clientAddr, amt0ToMint);
        IERC20(token1Addr).approve(clientAddr, amt1ToMint);
        //DO THIS BEFORE SWAPPING TOKEN ADDRESSES BELOW!!!

        if (token0Addr == address(0) || token1Addr == address(0)) console.log("token0Addr or token1Addr is zero");
        if (token0Addr >= token1Addr) {
            (token0Addr, token1Addr) = (token1Addr, token0Addr);
        } //"token0Addr must be < token1Addr!!!
        console.log("token0Addr:", token0Addr);
        console.log("token1Addr:", token1Addr);
        console.log("liquidity", liquidity);
        console.log("checkpoint 3");
        //https://solidity-by-example.org/defi/uniswap-v3-liquidity/
        (uint256 tokenId, uint128 liquidityDelta, uint256 amount0, uint256 amount1) =
            client.mintNewPosition(token0Addr, token1Addr, poolFee, amt0ToMint, amt1ToMint);

        liquidity += liquidityDelta;
        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidityDelta", liquidityDelta);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        console.log("checkpoint 5: after mintNewPosition");
        uint256 lastNftDepositId = client.lastNftDepositId();
        lg("lastNftDepositId:", lastNftDepositId);
        address liqSenderM;
        (liqSenderM, liquidityM, token0AddrM, token1AddrM) = client.nftDeposits(lastNftDepositId);
        lg("DepositNFT liqSenderM:", liqSenderM);
        console.log("liquidity:", liquidityM);
        lg("token0Addr:", token0AddrM);
        lg("token1Addr:", token1AddrM);
        showERC20Balc(token0Addr, token1Addr, clientAddr, tok0name, tok1name, "Client");

        lg("Go to Uniswap UI and paste above token addresses to confirm they appear! https://app.uniswap.org/#/swap"); //?chain=goerli

        // Collect fees
        ownerM = nfPosMgr.ownerOf(tokenId);
        lg("NFT owner:", ownerM);

        (uint256 fee0, uint256 fee1) = client.collectAllFees(tokenId);
        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        /*lg("Increase liquidity");
        uint256 daiAmountToAdd = 5 * 1e18;
        uint256 wethAmountToAdd = 0.5 * 1e18;

        (liquidityDelta, amount0, amount1) =
            client.increaseLiquidityCurrentRange(tokenId, daiAmountToAdd, wethAmountToAdd);
        liquidity += liquidityDelta;

        console.log("--- Increase liquidity ---");
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
        */
    }
    // pool MUST only be initialized once by setting sqrtPrice to a non zero value ... see UniswapV3Pool.sol

    //https://solidity-by-example.org/defi/uniswap-v3-swap
    function test_3_testMultiHop() private {
        lg("------------== test_3_testMultiHop");
        weth.deposit{value: 1e18}();
        weth.approve(address(clientAddr), 1e18);

        bytes memory path = abi.encodePacked(wethAddr, uint24(3000), usdcAddr, uint24(100), daiAddr);

        uint256 amountOut = client.swapExactInputMultiHop(path, wethAddr, 1e18);
        console.log("amountOut", amountOut);
    }

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
        deal(address(token0Addr), clientAddr, 1000e6);
        deal(address(token1Addr), clientAddr, 1000e18);
        showERC20Balc(token0Addr, address(token1Addr), clientAddr, "USDC", "WETH", "Client");

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

        showERC20Balc(token0Addr, address(token1Addr), clientAddr, "USDC", "WETH", "Client");
    }

    //Error: Do not know how to initialize a pool first...
    function test_1_deployPool() private {
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
}
/*//------------== USDC/WETH
        //0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640 Main
        tokenA = usdcAddr;
        tokenB = wethAddr;
        poolFee = 500;
        str = "USDC/WETH 500";

        poolAddr = factory.getPool(tokenA, tokenB, poolFee);
        lg("poolAddr:", poolAddr);
        (poolFeeM, liquidityM, tickspacingM,) = showPool(poolAddr, str);
        (sqrtPriceX96M, tickM,,,,,) = showPoolSlot0(poolAddr, str);

        amtInWei = 1e18;
        isToken0input = true;
        sqrtPriceLimitX96 = 0;
        price = getPrice(poolAddr, isToken0input, amtInWei, sqrtPriceLimitX96);
        lg("price:", price);
        */
