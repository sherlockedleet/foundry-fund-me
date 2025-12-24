// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {FundMe} from "../src/FundMe.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

contract DeployFundMe is Script {
    function run() public returns (FundMe) {
        // console.log("0-DeployFundMe's address: ", address(this));
        // console.log("msg.sender in start-deploy: ", msg.sender);
        HelperConfig helperConfig = new HelperConfig();

        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        // console.log("Deploying FundMe contract...");
        // console.log("DeployFundMe's address: ", address(this));
        // console.log("msg.sender in vm: ", msg.sender);
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
