// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "src/ERC20Token.sol";
//import "src/ERC677Token.sol";
import "src/WETH.sol";
import "src/UniswapClient.sol";

contract UniswapClientTest is Test {
    address zero = address(0);
    address alice = address(1);
    address bob = address(2);
    address hacker = address(6);
    bool ok;
    WETH weth;
    UniswapClient client;
    ERC20DP6 usdc;
    ERC20DP6 usdt;
    ERC20DP8 wbtc;
    //ERC20Token dai;
    ERC20Token token;
    //IERC677 erc677;
    address tokenAddr;
    address tokenAddrM;
    address ownerM;
    address poolAddr;
    address token0Addr;
    address token1Addr;
    uint24 fee;
    uint256 balcUSDC;
    uint256 balcUSDCm;
    uint256 balcFox1M;
    uint256 onClientAmt;
    uint256 amountOut;
    uint256 amountOutM;
    uint256 amountIn;
    uint256 amountInM;
    uint256 amtInMax;
    uint256 amtInMaxM;
    uint256 balcWeth;
    uint256 balcWethbf;
    uint256 balcERC677;
    uint256 balcERC677bf;
    uint256 balcTokClientM;
    uint256 balcTokAClientM;
    uint256 approvalAmount;
    uint256 approvedAmount;
    uint256 liquidityUsdcAmt;
    uint256 liquidityDaiAmt;

    address payable WethAddr = payable(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //Goerli
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 //Mainnet
    address wbtcAddr = 0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05; //Goerli

    address usdcAddr = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; //https://developers.circle.com/developer/docs/usdc-on-testnet
    //address usdtAddr;
    address usdtAddr = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49; // Goerli
    address daiAddr = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60; // Goerli

    address uniTokenAddr = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // Goerli
    address linkTokenAddr = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //https://docs.chain.link/resources/link-token-contracts

    address payable clientAddr = payable(0xBC8D41B7eEE9825b6d8246654f1ac6f55AE823C5);
    address public constant routerAddr = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address fox1;

    function setUp() external {
        console.log("---------== Setup()");
        tokenAddr = linkTokenAddr;
        weth = WETH(WethAddr);
        usdc = ERC20DP6(usdcAddr); //USDC use 6 dp !!!
        usdt = ERC20DP6(usdtAddr); //USDT use 6 dp !!!
        //erc677 = IERC677(tokenAddr);
        token = ERC20Token(tokenAddr);
        client = UniswapClient(clientAddr);

        // vm.startPrank(alice);
        //client.approveToken(approvalAmount, routerAddr);
        // vm.stopPrank();

        fox1 = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        console.log("fox1:", fox1);

        onClientAmt = 10 ether;
        approvalAmount = onClientAmt;
        console.log("approvalAmount: ", approvalAmount / 1e18, approvalAmount);

        vm.startPrank(fox1);
        token.transfer(clientAddr, onClientAmt);
        usdc.approve(routerAddr, onClientAmt);
        token.approve(routerAddr, onClientAmt);
        vm.stopPrank();
    }

    function test_1_init() external {
        console.log("----== test_1_init");
        // _showBalc();
        // tokenAddrM = address(client.token());
        // console.log("tokenAddrM:", tokenAddrM);
        // assertEq(tokenAddrM, tokenAddr);

        token0Addr = address(0);
        token1Addr = address(0);
        fee = 500; // 500, 3000, 10000
        poolAddr = client.getPool(token0Addr, token1Addr, fee);
        console.log("poolAddr:", poolAddr);
    }

    function _showBalc() private {
        balcERC677 = token.balanceOf(clientAddr);
        console.log("balcERC677:", balcERC677 / 1e18, balcERC677);
        balcWeth = weth.balanceOf(clientAddr);
        console.log("balcWeth:", balcWeth / 1e18, balcWeth);
        console.log("");
    }
    /*
    function test_2() external {
        console.log("----== test_2");
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
