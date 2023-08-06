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

contract CounterScript is Script {
    uint256 choice = 0;
    string url;

    address public factoryAddr = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address Weth9Addr = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //Goerli

    function setUp() public {}

    //default function to run in scripts
    function run() public {
        url = vm.rpcUrl("optimism");
        console.log("url:", url);
        url = vm.rpcUrl("arbitrum");
        console.log("url:", url);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        //vm.broadcast();
        console.log("choice:", choice);
        if (choice == 0) {
            new UniswapClient(factoryAddr, Weth9Addr);
        } else if (choice == 1) {
            new ERC20Token("GoldCoin", "GOLC");
        } else if (choice == 2) {}
        vm.stopBroadcast();
    }
}
