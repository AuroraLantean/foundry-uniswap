// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "forge-std/Script.sol";
/**
 * First, it collects all transactions from the script, and only then does it broadcast them all. It can essentially be split into 4 phases:
 * #1 Local Simulation - The contract script is run in a local evm. If a rpc/fork url has been provided, it will execute the script in that context. Any external call (not static, not internal) from a vm.broadcast and/or vm.startBroadcast will be appended to a list.
 *
 * #2 Onchain Simulation - Optional. If a rpc/fork url has been provided, then it will sequentially execute all the collected transactions from the previous phase here.
 *
 * #3 Broadcasting - Optional. If the --broadcast flag is provided and the previous phases have succeeded, it will broadcast the transactions collected at step 1. and simulated at step 2.
 *
 * #4 Verification - Optional. If the --verify flag is provided, there's an API key, and the previous phases have succeeded it will attempt to verify the contract. (eg. etherscan).
 */

import "src/ERC20Token.sol";
import "src/UniswapClient.sol";
import "src/DeployedCtrtAddrs.sol";
import "forge-std/console.sol";

contract CounterScript is Script {
    address weth9Addr;
    address usdtAddr;
    address usdcAddr;
    address wBTCAddr;
    address daiAddr;
    address uniAddr;
    address linkAddr;
    address factoryAddr;
    address quoterAddr;
    address routerAddr;
    address nfPosMgrAddr;
    address payable clientAddr;
    DeployedCtrtAddrs deployedCtrtAddrs;

    uint256 whichCtrt = 0;
    string url;
    uint8 network = 0; //0 to deploy all UniswapV3, 1 Goerli, 2 Sepolia, 5 Main

    function setUp() public {
        if (network > 0) {
            deployedCtrtAddrs = new DeployedCtrtAddrs();
            address[] memory arr = deployedCtrtAddrs.getAddrs(network);

            weth9Addr = arr[0];
            usdcAddr = arr[2];
            uniAddr = arr[5];
            factoryAddr = arr[7];
            quoterAddr = arr[8];
            routerAddr = arr[9];
            nfPosMgrAddr = arr[10];
            clientAddr = payable(arr[11]);
        } else {
            console.log("invalid network all UniswapV3");
        }
    }

    //default function to run in scripts
    function run() public {
        url = vm.rpcUrl("optimism");
        console.log("url:", url);
        url = vm.rpcUrl("arbitrum");
        console.log("url:", url);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        //vm.broadcast();
        console.log("whichCtrt:", whichCtrt);
        if (whichCtrt == 0) {
            new UniswapClient(factoryAddr, weth9Addr, routerAddr, quoterAddr);
        } else if (whichCtrt == 1) {
            new ERC20Token("GoldCoin", "GOLC");
        } else if (whichCtrt == 2) {}
        vm.stopBroadcast();
    }
}
