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
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/NFTDescriptor.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/lens/Quoter.sol";
import "@uniswap/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";
import "@uniswap/v3-periphery/contracts/NonfungiblePositionManager.sol";
import "src/UniswapClient.sol";
import "src/DeployedCtrtAddrs.sol";

contract UniswapClientTest is Test {
    address zero = address(0);
    address alice = address(1);
    address bob = address(2);
    address wethAddr;
    address usdtAddr;
    address usdcAddr;
    //address wBTCAddr;
    address daiAddr;
    address uniAddr;
    //address linkAddr;
    address factoryAddr;
    address quoterAddr;
    address routerAddr;
    address nfPosMgrAddr;
    address payable clientAddr;

    address nftDescriptorAddr;
    address nftPosDescriptorAddr;
    string tok0name;
    string tok1name;
    WETH weth;
    ERC20DP6 usdt;
    ERC20DP6 usdc;
    //ERC20DP8 wBTC;
    ERC20Token dai;
    ERC20Token uni;
    ERC20Token token0;
    ERC20Token token1;
    //IERC677 erc677;
    UniswapV3Factory factory;
    Quoter quoter;
    SwapRouter router;
    NonfungiblePositionManager nfPosMgr;
    //NonfungibleTokenPositionDescriptor nftPosDescriptor;
    UniswapClient client;

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

    uint8 network = 1;

    function setUp() external {
        lg("------------== Setup()");
        deal(alice, 1000 ether);
        deal(bob, 1000 ether);
        vm.warp(1689392786); //in JS: new Date().getTime()/1000
            //0 to deploy all UniswapV3 locally, 1 Goerli, 2 Sepolia, 5 Main
        console.log("network:", network);

        getDeployedContractAddrs(network);

        lg("--------== After deployment/setup of contracts");
        vm.startPrank(bob);
        //usdt.approve(nfPosMgrAddr, 1000e6);
        usdc.approve(nfPosMgrAddr, 1000e6);
        vm.stopPrank();

        lg("clientAddr:", clientAddr);
        poolWeth9Uni500 = UniswapV3Pool(poolDaiUsdc100Addr);

        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY_ANVIL"));
        lg("fox1:", fox1);

        //onClientAmt = 10 ether;
        //approvalAmount = onClientAmt;
        //lg("approvalAmount: ", approvalAmount / 1e18, approvalAmount);

        //vm.startPrank(fox1);
        //uni.transfer(clientAddr, onClientAmt);
        //usdc.approve(routerAddr, onClientAmt);
        //uni.approve(routerAddr, onClientAmt);
        //vm.stopPrank();
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

        weth = WETH(payable(wethAddr));
        usdt = ERC20DP6(usdtAddr); //USDT use 6 dp !!!
        usdc = ERC20DP6(usdcAddr); //USDC use 6 dp !!!
        dai = ERC20Token(daiAddr);
        uni = ERC20Token(uniAddr);
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

    function test_1() external {
        lg("------------== goerli_1");
        if (network != 1) revert("invalid network");
        token0Addr = usdcAddr; //Goerli
        token1Addr = wethAddr; //Goerli
        token0 = usdc;
        token1 = ERC20Token(address(weth));
        tok0name = "USDC";
        tok1name = "WETH";
        amt0ToMint = 1000e18; // USDC
        amt1ToMint = 1000e18; // WETH
        poolFee = 500;
        console.log("Show pool of", tok0name, tok1name);
        IUniswapV3Pool poolc = getPool(token0Addr, token1Addr, poolFee);
        lg("poolAddrCalc", address(poolc));

        vm.startPrank(alice);
        token0.transfer(clientAddr, amt0ToMint);
        token1.transfer(clientAddr, amt0ToMint);
        vm.stopPrank();
    }
    /*
    function test_1_mintLiquidity() external {
        lg("------------== test_1_mintLiquidity");
        if (network == 1) {
            token0Addr = usdcAddr; //Goerli
            token1Addr = wethAddr; //Goerli
            token0 = usdc;
            token1 = ERC20Token(address(weth));
            tok0name = "USDC";
            tok1name = "WETH";
            amt0ToMint = 1000e18; // USDC
            amt1ToMint = 1000e18; // WETH
            poolFee = 500;
        } else if (network == 2) {} else {
            revert("invalid network");
        }

        vm.startPrank(alice);
        token0.transfer(clientAddr, amt0ToMint);
        token1.transfer(clientAddr, amt0ToMint);
        vm.stopPrank();
        showERC20Balc(token0, token1, clientAddr, tok0name, tok1name, "client");

        if (token0Addr == address(0) || token1Addr == address(0)) console.log("token0Addr or token1Addr is zero");
        if (token0Addr >= token1Addr) {
            (token0Addr, token1Addr) = (token1Addr, token0Addr);
        } //"token0Addr must be < token1Addr!!!
        console.log("token0Addr:", token0Addr);
        console.log("token1Addr:", token1Addr);

        vm.startPrank(alice);
        IERC20(token0Addr).approve(clientAddr, amt0ToMint);
        IERC20(token1Addr).approve(clientAddr, amt1ToMint);
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
        showERC20Balc(token0, token1, clientAddr, tok0name, tok1name, "client");

        //MintParams, mint,increaseLiquidity, decreaseLiquidity, IncreaseLiquidityParams, DecreaseLiquidityParams, CollectParams, collect

        // nfPosMgr.mint(mintParams);

        //check added liquidity in the pool
        lg(
            "Go to Uniswap UI and paste above token addresses to confirm they appear! https://app.uniswap.org/#/swap?chain=goerli"
        );
    }
    // pool MUST only be initialized once by setting sqrtPrice to a non zero value ... see UniswapV3Pool.sol
    */

    function deployPool(address token0r, address token1r, uint24 _poolFee, uint160 _sqrtPriceX96, string memory str)
        private
        returns (address poolAddr_)
    {
        console.log("--------== deployPool() of ", str, poolFee);
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

        //factory.createPool(wethAddr, uniAddr, _poolFee);
        //IUniswapV3Pool(poolAddr_).initialize(_sqrtPriceX96);
        nfPosMgr.createAndInitializePoolIfNecessary(token0r, token1r, _poolFee, _sqrtPriceX96); //gasLimit = 5000000
        poolAddr_ = factory.getPool(token0r, token1r, _poolFee);
        lg("poolAddr", poolAddr_);
        IUniswapV3Pool poolc = getPool(token0r, token1r, _poolFee);
        lg("poolAddrCalc", address(poolc));
    }

    function showPool(address _poolAddr, string memory str)
        private
        returns (uint24 poolFee_, uint128 liquidity_, int24 tickSpacing_, uint128 maxLiquidityPerTick_)
    {
        lg("--------== showPool(): pool =", _poolAddr);
        lg(str);
        UniswapV3Pool pl = UniswapV3Pool(_poolAddr);
        address factoryAddrM = pl.factory();
        token0AddrM = pl.token0();
        token1AddrM = pl.token1();
        poolFee_ = pl.fee();
        liquidity_ = pl.liquidity();
        tickSpacing_ = pl.tickSpacing();
        maxLiquidityPerTick_ = pl.maxLiquidityPerTick();

        assertEq(factoryAddrM, factoryAddr);
        lg("factoryAddrM:", factoryAddrM);
        lg("token0AddrM:", token0AddrM);
        lg("token1AddrM:", token1AddrM);
        console.log("poolFee_:", poolFee_);
        console.log("liquidity_:", liquidity_);
        console.log("tickSpacing_:", uint24(tickSpacing_), ", isPositive:", tickSpacing_ > 0);
        console.log("maxLiquidityPerTick_:", maxLiquidityPerTick_);
    }

    function showPoolSlot0(address _poolAddr, string memory str)
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
        lg("--------== showPoolSlot0(): pool =", _poolAddr);
        lg(str);
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
    // interface IERC20B is IERC20 {
    //     function decimals() external view returns (uint256);
    //     function name() external view returns (uint256);
    //     function decimals() external view returns (uint256);
    // }

    function getPool(address _tokenA, address _tokenB, uint24 _fee) private view returns (IUniswapV3Pool) {
        if (_tokenA == zero || _tokenB == zero) lg("_tokenA or _tokenB is zero");
        return IUniswapV3Pool(PoolAddress.computeAddress(factoryAddr, PoolAddress.getPoolKey(_tokenA, _tokenB, _fee)));
    }

    //sqrtPriceLimitX96 = 0
    function getPrice(address _poolAddr, bool _isToken0input, uint256 _amtInWei, uint160 _sqrtPriceLimitX96)
        private
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

    function showERC20Balc(
        ERC20 tokA,
        ERC20 tokB,
        address addr,
        string memory nameTokA,
        string memory nameTokB,
        string memory nameAddr
    ) private view {
        console.log("----== showERC20Balc on ", nameAddr);
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

    function lg(string memory str) private view {
        console.log(str);
    }

    function lg(string memory str, address addr) private view {
        console.log(str, addr);
    }

    function lg(string memory str, bool b) private view {
        console.log(str, b);
    }

    function lg(string memory str, uint8 u8) private view {
        console.log(str, u8);
    }

    function lg(string memory str, uint256 u256) private view {
        console.log(str, u256);
    }

    receive() external payable {
        console.log("test ctrt to receive from", msg.sender, msg.value);
    }
}
