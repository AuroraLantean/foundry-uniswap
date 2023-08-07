// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "forge-std/console.sol";

/**
 * address weth9,
 *             address usdt,
 *             address usdc,
 *             address wBTC,
 *             address dai,
 *             address uni,
 *             address link,
 *             address factory,
 *             address quoter,
 *             address router,
 *             address nfPosMgr,
 *             address payable client
 */
contract DeployedCtrtAddrs {
    function getAddrs(uint8 network) public view returns (address[] memory arr) {
        arr = new address[](12);
        if (network == 1) {
            console.log("network", network, " Goerli");

            arr[0] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            arr[1] = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
            arr[2] = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; //https://developers.circle.com/developer/docs/usdc-on-testnet
            arr[3] = 0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05;
            arr[4] = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;

            arr[5] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
            arr[6] = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //https://docs.chain.link/resources/link-token-contracts

            //https://docs.uniswap.org/contracts/v3/reference/deployments
            arr[7] = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
            arr[8] = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
            arr[9] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            arr[10] = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

            arr[11] = payable(0x77b1b3cD6435B0f5a14eE49F2Cb3Af18a8189DF5);
        } else if (network == 2) {
            console.log("network", network, " Sepolia");
        } else if (network == 5) {
            console.log("network", network, " Main");
            arr[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            arr[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
            arr[2] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            arr[3] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
            arr[4] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

            arr[5] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
            arr[6] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
            //https://docs.uniswap.org/contracts/v3/reference/deployments
            arr[7] = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
            arr[8] = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
            arr[9] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            arr[10] = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

            arr[11] = payable(address(0));
        } else {
            console.log("invalid network!");
        }
    }
}
